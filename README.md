# LetterCredit
## 1. General rule to deploy the contract: 
Deploy the contract LetterCredit. As inputs insert the address of the buyer and the seller. 
The fintech address is the one that deploys the contract. 

Then, switch to the buyer address: it is time to send a document that explicates the files and details required to consider the transaction successful and a deadline for the seller (function `buyerUpload()` with as input the hash of the 
document - we use IPFS - and the number of days available). In case the buyer wants to extend the deadline can call the `ExtendTime()`
function. 
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. Being able to be called at any time, 
it works like installment payments. 

Then, switch to the seller and use the function `SellerUpload()` to upload the documents required by the buyer. 

At any time, the fintech can give the right to vote on documents compliance through the function `giveRightToVote()`, and set the deadline
to exercise the vote (`VotingEndTime()` function). Only the banks accredited by fintech will be able to vote. 
The vote can only be expressed when the seller has completed the uploading of documents (`vote()` function). The two voting options
available are 0 (Not compliant) if the bank found some irregularities between the buyer and seller documents and 1 in case the documents
comply. 
The result is determined by the majority principle, and in the event of a tie, we decide to set the documents to not compliant. 
We have adopted this strategy as we believe that if half of the banks believe the documents are not compliant, it is less risky not
to proceed with the transaction. Also, note that the transaction is not concluded. Indeed, if the documents are not compliant, 
the buyer chooses whether to waive the discrepancies or terminate the contract (to waive the discrepancies the buyer needs 
to input true to the function `waiveDiscrepancies()` when the contract status is document defect). 

To check the result of the election, you need to switch to the fintech account and press the function `checkCompliance()`.
With this function, the ether contained within the smart contract is divided between the parties according to the status
of the contract in case of compliance but is not yet sent. In case of not compliance, as already said above, the buyer needs
before to decide whether to waive or not the discrepancies, and finally the money will be divided. 

`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed. We decide to create a function
that allows to separately withdraw the money to avoid malicious behavior in the event that multiple players are called in this function.
