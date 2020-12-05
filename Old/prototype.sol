pragma solidity ^0.6.0;
//"SPDX-License-Identifier: UNLICENSED"

//ispired by  https://github.com/lockercho/blockchain-lc-demo/blob/master/LC.sol


contract LetterCredit {
    
    address payable buyer;
    address payable seller;
    address payable fintech;
    string buyer_document;
    string seller_document;
    
	enum contract_status {ON,BUYER_UPLOADED,SELLER_UPLOADED,MONEY_NOT_ENOUGH, DOC_OK, DOC_DEFECT}

	contract_status status; // all the status that the contract may have
	uint defect_fee; // fee held by the fintech company in case of no compliance (insert a number)
	uint commission_cost; // fee held by the fintech company in case of compliance (insert a number, it will be transformed in a %)
	
	constructor(address payable _buyer, address payable _seller, address payable _fintech, 
	            uint _defect_fee, uint _commission_cost) public {
	    buyer = _buyer;
	    seller = _seller;
	    fintech = _fintech;
	    status = contract_status.ON;
	    defect_fee = _defect_fee;
	    commission_cost = _commission_cost;
	}
	
	function buyerUpload(string memory _buyer_document) public payable {
	    //The buyer uploads the document, and the money
	    require(msg.sender == buyer, "Invalid access");
	    require(status==contract_status.ON,"Invalid status");
	    buyer_document = _buyer_document;
	    status = contract_status.BUYER_UPLOADED;
	}
	
	//Some debug functions
	function getBuyer() public view returns (address payable) {
	    return buyer;
	}
	
	function getSeller() public view returns (address payable) {
	    return seller;
	}

	function getStatus() public view returns (contract_status) {
	    return status;
	}
	
	function checkContractBalance() public view returns(uint) {
		return address(this).balance;
	}
	
	
    
	function sellerUpload(string memory _document, uint expected_fund) public{
        //The seller, after the buyer has uploaded the document and the money,
        //check that the money are enough and upload his document. 
        //In case the money are not enough, we can code smth more.
		require(msg.sender==seller,"Invalid access");
		require(status==contract_status.BUYER_UPLOADED, "Invalid status");
		
		if (checkContractBalance()==expected_fund) {
		    seller_document = _document;
		    status = contract_status.SELLER_UPLOADED;
		} else {
		    status = contract_status.MONEY_NOT_ENOUGH;
		    //Do something else?
		}
		
	}

	function checkCompliance(bool result) public payable {
	    //The fintech company checks the compliance of the
	    //documents. In case they comply the smart contract sends
	    //to the fintech company a % (commission_cost / 100) of the transaction,
	    //the rest is sent to the seller.
	    //In case the documents defect, the fintech takes only a defect fee. 
		
		require(msg.sender==fintech, "Invalid access");
		require(status==contract_status.SELLER_UPLOADED, "Invalid status");


		if(result) {
		    status = contract_status.DOC_OK;
		    uint money_seller = this.checkContractBalance() * (100 - commission_cost / 100);
		    uint money_fintech = this.checkContractBalance() - money_seller;
		    seller.transfer(money_seller); 
		    fintech.transfer(money_fintech); 
		    
		} else {
		    
		    status = contract_status.DOC_DEFECT;
		    fintech.transfer(defect_fee);
		    //Do something else??
		}                                                                     

	}
 // Create the destroy function in case of revert, as heritage depending on the state (if it is possible)
 // To avoid that the buyer could make the smart contract reverts in order to not send the money.
}
