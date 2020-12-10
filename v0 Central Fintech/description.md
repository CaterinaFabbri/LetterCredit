Deploy the contract LetterCredit.
As inputs insert the address of the fintech, the buyer and the seller.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, as well as a deadline for the seller. This can be done through the function `buyerUpload()` which inputs the hash of the document (we use IPFS) and the number of days available. If the buyer wants to extend the deadline, he can call the `ExtendTime()` function.
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the document required by the buyer. To simplify, we assume that only a document needs to be uploaded.

It is time for a compliance check. In this implementation, this step is taken care by the fintech. After downloading the files via the hashes uploaded by the buyer and the seller in the contract, the fintech checks the compliance between the two documents. It provides a feedback by using the `CheckCompliance()` function. If the feedback is true, the money is sent to the seller and the fintech takes a commission. If the result is False, it is up to the buyer to decide how to proceed in the transaction.

`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.
