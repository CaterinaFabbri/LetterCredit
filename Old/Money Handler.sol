Most recent version:
pragma solidity >0.5.0 <0.7.0;

/*
This contract handles the money part of the transactions:
1) receive() -> Let the buyer put the money in the contract, possibly in installments
2) compliance_pass() -> Let the Fintech update a bool to signal that all documents are compliant
3) money_to_seller() -> Give the seller the possibility of getting the money as soon as the documents are approved
4) allow_buyer_out() -> Let the fintech update a bool to allow (or stop allowing) the buyer to retrieve the money
5) money_to_Buyer()  -> Let the buyer have the money back if the documents aren't compliant and time expires
*/


contract MoneyHandler {
    
    // define the addresses of the parties invovled
    address payable public buyer;
    address payable public seller;
    address         public fintech;
    // define the bool that the Fintech will set to True once documents are compliant
    bool public compliance;
    // define the bool that the Fintech will set to True if documents aren't compliant and
    // the buyer gains the possibility of withdrawing the money
    bool public buyer_out;
    
    
    // these arguments are set only once, when deploying the contract
    constructor (address payable _buyer,  address payable _seller, address _fintech) public payable{
    /* Stores the addresses of the buyer and of the seller
       and initializes the variables */
       
         buyer = _buyer;
         seller = _seller;
         fintech = _fintech;
         compliance = false;
         buyer_out = false;
    }
    
    receive() external payable {
    /* Let the buyer upload the money */
        require(msg.sender == buyer);
    }
    

    function compliance_pass() external {
     /* Let the fintech update the compliance status upon verification of documents.
        This enables the seller to retrieve the money */
    require(msg.sender == fintech);
    compliance = true;
        
    }
    
    function allow_buyer_out(bool _boolean) external {
     /* Let the fintech give (or take) the buyer the possibility of withdrawing from 
     the transaction, if there are relevant discrepancies */
    require(msg.sender == fintech);
    buyer_out = _boolean;
    }
    
    
    function money_to_Buyer() external {
     /* Let the buyer retrieve the money if documents aren't compliant */

        uint money = address(this).balance;
        require(money > 0, "Need to have money in the contract");
        require(compliance == false, "Safety check: buyer can't withdraw once documents are compliant");
        require(msg.sender == buyer, "Only the buyer can decide whether he wants to withdraw or not");
        require(buyer_out  == true, "The fintech must have authorized the buyer to withdraw");
        // transfer all the money which is in the contract
        buyer.transfer(money);

    }
    function money_to_Seller() external {
     /* Let the seller retrieve the money if documents are compliant
        Note: anyone can call this function*/

        uint money = address(this).balance;
        require(money > 0, "Need to have money in the contract");
        require(compliance == true, "Need compliance of documents");
        // transfer all the money which is in the contract
        seller.transfer(money);

    }
    
    function check_Contract_Balance() public view returns(uint){
        /* Give to each of the parties involved the possibility of checking the contract balance */
        require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller);
        return address(this).balance;
    }
    
    
}
