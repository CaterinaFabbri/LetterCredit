pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

// Deploy only LetterCredit
// NOTE: need to set an higher gas limit 

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Ballot is Ownable {
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }
    
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    mapping(address => Voter)  voters;
    mapping(address => bool)  allowed_to_vote;
    address[] public voters_addresses;
    Proposal[] public proposals;

    constructor() {
        
        proposals.push(Proposal({
            name: "Compliant",
            voteCount: 0
            }));
        proposals.push(Proposal({
            name: "Not Compliant",
            voteCount: 0
            }));        
    }
    
    function giveRightToVote(address voter) public onlyOwner {
        require(!voters[voter].voted,"The voter already voted.");
        // add his address to the list of voters
        voters_addresses.push(voter);
        allowed_to_vote[voter] = true;
    }

    /* let a bank vote, modifying its Voter struct accordingly */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount ++;
    }

    function winningProposal() onlyOwner public view returns (string memory winnerName_){
        uint winningVoteCount = 0;
        uint winningProposal_ = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        winnerName_ = proposals[winningProposal_].name;
        return(winnerName_);
    }
    
    function replenish_all_votes() public onlyOwner {
        for (uint v = 0; v < voters_addresses.length; v++) {
            address addr = voters_addresses[v];
            voters[addr].voted = false;
        }
    }

}

contract LetterCredit is Ballot {
    
    using SafeMath for uint;
    
    // define the addresses of the parties invovled
    address payable public buyer;
    address payable public seller;
    address payable public fintech;
    address address_ballot;

    
    mapping(address => uint) balance;
     // can be made bytes32 in production, more efficient
    mapping(address => string) docu_hashs;
    
    //define deadline
    uint deadline;
    uint extension;
    bool waive; 

    //define all the status that the contract may have
    enum contract_status {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT,DOC_REJECTED, MONEY_SENT} contract_status status;
    enum contract_time {ON_TIME, OUT_OF_TIME} contract_time time;
    
    //define fees held by the fintech company
    uint defect_fee; // fee in case of no compliance
    uint commission_cost; // fee in case of compliance
    
    // signal that the buyer uploaded some money
    event buyer_installment(uint256 amount);
	
	
    constructor (address payable _fintech, address payable _buyer,  address payable _seller) payable{
        
        /* Stores the addresses of the buyer and of the seller
        and initializes the variables */
        buyer = _buyer;
        seller = _seller;
        fintech = _fintech;
        
        status = contract_status.ON;
        
        balance[buyer] = 0;
        balance[seller] = 0;
        balance[fintech] = 0;
        
        commission_cost = 10; // in %
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
        emit buyer_installment(msg.value);
    }

    function SetEndTime(uint _number_of_days) internal onlyBuyer {
        deadline = block.timestamp.add(_number_of_days); //this is just in seconds to test whether it works fine
        time = contract_time.ON_TIME;
    }
    
    function buyerUpload(string memory hash_buyer, uint _Number_of_Days) external onlyBuyer {
	    require(status == contract_status.ON, "Invalid status, status is not ON");
	   
	    docu_hashs[buyer] = hash_buyer;
	    status = contract_status.BUYER_UPLOADED;
	    
	    SetEndTime(_Number_of_Days);
	}
	
	function ExtendTime(uint _extension) external onlyBuyer{
        
        extension = _extension;
        deadline = block.timestamp.add(extension);
        
        time = contract_time.ON_TIME;
	}
	
	 function waiveDiscrepancies(bool _waive) public onlyBuyer{
        
        // In case the documents don't comply, the buyer can
        // decide whether to wave the discrepancies or terminate the
        // contract
        
        require(status == contract_status.DOC_DEFECT, "Invalid status");

        waive = _waive;

        uint money = address(this).balance;

        if (waive) {

		    status = contract_status.DOC_OK; //The buyer decides to wave the discrepancies

            uint commission; 
            commission = money.mul(commission_cost)/100; 

            // transfer all the money which is in the contract between seller and fintech
		    balance[seller] = (money - commission);
	    	balance[fintech] = (money - balance[seller]);

        } else {

	    	status = contract_status.DOC_REJECTED; //The buyer decides to terminate the contract

            uint defect;
            defect = money.mul(defect_fee)/100; 

            // transfer all the money which is in the contract between buyer and fintech
            balance[buyer] = (money - defect);
		    balance[fintech] = money - balance[buyer];


        }
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
	}
	
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
	
    function checkCompliance() public onlyOwner{
    
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
        
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        uint money = address(this).balance;
        // No discrepancies scenario
        if (keccak256(bytes(winningProposal())) == keccak256(bytes("Compliant"))){

    	    status = contract_status.DOC_OK; 
    
            uint commission; 
            commission = money.mul(commission_cost)/100; 
            
            // split the money owed to the fintech and the seller
    	    balance[seller] = (money - commission);
        	balance[fintech] = (money - balance[seller]);}
        	
    	// discrepancies scenario 
    	else {
            
        	status = contract_status.DOC_DEFECT; 
        	
            }
        }

/*    
    function fintechUpload(string memory hash_fintech) public onlyOwner{
        
        // In case the documents defect, the fintech can upload a document
        // for the buyer to review.
	    require(status==contract_status.DOC_DEFECT, "Invalid status, status is not DOC_DEFECT");
	    docu_hashs[fintech] = hash_fintech;

	}

*/    
    function sendMoney() public payable onlyOwner{
        
        require(status == contract_status.DOC_REJECTED || status == contract_status.DOC_OK , "Invalid status");
        
        uint amount_seller = balance[seller];
	    uint amount_fintech = balance[fintech];
	    uint amount_buyer = balance[buyer];
	    
	    balance[seller] = 0;
	    balance[buyer] = 0;
	    balance[fintech] = 0;
	    	
	    //works like transfer function but avoid reentrancy
    	(bool success_seller,) = seller.call{value : amount_seller}("");
    	require(success_seller);
    	(bool success_fintech,) = fintech.call{value : amount_fintech}("");
    	require(success_fintech);
		(bool success_buyer,) = buyer.call{value : amount_buyer}("");
    	require(success_buyer);
		
		status = contract_status.MONEY_SENT;
		assert(check_Contract_Balance() ==0);
	    	
    }
	
	
	/* selfdestruct the contract and give all the money 
    *  to the fintech (nice fail-safe mechanism but trust required */
    function destroycontract() public payable onlyOwner{
        selfdestruct(fintech);
    }
	
	
	// ----------------------------------------- Mixed Domain -----------------------------------------  //
	
	function See_Doc_Hash( address _user) public view returns(string memory){
        bool isbank = allowed_to_vote[msg.sender];
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || isbank==true, "not authorized");	    
        return docu_hashs[_user];
	}
    
    function canc() public view returns(bool _b){
        return allowed_to_vote[msg.sender];
    }
    
    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller, "not authorized");
        return address(this).balance;
    }
    
    
     //Some debug functions
	function getStatus() public view returns(LetterCredit.contract_status) {
		return status;
	}
	
	function getTime() public view returns(LetterCredit.contract_time) {
		return time;
	}

}
	// ----------------------------------------- End -----------------------------------------           //