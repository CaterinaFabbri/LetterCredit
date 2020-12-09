pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

// Deploy only LetterCredit
// NOTE: need to set an higher gas limit 

// LATEST CHANGES: 
// removed the array with voters
// removed the replenish votes function
// using emits to keep track of who can vote (can feed them also a document or the name of the bank)
// added the function to remove the right to vote
// removed fintech from the constructor arguments, now 33,33% faster to deploy :-)
// now voting can happen only if contract status is SELLER_UPLOADED

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Events {
    
    // -----------------------------------------  Ballot Domain  ----------------------------------------- //
    
    // signal that fintech gives the right to vote    
    event NewVoter(address voter_address);
    // signal that fintech removes the right to vote
    event RemovedVoter(address voter_address);

    // -----------------------------------------  LetterCredit Domain  ----------------------------------------- //

    // signal the start of the contract
    event ContractDeployed(uint deadline);
    
    // signal that the buyer has uploaded some money
    event BuyerInstallment(uint256 amount);
    
	// signal that the seller has uploaded the document
	event SellerUpload();
	
    // signal an extension of the deadline
    event Deadline_extension(uint deadline);
    
	// signal that the Fintech has evaluated compliance of seller's document
	event ComplianceChecked();
	
	// signal that the buyer has decided either to waive or to end the transaction 
	event BuyerDecision(bool waive);
	
    // signal that someone has withdrawn money
    event Withdrawn(address withdrawer);
    
}

contract Variables {
    
    // -----------------------------------------  Ballot Domain  ----------------------------------------- //
    
    // keep track of the contract status
    enum contract_status  {ON, BUYER_UPLOADED, SELLER_UPLOADED, 
                            DOC_OK, DOC_DEFECT,DOC_REJECTED, 
                            MONEY_SENT} contract_status status;
    
    // keep track of the voting deadline
    enum voting_time {ON_TIME, OUT_OF_TIME} voting_time v_time;
    
    // keep track of whether the bank already voted (voted), 
    // and the index of the voted proposal (vote)
    struct Voter {
        bool voted;  
        uint vote;   
    }
    mapping(address => Voter)  voters;
    

    // keep track of the number of accumulated votes for each proposal name
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; 
    }
    Proposal[] public proposals;
    

    // voting deadline: set by the fintech (days), and starts when the seller 
    // uploads the documents.
    uint public v_deadline;
    
    // records when the seller uploads the documents
    uint _UploadTime;
    
    // true if the fintech has given right to vote
    mapping(address => bool)  allowed_to_vote;

    


    // -----------------------------------------  LetterCredit Domain  ----------------------------------------- //
    
    
    // define the addresses of the parties involved
    address payable public buyer;
    address payable public seller;
    address payable public fintech;
    
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


contract Ballot is Ownable, Events, Variables {
    
    using SafeMath for uint;
    
    constructor() {
        
        proposals.push(Proposal({
            name: "Not Compliant",
            voteCount: 0
            }));   
        proposals.push(Proposal({
            name: "Compliant",
            voteCount: 0
            }));
    }
    

    function giveRightToVote(address voter) public onlyOwner {
        require(allowed_to_vote[voter] == false , "The user is already allowed to vote");
        // below check isn't required nor useful as of now
        //require(!voters[voter].voted,"The voter has already voted");
    
        allowed_to_vote[voter] = true;
        emit NewVoter(voter);
    }
    
    function removeRightToVote(address voter) public onlyOwner {
        require(allowed_to_vote[voter] != false , "The user is already not allowed to vote");
        
        allowed_to_vote[voter] = false;
        emit RemovedVoter(voter);    
    }
    
    function VotingEndTime(uint v_number_of_days) external onlyOwner {
        v_deadline = _UploadTime.add(v_number_of_days * 1 days);
        //v_deadline = _UploadTime.add(v_number_of_days); //this is just in seconds to test whether it works fine
        v_time = voting_time.ON_TIME;
    }
    
    /* let a bank vote, modifying its Voter struct accordingly */
    function vote(uint proposal) public {
        require(status == contract_status.SELLER_UPLOADED, "Can't vote on a document not yet uploaded");
        bool isbank = allowed_to_vote[msg.sender];
        require(isbank == true, "must be allowed to vote");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        
        if (block.timestamp >= v_deadline) {
	        
	        v_time = voting_time.OUT_OF_TIME;
	    }
	    
	    require(v_time == voting_time.ON_TIME, "Invalid status, status is not ON_TIME");
	    
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount ++;
    }

    function winningProposal() onlyOwner public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

}

/*********************************************************************************************************************************************************/

contract LetterCredit is Ballot {
    
    using SafeMath for uint;

	
    constructor (address payable _buyer,  address payable _seller) payable{
        
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

    function Ether_Upload() payable public onlyBuyer{ 
        emit BuyerInstallment(msg.value);
    }

    function SetEndTime(uint _number_of_days) internal onlyBuyer {
        deadline = block.timestamp.add(_number_of_days * 1 days);
        //deadline = block.timestamp.add(_number_of_days); //this is just in seconds to test whether it works fine
        time = contract_time.ON_TIME;
    }
    
	
    function buyerUpload(string memory hash_buyer, uint _number_of_days) external payable onlyBuyer {
	    require(status == contract_status.ON, "Invalid status, status is not ON");
	   
        // upload the letter of credit	   
	    docu_hashs[buyer] = hash_buyer;
	    status = contract_status.BUYER_UPLOADED;
	    
	    // set the deadline
	    SetEndTime(_number_of_days);
	    
	    // eventually upload a first installment
	    Ether_Upload();
	    
    	emit ContractDeployed(deadline);
	}
	

	
	function ExtendTime(uint _extension) external onlyBuyer {
        extension = _extension;
        deadline = block.timestamp.add(extension * 1 days);
        // deadline = block.timestamp.add(extension);

        time = contract_time.ON_TIME;
        emit Deadline_extension(deadline);
	}
    
	
    function waiveDiscrepancies(bool _waive) public onlyBuyer {
        
        // In case the documents don't comply, the buyer can
        // decide whether to wave the discrepancies or terminate the
        // contract
        
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
	
    function sellerUpload(string memory hash_seller) public onlySeller {
    //The seller, after the buyer has uploaded the document and the money, upload his document. 
    
	    require(status==contract_status.BUYER_UPLOADED, "Invalid status, status is not BUYER_UPLOADED");
	    
	    if (block.timestamp >= deadline) {
	        
	        time = contract_time.OUT_OF_TIME;
	    }
	    
	    require(time == contract_time.ON_TIME, "Invalid status, status is not ON_TIME");
		
	    docu_hashs[seller] = hash_seller;
	    status = contract_status.SELLER_UPLOADED;
	    _UploadTime = block.timestamp;

	    emit SellerUpload();
	}
	
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
	
    function checkCompliance() public onlyOwner{
    
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
        
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
        	
        	// split the money owned to the fintech and the buyer
        	setBalances(defect_fee, buyer);
        	
            }
        
        emit ComplianceChecked();    

        }

/*    
    function fintechUpload(string memory hash_fintech) public onlyOwner{
        
        // In case the documents defect, the fintech can upload a document
        // for the buyer to review.
	    require(status==contract_status.DOC_DEFECT, "Invalid status, status is not DOC_DEFECT");
	    docu_hashs[fintech] = hash_fintech;
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


	function setBalances(uint commission_fee, address user_payable) internal {
	    
	    uint contract_money = address(this).balance;
        uint commission;
        
        commission = contract_money.mul(commission_fee)/100; 

        // split the money owed to the user (buyer or seller) and to the fintech
        balance[user_payable] = (contract_money - commission);
	    balance[fintech] = contract_money - balance[user_payable];
	   
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

	

	function See_Doc_Hash( address _user) public view returns(string memory){
        bool isbank = allowed_to_vote[msg.sender];
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || isbank==true, "not authorized");	    
        return docu_hashs[_user];
	}
    
    
    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller, "not authorized");
        return address(this).balance;
    }
    
    

}
	// ----------------------------------------- End -----------------------------------------           //
	
    contract evilGenius {
        /*
    	*  @dev makes a payment to this address fail
        */
        function revertBonanza() public payable {
            revert("ihih evil genius at it again!");
        }
    }
