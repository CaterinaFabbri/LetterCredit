# General instructions and description

Deploy the contract **LetterCredit**. \
As inputs insert buyer and seller addresses. The fintech address is the one that deploys the contract.

**At any time, the fintech can add or remove banks from the system using `giveRightToVote()` and `removeRightToVote()`. In future implementations it would be easy to let the fintech add or remove banks only when there isn't a voting due. \
Adding a bank previously removed doesn't reset whether it voted or not.**

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, aswell as a deadline for the seller. This can be done through the function `buyerUpload()` with inputs the hash of the document (we use IPFS) and the number of days available. \
If the buyer wants to extend the deadline, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract taking advantage of the `receive()`. It can be called at any time, allowing him to upload money in installments. **We switched to `receive()` because it works better with our front-end implementation**

Then, switch to the seller and use the function `SellerUpload()` to upload the document required by the buyer. To simplify, we assume that only a document needs to be uploaded.

**The fintech shall set a deadline for voting using `VotingEndTime()`. We considered setting it automatically, using a fixed amount of time, but we think it should depend on the complexity of the task.** 

**Banks can express their evaluation on the compliance of the document using `vote()`. \
Each bank who voted in line with the majority will receive an equal reward, while the others will obtain None. \
In future implementations, there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it.** 

It is time for a compliance check.  
**The fintech uses `checkCompliance()` to set the compliance status of the contract according to the outcome of voting. In future implementation this step can be triggered automatically taking advantage of events which keep track of whether all the banks voted or whether the deadline for voting has expired. \
In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the final evaluation and decision to the buyer.** \
In case of lack of compliance, indeed, the buyer can choose whether to waive the discrepancies and positively conclude the deal, or whether to stop the deal, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one. \
In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech.


`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.
