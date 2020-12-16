pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

// Deploy votingEcosystem, then only LetterCredit, passing the former contract's address
// NOTE: need to set an higher gas limit 


// need to click on the error on the left, and remove 'internal' from the constructor
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/Barandaur/prova/blob/main/events.sol";

import "https://github.com/CaterinaFabbri/LetterCredit/blob/main/Smart%20Contracts/v2%20Voting%20Ecosystem/vot_eco.sol";

/*
* @dev put variables here to ease the reading. Is this safe?
*/
contract Variables {
    
    // --------------  Ballot Variables  -------------- //
    
    // keep track of the contract status
    enum contract_status  {ON, BUYER_UPLOADED, SELLER_UPLOADED, 
                            DOC_OK, DOC_DEFECT,DOC_REJECTED, 
                            MONEY_SENT} contract_status status;
    
    // keep track of the voting deadline
    enum voting_time {ON_TIME, OUT_OF_TIME} voting_time v_time;
    

    // keep track of the number of accumulated votes for each proposal
    uint no_compliance_votes = 0;
    uint compliance_votes = 0;
    

    // voting deadline: set by the fintech (days), and starts when the seller 
    // uploads the documents.
    uint public v_deadline;
    
    // records when the seller uploads the documents
    uint _UploadTime;
    
    
    struct Voter {
    bool voted;
    uint vote;
    }
    mapping(address => Voter) voters;
    
    // keep track of who voted
    address[] public voter_addresses;
    address[] public winning_address;

    // --------------  LetterCredit Variables  -------------- //
    
    
    // define the addresses of the parties involved
    address payable public buyer;
    address payable public seller;
    address payable public fintech;
    
    address public vot_ecosystem;
    
    // checks whether the seller is on time to upload the documents
    enum contract_time {ON_TIME, OUT_OF_TIME} contract_time time;
    
    // define deadline, and extension (set by the buyer)
    uint public deadline;
    uint extension;
    
    // in case the buyer wants to waive discrepancies, it is set to true
    bool waive; 

    // records the balance for each player
    mapping(address => uint) balance;
    
    // records the document hash for each player (bytes32 in production?)
    mapping(address => string) docu_hashs;
    

    // define fees held by the fintech company in case of compliance,
    // and of no compliance
    uint defect_fee; 
    uint compliance_fee; 
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
    
    
    function VotingEndTime(uint v_number_of_days) internal  {
        v_deadline = _UploadTime.add(v_number_of_days * 1 days);
        v_time = voting_time.ON_TIME;
    }
    
    /* let a bank vote, modifying its Voter struct accordingly */
    function vote(uint proposal) public {
        
        // checks regarding this contract
        require(status == contract_status.SELLER_UPLOADED, "Can't vote on a document not yet uploaded");
        if (block.timestamp >= v_deadline) {
	        v_time = voting_time.OUT_OF_TIME;
	    }
	    require(v_time == voting_time.ON_TIME, "Invalid status, status is not ON_TIME");
	    
	    // checks on the voting ecosystem contract.
	    // we need to check that the original caller is a bank,
	    // but we can't use tx.origin since it can be frauded
	    //assert(msg.sender == tx.origin);
        bool isbank = votingEcosystem(vot_ecosystem).isvoter(msg.sender);
        require(isbank == true, "must be allowed to vote");
        bool voted = voters[msg.sender].voted;
        require(voted == false, "Already voted.");
        
        // access the Voter struct for a specific bank
        
        // modify varaibles before calling the other contract
        voters[msg.sender].voted = true;
        voters[msg.sender].vote = proposal;
        
        // store the fact that this address voted. Will be used
        // to make him eligible for the reward fee
        voter_addresses.push(msg.sender);
        
        // use his vote to increase the appropriate counter
        if (proposal == 0){
            no_compliance_votes +=1;}
        else {
            if (proposal == 1){
                compliance_votes +=1;}
        }
    }


    function winningProposal() internal view returns (uint winningProposal_){
        
        if (no_compliance_votes>=compliance_votes){
            winningProposal_ = 0;
        }
        else {
            winningProposal_ = 1;
        }
        return winningProposal_;
    }
        
    function voteAccordingMajority() internal  {

        for (uint p = 0; p < voter_addresses.length; p++) {
            
            address voter_address = voter_addresses[p];

            if (voters[voter_address].vote == winningProposal()) {
                winning_address.push(voter_address);
            }
        }
    }
}

/*********************************************************************************************************************************************************/

/*
* @dev main contract
*/
contract LetterCredit is Ballot {
    
    using SafeMath for uint;

	
    constructor (address payable _buyer,  address payable _seller, address _vot_ecosystem) 
    Ballot(vot_ecosystem = _vot_ecosystem)  // see https://docs.soliditylang.org/en/develop/contracts.html#arguments-for-base-constructors
    payable{
        
        /* Stores the addresses of the buyer and of the seller
        and initializes the variables */
        fintech = msg.sender;
        buyer = _buyer;
        seller = _seller;
        
        
        status = contract_status.ON;
        
        balance[buyer] = 0;
        balance[seller] = 0;
        balance[fintech] = 0;
        
        compliance_fee = 20; // in %
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
        time = contract_time.ON_TIME;
    }
    
	/*
    * @dev used by the buyer to upload the letter of credit hash, to set the
    *      deadline for the seller to upload his documents, and to feed an initial
    *      installment to the contract.
    * @params hash_buyer hash from which to retrieve the document,
    *	      _number_of_days num days the seller has from current day to upload his docs
    */
    function buyerUpload(string memory hash_buyer, uint _number_of_days) external payable onlyBuyer {
	    require(status == contract_status.ON, "Invalid status, status is not ON");
	   
        // upload the letter of credit	   
	    docu_hashs[buyer] = hash_buyer;
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
        extension = _extension;
        deadline = block.timestamp.add(extension * 1 days);
        // deadline = block.timestamp.add(extension);

        time = contract_time.ON_TIME;
        emit Deadline_extension(deadline);
	}
    
	/*
    * @dev allows the buyer to decide whether to waive the discrepancies or terminate the
    * contract, in case the documents don't comply.
    * @params _waive false to terminate transaction, true to waive discrepancies
    */
    function waiveDiscrepancies(bool _waive) public onlyBuyer {
        require(status == contract_status.DOC_DEFECT, "Can only use this function if there are discrepancies");

        waive = _waive;

        if (waive) {

		    status = contract_status.DOC_OK; //The buyer decides to waive the discrepancies

            // split the money owed to the fintech and the seller
            setBalances(compliance_fee, seller); }
	    	
        else {

	    	status = contract_status.DOC_REJECTED; //The buyer decides to terminate the contract

            // split the money owed to the fintech and the buyer
            setBalances(defect_fee, buyer); }
            
        emit BuyerDecision(waive);
        }

	// ----------------------------------------- Seller Domain -----------------------------------------  //
	
	/*
    * @dev allows the Seller to upload his document.
    * @params hash_seller hash from which to retrieve the document
    */
    function sellerUpload(string memory hash_seller) public onlySeller {
	    require(status==contract_status.BUYER_UPLOADED, "Invalid status, status is not BUYER_UPLOADED");
	    
	    if (block.timestamp >= deadline) {
	        
	        time = contract_time.OUT_OF_TIME;
	    }
	    
	    require(time == contract_time.ON_TIME, "Invalid status, status is not ON_TIME");
		
	    docu_hashs[seller] = hash_seller;
	    status = contract_status.SELLER_UPLOADED;
	    _UploadTime = block.timestamp;
	    
	    // for simplicity here we automatically set the time to vote
	    VotingEndTime(10);

	    emit SellerUpload();
	}
	
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
	
	/*
    * @dev allows the fintech to call a compliance check once voting ended.
    *      The result of voting determines compliance, according to simple majority 
    */
    function checkCompliance() public onlyOwner{
        
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        // No discrepancies scenario
        if (winningProposal()==1) {

    	    status = contract_status.DOC_OK; 
            
            // split the money owned to the fintech and the seller
            setBalances(compliance_fee, seller); 
            
        }
        	
    	// discrepancies scenario 
    	else {
            
        	status = contract_status.DOC_DEFECT;
        	
        	
            }
        
        emit ComplianceChecked();    

        }

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
        uint commission;
        uint fintech_money;
        commission = contract_money.mul(commission_fee)/100; 
        
        balance[user_payable] = (contract_money - commission);
        // 20% of the commission fee is of the fintech 
        fintech_money = commission.mul(20)/100;
	    balance[fintech] = fintech_money;
	    
	    // And the 60% of the commission fee belongs to those that voted according
	    // to the majority.
	    voteAccordingMajority();
	    uint banks_money = (commission - fintech_money).div(winning_address.length);
	    
	    for(uint i=0; i<winning_address.length; i++){
	        balance[winning_address[i]] = banks_money;
        }
	   
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
	function See_Doc_Hash( address _user) public view returns(string memory){
        bool isbank = votingEcosystem(vot_ecosystem).isvoter(msg.sender);
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || isbank==true, "not authorized");	    
        return docu_hashs[_user];
	}
    
    /*
	*  @dev let the parties check the money in the contract
    */
    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller, "not authorized");
        return address(this).balance;
    }

}
	// ----------------------------------------- End -----------------------------------------           //
