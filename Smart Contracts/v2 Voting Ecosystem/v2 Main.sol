pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

// Deploy votingEcosystem, then only LetterCredit, passing the former contract's address
// NOTE: 
// need to set an higher gas limit 
// need to click on the error on the left, and remove 'internal' from the constructor of Ownable.sol

// Some of the changes: 
// voting ecosystem
// now buyerUpload takes as argument also the num docs the seller will have to provide
// voting endtime is set automatically to avoid redundancies
// status seller_uploaded is set only when all docs are uploaded
// voting, compliance checking, waiving etc. all happen on a specific document, for each document;
// thus we need to keep track of the votings for each document (mapping in Voter struct)
// also voting deadlines and counts are relative to speicific documents (hence a new struct was created)
// banks get a fixed % of the balance at each voting (not fully implemented)
// removed v_time, the enum
// removed bunch of unnecessary variables from storage

// voting ecosystem already imports events and ownable

// imports from OpenZeppelin
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

// imports from our repository
//import "https://github.com/CaterinaFabbri/LetterCredit/blob/main/Smart%20Contracts/Importable%20Contracts/events.sol";
import "https://github.com/CaterinaFabbri/LetterCredit/blob/main/Smart%20Contracts/v2%20Voting%20Ecosystem/vot_eco.sol";


/*
* @dev put variables here to ease the reading. Is this safe?
*/
contract Variables {
    
    // --------------  Ballot Variables  -------------- //
    
    // keep track of the contract status
    enum contract_status  {ON, BUYER_UPLOADED, SELLER_UPLOADED,
                           DOC_OK, DOC_DEFECT,DOC_REJECTED} 
			   contract_status status;
    
    
    struct Voter {
    // new: map from num_doc to whether or not voted on that doc
    mapping (uint => bool) voted;
    // new: map from num_doc to vote expressed
    mapping (uint=> uint) vote;
    }
    // map each bank to its Voter struct
    mapping(address => Voter) voters;
    
    // keep track of who voted, mapping with num_doc as key
    mapping (uint => address[])  voter_addresses;
    // keep track of who 'won' a voting, to give them the reward fee
    address[] winning_address;

    // --------------  LetterCredit Variables  -------------- //
    
    
    // define the addresses of the parties involved
    address payable public buyer;
    address payable public seller;
    // not set to public because there0's already an owner getter
    address payable fintech;
    
    // new: address of vot_ecosystem contract
    address public vot_ecosystem;
    
    // records the buyer's document hash (bytes32 in production?)
    string buyer_doc_hash;
    // new: num docs the seller will have to upload
    uint num_docs_to_upload;
    // new: keep track of num uploaded documents
    uint num_docs_uploaded;
    
    //new: map each seller's document to its hashes
    mapping (uint=> string) seller_documents;
    // new: map each doc to its compliance status
    mapping (uint=> bool) compliances;
    // new: keep track of the num of uncompliant documents
    uint uncompl_docs;
    
    // new: struct to track seller documents and votings on them
    struct Documents {
        uint voting_deadline;
        uint votes_for_compliance;
        uint votes_for_no_compliance;
    }
    // new: mapping for the above struct
    mapping (uint => Documents) document;
    // new: mapping to avoid checking compliance on not uploaded docs
    mapping (uint => bool) need_to_check_compl;
    
    // define deadline, and extension (set by the buyer)
    uint deadline;

    // records the balance for each player
    mapping(address => uint) balance;    

    // define fees held by the fintech company.. 
    uint public defect_fee;      // ..in case of compliance,
    uint public compliance_fee;  // ..in case of no compliance
}

/*********************************************************************************************************************************************************/

/*
* @dev manages the voting pattern in a specific LetterCredit contract 
*/
contract Ballot is Ownable, Events, Variables {
    
    using SafeMath for uint;
    
    constructor(address _vot_ecosystem) {
        vot_ecosystem = _vot_ecosystem;
    }
    
    /*
    * @dev set the voting deadline for a particular seller's document
    * @params _num_document num doc for which to set the deadline
    *         v_number_of_days days from now until which banks can vote
    */
    function VotingEndTime(uint _num_document, uint v_number_of_days) internal  {
        assert(_num_document <= num_docs_uploaded); 
        document[_num_document].voting_deadline = block.timestamp.add(v_number_of_days * 1 days);
    }
    
    /* let a bank vote, modifying its Voter struct accordingly.
    Note: since the deadline is uint and thus initialized to zero, 
    it is impossible to vote on a document not yet uploaded */
    function vote(uint proposal, uint _num_document) public {
        
// checks regarding this contract
        uint v_deadline = document[_num_document].voting_deadline;
	    require(block.timestamp <= v_deadline, "Doc not yet uploaded or time expired for voting on this doc");
	    
// checks on the voting ecosystem contract.
        bool isbank = votingEcosystem(vot_ecosystem).isvoter(msg.sender);
        require(isbank == true, "must be allowed to vote");
        bool voted = voters[msg.sender].voted[_num_document];
        require(voted == false, "Already voted.");
        

// modify variables 
        voters[msg.sender].voted[_num_document] = true;
        voters[msg.sender].vote[_num_document]  = proposal;
        
        // store the fact that this address voted. Will be used
        // to make it eligible for the reward fee
        voter_addresses[_num_document].push(msg.sender);
        
// use the vote to increase the appropriate counter
        if (proposal == 0){
            document[_num_document].votes_for_no_compliance  +=1;}
        else {
            if (proposal == 1){
                document[_num_document].votes_for_compliance +=1;}
        }
    }

    /*
    * @dev returns the result of voting (compliance or no compliance) for a seller's doc
    * @params _num_document num doc for which to check voting result
    *         
    */
    function winningProposal(uint _num_document) internal view returns (uint winningProposal_){
        assert(_num_document <= num_docs_uploaded);  
        
        uint compliance_votes = document[_num_document].votes_for_compliance;
        uint no_compliance_votes = document[_num_document].votes_for_no_compliance;
        
        if (no_compliance_votes>=compliance_votes){
            winningProposal_ = 0;
        }
        else {
            winningProposal_ = 1;
        }
        return winningProposal_;
    }
    
    /*
    * @dev pushes into winning_address the banks who voted well on a specific doc
    * @params _num_document num doc for which to check who voted according majority
    */    
    function voteAccordingMajority(uint _num_document) internal  {
        assert(_num_document <= num_docs_uploaded); 
        uint _winningProposal =  winningProposal(_num_document);
        
        for (uint p = 0; p < voter_addresses[_num_document].length; p++) {
            
            address voter_address = voter_addresses[_num_document][p];

            if (voters[voter_address].vote[_num_document] == _winningProposal) {
                winning_address.push(voter_address);
            }
        }
    }
}

/*********************************************************************************************************************************************************/

/*
* @dev main contract, manages uploading of docs, compliance checks and reward splitting
*/
contract LetterCredit is Ballot {
    
    using SafeMath for uint;

	 /* Stores the addresses of the buyer and of the seller
     and initializes the variables */
    constructor (address payable _buyer,  address payable _seller, address _vot_ecosystem) 
    Ballot(vot_ecosystem = _vot_ecosystem)  // see https://docs.soliditylang.org/en/develop/contracts.html#arguments-for-base-constructors
    payable{
        
        fintech = msg.sender;
        buyer = _buyer;
        seller = _seller;
        
        status = contract_status.ON;
        
        compliance_fee = 20; // 20%
        defect_fee = 1;
    }
    
    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }
    
    
    // -----------------------------------------  Buyer Domain  ----------------------------------------- //
    // note: the functions accessible by the buyer come first, than those of the seller, then the fintech and finally the mixed ones

    /*
    * @dev allow the buyer to upload money at any time. 
    */
    function Ether_Upload() payable public onlyBuyer{ 
        emit BuyerInstallment();
    }
    
    /*
    * @dev used by the buyer to set the deadline. Called by prev. function.
    * @params _number_of_days num days the seller has from current day to upload his docs
    */
    function SetEndTime(uint _number_of_days) internal  {
        deadline = block.timestamp.add(_number_of_days * 1 days);
        //deadline = block.timestamp.add(_number_of_days); //this is just in seconds to test whether it works fine
    }
    
	/*
    * @dev used by the buyer to upload the letter of credit hash, to set the
    *      deadline for the seller to upload his documents, and to feed an initial
    *      installment to the contract.
    * @params hash_buyer hash from which to retrieve the document,
    *	      _number_of_days num days the seller has from current day to upload his docs
    */
    function buyerUpload(string memory hash_buyer, uint _number_of_days, uint _num_docs_seller) external payable onlyBuyer {
	    require(status == contract_status.ON, "Invalid status, status is not ON");
	   
        // upload the letter of credit	   
	    buyer_doc_hash = hash_buyer;
	    num_docs_to_upload = _num_docs_seller;
	    
	    status = contract_status.BUYER_UPLOADED;
	    
	    // set the deadline
	    SetEndTime(_number_of_days);
	    
    	emit ContractDeployed(deadline);
	}
	
	/*
	* @dev allows the buyer to extend the deadline.
	* @params _extension num of additional days the seller will have 
	*/
	function ExtendTime(uint _extension) external onlyBuyer {
        deadline = deadline.add(_extension * 1 days);
        // deadline = block.timestamp.add(extension);

        emit Deadline_extension(deadline);
	}
	
	/*
    * @dev new: allows the buyer to waive discrepancies on a specific doc
    * @params __num_document num of the document on which to waive
    */
    function waiveDocDiscrepancy(uint _num_document) public onlyBuyer {
        
        /* below checks aren't strictly necessary, as they are more to avoid that
        * the buyer does mistakes than to avoid malicious behaviour, which he would
        * gain nothing from */
        assert(_num_document < num_docs_uploaded);  
        assert(uncompl_docs > 0);
        uint v_deadline = document[_num_document].voting_deadline;
        require(block.timestamp > v_deadline, "Voting on this doc hasn't finished yet!");
        require(compliances[_num_document] == false, "nothing to waive: this doc is already compliant");
        
    	compliances[_num_document] = true;
    	uncompl_docs -= 1;
            
        //emit BuyerWaivedOneDoc(_num_document);
        }
    
	/*
    * @dev allows the buyer to decide whether to waive the discrepancies or terminate the
    * contract, in case the documents don't comply.
    * @params _waive false to terminate transaction, true to waive discrepancies
    */
    function waiveAllDiscrepancies(bool _waive) public onlyBuyer {
        require(status == contract_status.DOC_DEFECT, "Can only use this function if there are discrepancies");

        if (_waive) {

		    status = contract_status.DOC_OK; //The buyer decides to waive the discrepancies
		    uncompl_docs = 0;

            // split the money owed to the fintech and the seller
            setBalances(compliance_fee, seller); }
	    	
        else {

	    	status = contract_status.DOC_REJECTED; //The buyer decides to terminate the contract

            // split the money owed to the fintech and the buyer
            setBalances(defect_fee, buyer); }
            
        emit BuyerDecision(_waive);
        }

	// ----------------------------------------- Seller Domain -----------------------------------------  //
	
	/*
    * @dev allows the Seller to upload one document hash.
    * @params hash_seller hash from which to retrieve the document
    */
    function sellerUpload(string memory hash_seller) public onlySeller {
	    require(status==contract_status.BUYER_UPLOADED, "Invalid status, status is not BUYER_UPLOADED");
	    require(block.timestamp <= deadline, "Time for uploading documents expired");
		
	    seller_documents[num_docs_uploaded] = hash_seller;
	    
        // for simplicity here we automatically set the time to vote to 3 days from now
	    VotingEndTime(num_docs_uploaded,3);
	    
	    // this enables the fintech to check compliance on this doc
	    need_to_check_compl[num_docs_uploaded] = true;
	    
	    num_docs_uploaded += 1;
	    
	    
	    if (num_docs_uploaded == num_docs_to_upload){
	        status = contract_status.SELLER_UPLOADED;}
	    
	    emit SellerUpload();
	}
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
    

	/*
    * @dev allows the fintech to call a compliance check on a document once voting ended.
    *      The result of voting determines compliance, according to simple majority 
    */
    function checkCompliance(uint num_document) public onlyOwner{
        require(num_document < num_docs_uploaded, "Can't vote on a document not yet uploaded");  
        
        require(need_to_check_compl[num_document] == true, "Already setted compl., or doc not yet uploaded");
        need_to_check_compl[num_document] = false;
        
// No discrepancies scenario
        if (winningProposal(num_document)==1) {
            
            compliances[num_document] = true;
        }
        	
// discrepancies scenario 
    	else {

        	compliances[num_document] = false;
        	uncompl_docs += 1;
            }  
            
// let the voting deadline expire (discussed in description.md)
        document[num_document].voting_deadline = 0;
        
// eventually set overall compliance 
        if (status == contract_status.SELLER_UPLOADED) {
            
                if (uncompl_docs > 0){
                    // set doc to not compliant and let the buyer decide what to do
                    status = contract_status.DOC_DEFECT;
                }
                else {
                    status = contract_status.DOC_OK; 
                    // split the money owned to the fintech and the seller
                    setBalances(compliance_fee, seller); 
            }
            
        // pay a commission to the 'winner' banks
        // we didn't implement this yet, see below muted funct
        //updateBankBalances(num_document);    
        
        emit ComplianceChecked();
        }
    }
    
    /*
    * see description.md
	function updateBankBalances(uint _num_document) internal {
	    // here we let banks take 0.5% of the total money at each voting
	    
	    // be sure to clear array before pushing into it 
	    delete winning_address;
	    assert(winning_address.length == 0);
	    // update the winning_address array
	    voteAccordingMajority(_num_document);
	    
	    // set the banks reward
	    uint contract_money = address(this).balance;
	    uint banks_money = contract_money.mul(5)/100;
	    
	    transfer the money into an escrow contract, from which the banks can pull it.
	    This way this function doesn't interfere with setBalances(), which can be called
	    only when the current function is no longer callable
        }
	}
    */
    
	/*
	*  @dev selfdestruct the contract and give all the money 
    *  to the fintech (nice fail-safe mechanism but trust required) 
    */
    function destroycontract() public payable onlyOwner{
        selfdestruct(fintech);
    }
    
    	// ----------------------------------------- Mixed Domain -----------------------------------------  //
    
    /*
    * @dev internally called function to settle balances among the parties, banks included.
    *      Called in both cases of compliance and no compliance. 
    * @params commission_fee % of total money in the contract taken by the fintech
    *         user_payable address of user who will receive the money minus the fee
    */
	function setBalances(uint commission_fee, address user_payable) internal {
	    
	    uint contract_money = address(this).balance;
	    require(contract_money>0, "There is no money in this contract");
	    
        uint commission;
        commission = contract_money.mul(commission_fee)/100; 
        
        balance[user_payable] = (contract_money - commission);
        // the fintech takes its commission, banks are payed on each document
	    balance[fintech] = commission;
        }
	
	/*
	*  @dev let a user withdraw his due money
    */
    function withdrawFunds() public payable {
        
        // can use openzeppelin or https://github.com/kieranelby/KingOfTheEtherThrone/blob/v1.0/contracts/KingOfTheEtherThrone.sol
        // to make it more complex and safe, e.g. managing the amount of gas used
        
        // can only withdraw funds when the contract is resolved
        require(status == contract_status.DOC_REJECTED || status == contract_status.DOC_OK , "Invalid status");
        
        // check amount due to user, and set it to zero: Check-Effects-Interaction pattern
        address user = msg.sender;
        uint amount = balance[user];
        balance[user] = 0;
        
        // to avoid emitting irrelevant events
        require(amount > 0, "no money due to this address");
        
	    //works like transfer function but avoids reentrancy
    	(bool success,) = user.call{value : amount}("");
    	require(success);
    	
    	emit Withdrawn(user);
    }

	
    /*
	*  @dev let the parties retrieve the uploaded hashes of documents
    */
	function See_Buyer_Hash() public view returns(string memory){
        bool isbank = votingEcosystem(vot_ecosystem).isvoter(msg.sender);
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || isbank==true, "not authorized");	    
        return buyer_doc_hash;
	}
	
	function See_Seller_Hash(uint num_document) public view returns(string memory){
        bool isbank = votingEcosystem(vot_ecosystem).isvoter(msg.sender);
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || isbank==true, "not authorized");	    
        return seller_documents[num_document];
	}
    
    /*
	*  @dev let the parties check the money in the contract
    */
    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller, "not authorized");
        return address(this).balance;
    }
    
    function seeDocCompliances(uint num_document) public view returns(bool doc_compliance){
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller,  "not authorized");
        require(num_document <= num_docs_uploaded, "Can't check compliance on a document not yet uploaded");  
        return compliances[num_document];
    }
}
	// ----------------------------------------- End -----------------------------------------           //
