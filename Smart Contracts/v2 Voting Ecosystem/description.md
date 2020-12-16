## General Description 

**The main scope of this implementation is to test the scalability of the previous prototype. \
In order to do so, we we now let the fintech create and manage the network of banks allowed to vote in a manner which is independent from the specific instance of the `LetterCredit` contract. Indeed, it would be unfeasible to add separately the banks each time a `LetterCredit` is deployed. Here, instead, the network of banks needs to be created only once and it allows authorized banks to interface with several instances of `LetterCredit`. \
On a more technical side, originally the idea was to manage also the voting part in the `votingEcosystem` contract, by using mappings inside the Voter struct to map the varaibles relative to a specific `LetterCredit` instance. This would have allowed banks to only interact with `votingEcosystem`. Probably, though, it wasn't the best idea, as it doesn't really simplify things, and it was also quite hard to implement for a number of reasons (e.g. can't use [tx.origin](https://docs.soliditylang.org/en/v0.6.2/security-considerations.html#tx-origin), can't use [call](https://github.com/ethereum/solidity/issues/2884#issuecomment-329169020), methods like [delegatecall](https://medium.com/coinmonks/delegatecall-calling-another-contract-function-in-solidity-b579f804178c) would allow to act only on the storage of one of the two functions etc.). \
Thus, in `votingEcosystem` we just manage the general right to vote. The actual voting remains in the specific `LetterCredit` instances.**


**Deploy the contract `votingEcosystem`. \
The fintech is the one that deploys the contract. It can now start adding banks into the system.**

Deploy the contract `LetterCredit`. \
As inputs insert the address of the buyer and the seller **and the address of `votingEcosystem`** . The fintech is the one that deploys the contract.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, aswell as a deadline for the seller. This can be done through the function `buyerUpload()` with inputs the hash of the document (we use IPFS) and the number of days available. \
If the buyer wants to extend the deadline, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the document required by the buyer. To simplify, we assume that only a document needs to be uploaded.
**Within this step, the deadline for voting is automatically setted-up for convenience.**

Banks can express their evaluation on the compliance of the document using `vote()`. \
Each bank who voted in line with the majority will receive an equal reward, while the others will obtain None. \
In future implementations, there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it. \
**Here banks are authenticated by checking `votingEcosystem` state-variables.** 

It is time for a compliance check.  
The fintech uses `checkCompliance()` to set the compliance status of the contract according to the outcome of voting. In future implementation this step can be triggered automatically taking advantage of events which keep track of whether all the banks voted or whether the deadline for voting has expired. \
In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the final evaluation and decision to the buyer. \
In case of lack of compliance, indeed, the buyer can choose whether to waive the discrepancies and positively conclude the deal, or whether to stop the deal, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one. \
In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech.

It is time for a compliance check. Depending on the implementation, this step is taken care of by the Fintech, or by previously appointed banks. \
In the latter case, compliance is set through majority voting, for which there is a deadline. In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the decision to the buyer, as we will see in the next step. \
Only banks which voted according to the majority get a reward. The bank can add or remove banks at each time, emitting an event. In future implementations, there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it.

Results of an election can be checked through `checkCompliance()`, callable by the fintech. In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech. In case of lack of compliance, the buyer can choose whether to waive the discrepancies and proceed with the transactions, thus obtaining the same outcome as just described, or whether to terminate the transactions, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one.


`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.
