# General instructions and description

Deploy the contract **LetterCredit**. \
As inputs insert buyer and seller addresses. The fintech address is the one that deploys the contract.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, as well as a deadline for the seller. This can be done through the function `buyerUpload()` which inputs the hash of the document (we use IPFS) and the number of days available to the seller. If the buyer wants to extend the deadline later on, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the hash of the document required by the buyer. To simplify, we assume that only one document needs to be uploaded.

It is time for a compliance check. In this implementation, this step is taken care by the fintech. \
After downloading the files via the hashes uploaded by the buyer and the seller in the contract, the fintech checks the compliance between the two documents. It provides a feedback by using the `CheckCompliance()` function. If the feedback is *true*, the money is sent to the seller and the fintech takes a commission, as the documents are compliant. In case of lack of compliance, the buyer can choose whether to waive the discrepancies and proceed with the transactions, thus obtaining the same outcome as just described, or whether to terminate the transactions, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one.

`withdrawFunds()` is the function that allows each party to withdraw the money owed to them.
