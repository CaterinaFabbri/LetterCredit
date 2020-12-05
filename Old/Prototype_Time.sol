pragma solidity >0.5.0 <0.7.0;
//"SPDX-License-Identifier: UNLICENSED"
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
// upload new document,  installment. 

//Upload document on IPFS and encrypt using public code of seller (and after buyer) 
//copy the  hash of the file on SimpleStorage (Qm...)
//
//before deploy SimpleStorage from buyer Account, than deploy of LetterCredit

contract SimpleStorage {

    string doc_hash;
    
    function store(string memory _hash) public returns(bool){
        doc_hash = _hash;
        return true;
    }

    function get() public view returns (string memory){
        return doc_hash;
    }
}



contract LetterCredit {
    
    using SafeMath for uint;
    
    //in order to call SimpleStorage
    address addressS;
    
    // define the addresses of the parties invovled
    address payable public buyer;
    address payable public seller;
    address payable public fintech;
    
    mapping(address => uint) balance;
    
    //define documents to be uploaded
    //string buyer_document;
    //string seller_document;
    
    //define deadline
    uint public Number_of_Days;
    uint public deadline;
    uint public extension;
    
    //define all the status that the contract may have
    enum contract_status {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT, MONEY_SENT} contract_status status;
    enum contract_time {ON_TIME, OUT_OF_TIME} contract_time time;
	
    // define the bool that the Fintech will set to True once documents are compliant
    bool public compliance;
    
    //define fees held by the fintech company
    uint defect_fee; // fee in case of no compliance
    uint commission_cost; // fee in case of compliance
	
    // these arguments are set only once, when deploying the contract
    constructor (address payable _buyer,  address payable _seller, address payable _fintech) public payable{
        
        /* Stores the addresses of the buyer and of the seller
        and initializes the variables */
        buyer = _buyer;
        seller = _seller;
        fintech = _fintech;
        compliance = false;
        status = contract_status.ON;
        time = contract_time.ON_TIME;
        balance[buyer] = 0;
        balance[seller] = 0;
        balance[fintech] = 0;
        commission_cost = 10; // in %
        defect_fee = 1;

    }
    
    function SetEndTime(uint _Number_of_Days) external{
        require(msg.sender == buyer, "Invalid access, only buyer can set the starting date");
        require(time == contract_time.ON_TIME, "Invalid status, status is not ON_TIME");
        
        Number_of_Days = _Number_of_Days;
        deadline = now.add(Number_of_Days); //this is just in seconds to test whether it works fine
        
        //deadline = now.add(Number_of_Days * 1 days);
    }
    
    function SetStorageAddress(address _addressS) external{
        addressS = _addressS;
    }
    

    function Ether_Upload() payable public returns (bool success) { 
        require(msg.sender == buyer, "Only the one who created the contract can upload ether");
        return true;
    }

    
    function buyerUpload(string memory hash_buyer) external{
        require(msg.sender == buyer, "Invalid access, only buyer can upload documents");
	    require(status == contract_status.ON, "Invalid status, status is not ON");
	    
	    //The buyer uploads the document 
	    //buyer_document = _buyer_document; (string memory _buyer_document)
	
	    //Using SimpleStorage
	    SimpleStorage s = SimpleStorage(addressS); // pointer to SimpleStorage, type variable (smart contract) name of variable (s)
	    s.store(hash_buyer);
	    //require(success, 'Error, documents not stored');
	
	    status = contract_status.BUYER_UPLOADED;
	}

	
    function sellerUpload(string memory hash_seller) public{
        
        //The seller, after the buyer has uploaded the document and the money, upload his document. 
	    require(msg.sender == seller,"Invalid access, only seller can upload documents");
	    require(status==contract_status.BUYER_UPLOADED, "Invalid status, status is not BUYER_UPLOADED");
	    
	    if (now >= deadline) {
	        
	        time = contract_time.OUT_OF_TIME;
	    }
	    
	    require(time == contract_time.ON_TIME, "Invalid status, status is not ON_TIME");
		
	    //seller_document = _document; (string memory _document)
	
	    //Using SimpleStorage
	    SimpleStorage s = SimpleStorage(addressS);
	    s.store(hash_seller);
        //require(success, 'Error, documents not stored');
        
	    status = contract_status.SELLER_UPLOADED;
	}
	
	function ExtendTime(uint _extension) external{
	    require(msg.sender == buyer, "Invalid access, only buyer can set the extension");
        
        extension = _extension;
        deadline = now.add(extension);
        
        time = contract_time.ON_TIME;
	}
	
	function ReadHash() public view returns(string memory){
	    require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
	    SimpleStorage s = SimpleStorage(addressS);
	    return s.get();
	}

    function checkCompliance(bool _compliance) public {
        
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
	    require(msg.sender == fintech, "Invalid access, only fintech can review documents");
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        uint money = address(this).balance;
        
        compliance = _compliance;

        if (compliance) {
            
		    status = contract_status.DOC_OK; //No discrepancies
    
            uint commission; 
            commission = money.mul(commission_cost)/100; 
            
            // transfer all the money which is in the contract between seller and fintech
		    balance[seller] = (money - commission);
	    	balance[fintech] = (money - balance[seller]);
	    	
		    
        } else {
            
	    	status = contract_status.DOC_DEFECT; //discrepancies
	    	
            uint defect;
            defect = money.mul(defect_fee)/100; 

            // transfer all the money which is in the contract between buyer and fintech
            balance[buyer] = (money - defect);
		    balance[fintech] = money - balance[buyer];
		    
		    
        }
    }
    
    
    function sendMoney() public payable {
        
        require(msg.sender == fintech, "Invalid access, only fintech can split money");
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

    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
        return address(this).balance;
    }
    
    
     //Some debug functions
    
    function getBalance() public view returns(uint) {
        return balance[msg.sender];
    }
    

	function getStatus() public view returns(LetterCredit.contract_status) {
		return status;
	}
	
	function getTime() public view returns(LetterCredit.contract_time) {
		return time;
	}
    

    function destroycontract() public payable {
        require(msg.sender == fintech);
        selfdestruct(msg.sender);
    }
}






    /****************************************   draft   **********************************************************/
    
    // define the bool that the Fintech will set to True if documents aren't compliant and
    // the buyer gains the possibility of withdrawing the money
    //bool public buyer_out;

    /*
    function FirstInstallment (uint256 amount) external payable {
        require(msg.sender == buyer,'only buyer can upload money');
        msg.value == amount;
    }*/
    
        
    /*
    function FinalInstallment (uint256 amount2) public payable {
        require(msg.sender == buyer,'only buyer can upload money');
        require(status == contract_status.DOC_OK);
        msg.value == amount2;
        status = contract_status.END;
    }
    
    function allow_buyer_out(bool _boolean) public {
        
        Let the fintech give (or take) the buyer the possibility of withdrawing from 
        the transaction, if there are relevant discrepancies 
        
        require(msg.sender == fintech);
        buyer_out = _boolean;
    }*/