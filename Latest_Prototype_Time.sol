pragma solidity 0.7;
//"SPDX-License-Identifier: UNLICENSED"

// LATEST CHANGES: 
// block.timestamp instea of now (sol 7.5);
// removed public from constructor (sol. 7.5);
// removed the compliance bool from variables;
// removed number_of_days from the variables;
// now fintech is the first argument of constructor;
// now using OpenZeppeling to set Fintech as owner (requires prevous step);
// now hashes of documents uploaded by buyer and seller are in a mapping,
// this assumes that only 1 document is needed to be uploaded for each, and
// that the document comes in the form of IPFS hash;
// now the buyer sets the endtime right on deployment of the contract, thus also
// on_time status of the contract is set when the buyer uploads the doc instead than in the constructor;
// reordered the functions (you surely may change this);
// removed public from a couple of time variables;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

/*
This contract is the union of the "Money Handler.sol" and "prototype.sol":
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
        //deadline = block.timestamp.add(_number_of_days * 1 days);
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
	
    function setCompliance(bool _compliance) public onlyOwner{
    
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        uint money = address(this).balance;
        
        // No discrepancies scenario
        if (_compliance == true) {
            
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
	    require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
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
	// ----------------------------------------- End -----------------------------------------           //
