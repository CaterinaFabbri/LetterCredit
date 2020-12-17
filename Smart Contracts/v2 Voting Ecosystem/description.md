## General Description 

**The main scope of this implementation is to test the scalability of the previous prototype. \
In order to do so, we now let the fintech create and manage the network of banks allowed to vote in a manner which is independent from the specific instance of the `LetterCredit` contract. This way, the network of banks needs to be created only once and it allows authorized banks to interface with several instances of `LetterCredit`. 
Notably, in `votingEcosystem` we just manage the general right to vote. The actual voting remains in the specific `LetterCredit` instances.\
Furthermore, here we remove the assumption that only one document needs to be uploaded by the seller. By doing so, we now need to vote, check compliance and possibly waive discrepancies on each single document uploaded by the seller. \
It needs to be noted that a lot of complicacies are added by these changes, thus this implementation, even more so than the others, is to be considered as prototypical, as it's probably vulnerable to some sophisticated malicious attacks**


**note on convention: a lot of functions refer to a specific document, which is inputted as argument via *num_document*, where 0 <= *num_document* < *num_docs_to_upload*. Thus, 0 stands for the first document.**

### steps:

**Deploy the contract `votingEcosystem`. \
The fintech is the one that deploys the contract. It can now start adding banks into the system.**

Deploy **one or more** `LetterCredit` contracts. \
As inputs insert the address of the buyer and the seller **and the address of `votingEcosystem`** . The fintech is the one that deploys the contract.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, as well as a deadline for the seller. This can be done through the function `buyerUpload()` with inputs the hash of the document (we use IPFS), the number of days available **and the number of documents that the seller will need to provide**. \
If the buyer wants to extend the deadline, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the documents required by the buyer. **It can upload as many documents as previously stated by the buyer. It can upload his documents whenever he wants, as long as his deadline doesn't expire.** \
**Within this step, the deadline for voting on the relative document is automatically setted-up for convenience.**

Banks can express their evaluation on the compliance of a document using `vote()`. \
**Here it is trickier to give the rewards to banks who voted according majority: do we consider each single voting on each single document, or do we require some condition to be met on the overall votings? We preferred the former, and we found two possible implementations. \
The first idea - the one we adopted - is that, at each voting, we push into an array the addresses of 'winning' firms, and we set their balances at the end, proportionally to how many times they voted according to majority. E.g., say that bank A voted according to majority 2 times, bank B 1 time and bank C 0 times, and assume the total fee to be payed to banks is 100. Then, Bank A would get 2/3 of the reward, while bank B would get the remaining third. \
The other option is to settle their balances after each voting concludes (so when `checkCompliance()` is called), and transfer their due money into an [escrow](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/payment/escrow/Escrow.sol) contract, from which they can pull, at any time, the money owed to them. This latter one would probably be the safest implementation, but it would be dependent on the buyer upoloading its installments. Thus, we opted for the former, as it works even if the buyer uploads his money very late, and the rewards are equal neverthless the amount of the individual installments.**. \
In future implementations, there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it. \
**Here banks are authenticated by checking `votingEcosystem` state-variables.** 

It is time for a compliance check.  
**The fintech uses `checkCompliance()` to set the compliance status of the a document according to the outcome of voting. If the seller has uploaded all due documents, then compliance is finally checked for the whole contract, the status is set to *not_compliant* if any of the documents isn't compliant, and to *compliant* otherwise, in which case balances are also settled.  ** \
**Note that compliance checks and votings can happen in any order (e.g. on the second document before than on the first one), as long as the relative document has been uploaded and the relative deadline is met.** \
**When checking compliance for a document, we also let the voting deadline expire for that document, which enables the buyer to waive discrepancies on that document. This makes even more sense in future implementations,** where `checkCompliance()` can be triggered automatically, taking advantage of events which keep track of whether all the banks voted or whether the deadline for voting has expired. \
In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the final evaluation and decision to the buyer. \
In case of lack of compliance, indeed, the buyer can choose whether to waive the discrepancies and positively conclude the deal, or whether to stop the deal, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveAllDiscrepancies()` inputting *true* in the former case and *false* in the latter one. \
In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech.
**It is to note that here the buyer can also waive discrepancies on a single document, through `waiveDocDiscrepancy()`. This may allow the seller to understand the intentions of the buyer. It can make even more sense in future implementation, as discrepancies may be further deemed by the banks as *major* or *minor*, and for the former ones a deadline may trigger for the buyer, who will need to decide whether to end the contract and get his money back, or whether to waive the discrepancy or to settle it as *minor*, so that he he will be able to make a final decision upon seeing further documents by the seller.**



`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.
