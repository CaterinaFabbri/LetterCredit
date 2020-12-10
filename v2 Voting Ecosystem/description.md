**Future Implementation

Deploy the contract **LetterCredit**. \
As inputs insert the address of the buyer and the seller. The fintech address is the one that deploys the contract.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, aswell as a deadline for the seller. This can be done through the function `buyerUpload()` with inputs the hash of the document (we use IPFS) and the number of days available. /
If the buyer wants to extend the deadline, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the document required by the buyer. To simplify, we assume that only a document needs to be uploaded.

It is time for a compliance check. Depending on the implementation, this step is taken care of by the Fintech, or by previously appointed banks. \
In the latter case, compliance is set through majority voting, for which there is a deadline. In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the decision to the buyer, as we will see in the next step. /
Only banks which voted according to the majority get a reward. The bank can add or remove banks at each time, emitting an event [maybe we can restrict the adding/removing only when there isn't a voting due]. **In this future implementation, there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it.**

Results of an election can be checked through `checkCompliance()`, callable by the fintech. In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech. In case of lack of compliance, the buyer can choose whether to waive the discrepancies and proceed with the transactions, thus obtaining the same outcome as just described, or whether to terminate the transactions, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one.


`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.
