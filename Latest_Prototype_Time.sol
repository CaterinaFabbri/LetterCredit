pragma solidity 0.7;
//"SPDX-License-Identifier: UNLICENSED"

// LATEST CHANGES: 
// fintech is the msg.sender
// created an internal function to settle balances, to avoid code-repetition
// added an evil genius contact to test fund withdrawal
// changed the way funds are withdrawn, to make the process more secure
// added tons of events, so each user is able to now able to see what's going on, while preserving privacy
// now the buyer can set an ether value when uploading the letter of credit document, to upload a first installment



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

contract Events {
    
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


contract LetterCredit is Ownable, Events{
    
    using SafeMath for uint;
    
    //in order to call SimpleStorage
    address addressS;
    bool waive;
    
    // define the addresses of the parties invovled
    address payable public buyer;
    address payable public seller;
    address payable public fintech;
    
    mapping(address => uint) balance;
     // can be made bytes32 in production, more efficient
    mapping(address => string) docu_hashs;
    
    //define deadline
    uint public deadline;
    uint extension;
    
    //define all the status that the contract may have
    enum contract_status {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT, DOC_REJECTED} contract_status status;
    enum contract_time {ON_TIME, OUT_OF_TIME} contract_time time;
    
    //define fees held by the fintech company
    uint defect_fee;      // fee in case of no compliance
    uint compliance_fee;  // fee in case of compliance
	 
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
        
        compliance_fee = 10; // in %
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
	
    function SetEndTime(uint _number_of_days) internal onlyBuyer {
        deadline = block.timestamp.add(_number_of_days * 1 days);
        //deadline = block.timestamp.add(_number_of_days); 
        time = contract_time.ON_TIME;
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
	    emit SellerUpload();
	}
	
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
	
    function setCompliance(bool _compliance) public onlyOwner{
    
        /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        // No discrepancies scenario
        if (_compliance == true) {
            
    	    status = contract_status.DOC_OK; 
            
            // split the money owed to the fintech and the seller
            setBalances(compliance_fee, seller); }
        	
    	// discrepancies scenario 
    	else {
            
        	status = contract_status.DOC_DEFECT; 
    
            // split the money owed to the fintech and the buyer
            setBalances(defect_fee, buyer);}
            
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
	    require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
	    return docu_hashs[_user];
	}

    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
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
