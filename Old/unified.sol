// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

// MAIN CHANGES: 

//* When the Fintech checks the compliance (so far, NOT upgraded with time, or a mechanism that tells the fintech when to do it)
// now the ballot contract (winningProposal()) is used. 

//* The two contracts are unified in only one file. The owner of the contracts (fintech) needs to set for the LetterCredit contract
// the ballot adress, and viceversa.

//* There is no need to remove the require from LetterCredit.See_Doc_Hash(), indeed I have added to the address that can 
// access this function also 'msg.sender ==address_ballot' (the address of the ballot contract). In this way, it is possible 
// to call from the ballot contract this function. Note that only those that have access to the function in which is called
// the LetterCredit.See_Doc_Hash() will be credited as 'address_ballot'. 

//* The same happens for the Ballot.winningProposal. Here, the msg.sender must be either == owner() (used when the function is called directly from 
// the ballot contract), or == address_Prototype (used when the function is called by LetterCredit.checkCompliance).


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

/*
This contract:
1) Ether_Upload() -> instead of creating functions that allows to pay using different installments, Ether_Upload give the possiblity only to 
the buyer to upload money into the contract, therefore the buyer can upload the money in any moment and so also pay in installments.
2) buyerUpload() -> buyer requests documents (implement Ipfs)
3) sellerUpload() -> seller upload requested documents (implement Ipfs)
4) checkCompliance() -> Let the Fintech update a bool to signal that all documents are compliant 
(implement possibility to upload new documents if there are discrepancies)
5) money_to_seller() -> Give the seller the possibility of getting the money as soon as the documents are approved
6) money_to_Buyer()  -> Let the buyer have the money back if the documents aren't compliant and time expires
7) fintech_withdraw() -> Let the fintech withdraw its fees
8) check_Contract_Balance() -> Let the fintech update a bool to allow (or stop allowing) the buyer to retrieve the money
9) getBalance() -> get the balance of buyer, seller and fintech
10) destroycontract() -> fintech possibility to destroy contract and inherit the amount of the transaction.
Note: The fintech firm has no interest in behaving improperly as it has a reputation to maintain.
11) SetEndTime() -> lets the buyer set the expiration time of the letter of credit (in number of days)
12) ExtendTime() -> gives the buyer the possibility to extend time after the expiration date of the letter of credit
*/
//Upload document on IPFS and encrypt using public code of seller (and after buyer) 


contract LetterCredit is Ownable{
    
    using SafeMath for uint;
    
    //in order to call SimpleStorage
    address addressS;
    
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
    
    //define all the status that the contract may have
    enum contract_status {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT, MONEY_SENT} contract_status status;
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
    
    function SetBallotAddress(address _BallotAddress) external onlyOwner{
        address_ballot = _BallotAddress;
    }
	
    function checkCompliance() public onlyOwner{
    
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        uint money = address(this).balance;
        Ballot _ballot = Ballot(address_ballot);
        uint _compliance = _ballot.winningProposal();

        
        // No discrepancies scenario
        if (_compliance == 0) {
            
    	    status = contract_status.DOC_OK; 
    
            uint commission; 
            commission = money.mul(commission_cost)/100; 
            
            // split the money owed to the fintech and the seller
    	    balance[seller] = (money - commission);
        	balance[fintech] = (money - balance[seller]);}
        	
    	// discrepancies scenario 
    	else {
            
        	status = contract_status.DOC_DEFECT; 
        	
            uint defect;
            defect = money.mul(defect_fee)/100; 
    
            // split the money owed to the buyer and the fintech
            balance[buyer] = (money - defect);
    	    balance[fintech] = money - balance[buyer];
            }
        }
    
    
    function sendMoney() public payable onlyOwner{
        
        require(status == contract_status.DOC_DEFECT || status == contract_status.DOC_OK , "Invalid status");
        
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
	    require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller || msg.sender ==address_ballot);
	    return docu_hashs[_user];
	}

    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
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
	// ----------------------------------------- End LetterCredit-----------------------------------------           //
	
	// ----------------------------------------- Start Ballot---------------------------------------------           //
	
contract Ballot is Ownable{
    
    address address_Prototype;
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }
    
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    mapping(address => Voter) public voters;
    mapping(address => bool) public allowed_to_vote;
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
    
    function SetContractAddress(address _ContractAddress) external onlyOwner{
        address_Prototype = _ContractAddress;
    }
    
    function giveRightToVote(address voter) public onlyOwner {
        require(!voters[voter].voted,"The voter already voted.");
        // add his address to the list of voters
        voters_addresses.push(voter);
        allowed_to_vote[voter] = true;
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount ++;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        require(msg.sender == owner() || msg.sender == address_Prototype, "Invalid access");
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() onlyOwner public view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function replenish_all_votes() public onlyOwner {
        for (uint v = 0; v < voters_addresses.length; v++) {
            address addr = voters_addresses[v];
            voters[addr].voted = false;
        }
    }
    
    function Read_doc_hashes(address _Buyer_Or_Seller) public view returns (string memory){
        require(allowed_to_vote[msg.sender], "Only allowed to vote can see documents' hashes.");
        LetterCredit l = LetterCredit(address_Prototype);
        return(l.See_Doc_Hash(_Buyer_Or_Seller));
    }
    
}

	// ----------------------------------------- End Ballot---------------------------------------------           //
