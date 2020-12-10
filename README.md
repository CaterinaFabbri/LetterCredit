# LetterCredit

The aim of our project is to first digitalize and then to boldy innovate the letter of credit process. In order to do this, we prototyped three slightly different implementations, each adding complexity to the previous one 

## Repository Structure
The three folders **Central Fintech**, **Voting System** and **Voting Ecosystem** contain a Solidity prototype and a .md file briefly describing its most relevant aspects.
The **General Documents** folder contains: `Log.md`, illustrating our general workflow, `General Idea.txt`, briefly describing some theoretical aspects of the ideas, `Pitfalls and Safety checks.txt`, describing some security considerations and checks we performed, aswell as some aspects that can be improved

## General rules for contract deployment

In the following image we describe the pipeline and workflow of our most basic prototype, the **Central Fintech** one. While the other prototypes add complexity, the general framework is the same. We also provide a brief general description of the steps to be performed.
![plot](https://github.com/CaterinaFabbri/LetterCredit/blob/main/Documents%20and%20Images/Basic%20Structure.png) \



Deploy the contract **LetterCredit**. \
As inputs insert the address of the buyer and the seller. The fintech address is the one that deploys the contract.

Then, switch to the buyer address. It is time to send a document that explicates files and details required to consider the transaction successful, aswell as a deadline for the seller. This can be done through the function `buyerUpload()` with inputs the hash of the document (we use IPFS) and the number of days available. /
If the buyer wants to extend the deadline, he can call the `ExtendTime()` function. \
The buyer can upload the money in the smart contract through the function `Ether_Upload()`. It can be called at any time, allowing him to upload money in installments.

Then, switch to the seller and use the function `SellerUpload()` to upload the document required by the buyer. To simplify, we assume that only a document needs to be uploaded.

It is time for a compliance check. Depending on the implementation, this step is taken care of by the Fintech, or by previously appointed banks. \
In the latter case, compliance is set through majority voting, for which there is a deadline. In case a tie happens, we decided to set no-compliance as the default outcome. We have adopted this strategy as we believe that if half of the banks deem the documents as not compliant, it is less risky to leave the decision to the buyer, as we will see in the next step. /
Only banks which voted according to the majority get a reward. The bank can add or remove banks at each time, emitting an event [maybe we can restrict the adding/removing only when there isn't a voting due]. In future implementations there can be a weighted voting based on the trust score of banks, where the trust score is modelled according to how many times a bank voted according to the majority, following a function on the line of that described in Yu and Munindar (2000), which follows the idea that gaining trust is easier than losing it.

Results of an election can be checked through `checkCompliance()`, callable by the fintech. In case of compliance, the fees are calculated and the money is sent to seller/banks/fintech. In case of lack of compliance, the buyer can choose whether to waive the discrepancies and proceed with the transactions, thus obtaining the same outcome as just described, or whether to terminate the transactions, getting back his money minus a fee. The buyer can choose the outcome by calling `waiveDiscrepancies()` inputting *true* in the former case and *false* in the latter one.


`withdrawFunds()` is the function that each player needs to press in order to withdraw the money owed.

## How to use the front-end
injected web3, metamask, copy contract address etc.



