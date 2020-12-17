pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

// need to click on the error on the left, and remove 'internal' from the constructor
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

import "https://github.com/CaterinaFabbri/LetterCredit/blob/main/Smart%20Contracts/Importable%20Contracts/events.sol";


contract LetterCredit is Ownable, Events{
    
    using SafeMath for uint;
    
    // define the addresses of the parties invovled
    address payable public buyer;
    address payable public seller;
    address payable  fintech;
    
    mapping(address => uint) balance;
    mapping(address => string) docu_hashs;
    
    //define deadline
    uint deadline;
    
    //define all the statuses that the contract may have
    enum contract_status {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT, DOC_REJECTED} contract_status status;

    // fees held by the fintech company, as percentage of total money uploaded
    uint defect_fee;      // fee in case of no compliance
    uint compliance_fee;  // fee in case of compliance
	 
    constructor (address payable _buyer,  address payable _seller) payable{
        
        /* Stores the addresses of the buyer and of the seller
        and initializes the variables */
        fintech = msg.sender;
        buyer = _buyer;
        seller = _seller;    
        
        status = contract_status.ON;

        compliance_fee = 10; 
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

    /**
    * @dev allow the buyer to upload money at any time
    */
    function Ether_Upload() payable public onlyBuyer{ 
        emit BuyerInstallment();
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
	    
	    // eventually upload a first installment
	    Ether_Upload();
	    
    	emit ContractDeployed(deadline);
	}

    /*
    * @dev used by the buyer to set the deadline. Called by prev. function.
    * @params _number_of_days num days the seller has from current day to upload his docs
    */
    function SetEndTime(uint _number_of_days) internal onlyBuyer {
        deadline = block.timestamp.add(_number_of_days * 1 days);
    }
    
	/*
	* @dev allows the buyer to extend the deadline.
	* @params _extension num of additional days the seller will have 
	*/
	function ExtendTime(uint _extension) external onlyBuyer {
        deadline = deadline.add(_extension * 1 days);
        emit Deadline_extension(deadline);
	}
    
    /*
    * @dev allows the buyer to decide whether to waive the discrepancies or terminate the
    * contract, in case the documents don't comply.
    * @params _waive false to terminate transaction, true to waive discrepancies
    */
    function waiveDiscrepancies(bool _waive) public onlyBuyer {
    
        require(status == contract_status.DOC_DEFECT, "Can only use this function if there are discrepancies");
        
        if (_waive) {

		    status = contract_status.DOC_OK; //The buyer decides to waive the discrepancies

            // split the money owed to the fintech and the seller
            setBalances(compliance_fee, seller); }
	    	
        else {

	    	status = contract_status.DOC_REJECTED; //The buyer decides to terminate the contract
		// split the money owed to the fintech and the buyer		}
           	setBalances(defect_fee, buyer); }
            
        emit BuyerDecision(_waive);
        }
    
	// ----------------------------------------- Seller Domain -----------------------------------------  //
	
	/*
    * @dev allows the Seller to upload his document.
    * @params hash_seller hash from which to retrieve the document
    */
    function sellerUpload(string memory  hash_seller) public onlySeller {
    
	    require(status==contract_status.BUYER_UPLOADED, "Invalid status, status is not BUYER_UPLOADED");
	    require(block.timestamp <= deadline, "Time for uploading expired");
		
	    docu_hashs[seller] = hash_seller;
	    status = contract_status.SELLER_UPLOADED;
	    emit SellerUpload();
	}
	
    // ----------------------------------------- Fintech Domain -----------------------------------------  //
	
	
   /*
    * @dev allows the fintech to update the compliance status upon verification of documents.
    *      This can enable the seller to retrieve the money. 
    * @params _compliance set to true if there is compliance
    */
    function setCompliance(bool _compliance) public onlyOwner{
    
        require(status == contract_status.SELLER_UPLOADED, "Invalid status, status is not SELLER_UPLOADED");
        
        // No discrepancies scenario
        if (_compliance == true) {
            
    	    status = contract_status.DOC_OK; 
            
            // split the money owed to the fintech and the seller
            setBalances(compliance_fee, seller); }
        	
    	// discrepancies scenario 
    	else {
            
        	status = contract_status.DOC_DEFECT; 
		}
            
        emit ComplianceChecked();    
        }
	
/*  
    * @dev In case the documents defect, the fintech can upload a document
    *      to explain the reason
    function fintechUpload(string memory hash_fintech) public onlyOwner{
        

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
	
	/*
    * @dev internally called function to settle balances,
    *      in both cases of compliance and no compliance. 
    * @params commission_fee % of total money in the contract taken by the fintech
    *         user_payable address of user who will receive the money minus the fee
    */
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
        require(address(this).balance > 0, "No money in the contract");
        
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
	function See_Doc_Hash(address _user) public view returns(string memory){
	    require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
	    return docu_hashs[_user];
	}

    /*
	*  @dev let the parties check the money in the contract
    */
    function check_Contract_Balance() public view returns(uint){
        
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
        return address(this).balance;
    }
    
}
	// ----------------------------------------- End -----------------------------------------           //
