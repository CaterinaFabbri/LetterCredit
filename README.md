# LetterCredit

The aim of our project is to first digitalize and then to boldy innovate the letter of credit process. Our general vision is that the banks no longer make the payment for the buyer, exposing themselves to risk in order to add guarantees for the seller. \
Instead, banks should only check the compliance of the seller's documents, acting as independent third-parties, while the payment enforcing should be granted by the smart-contract. \
We forsee advantages in terms of digitalization, risk (and fees) reduction, democraticization of the process, and greater access to the service.

In order to do this, we prototyped three different implementations with increasing complexity. \
Very briefly, in **v0 Central Fintech** we prototype a simple digitalization of the process, taking advantage of the blockchain enforcement. \
In **v1 Voting System** we add to the implementation a network of banks, which needs to express opinions on the compliance of the process. \
In **v2 Voting Ecosystem** we test the scalability of v1, removing a couple of restrictive assumptions.



## Repository Structure

The **General Documents** folder contains: \
`Log.md`, it illustrates the workflow throughout our meetings; \
`General Idea.txt`, it is the file we used to brainstorm remotely, and it briefly describes theoretical aspects of our ideas; \
`Pitfalls and Safety checks.txt`, it describes some security considerations and checks that we performed.

The **Smart Contracts** folder contains four sub-folders. \
Three of them contain a Solidity prototype which builds up on the previous one, and a .md file briefly describing the process and the main differences (highlighted) with regard to the previous prototype. \
The other subfolder contains the common contracts which are imported by all three implementations.


## General rules for contract deployment

In the following image we describe the pipeline and workflow of our most basic prototype, the **v0 Central Fintech** one. While the other prototypes add complexity, the general framework remains the same. <br/>
More detailed instructions and information are specified in each relevant folder, highlighting the differences among implementations.


![plot](https://github.com/CaterinaFabbri/LetterCredit/blob/main/Documents%20and%20Images/Basic%20Structure.jpg)


## How to use the front-end
For the v1 implementation, we created a [website](https://eth-app-final.yenerk95.vercel.app/) which allows to use the contract functionalities outside of Remix, through a Metamask integration. <br/>

In order to use the website, one needs to first deploy the contract in Remix, using Injected Web3 and a Metamask Testnet. Then, the contract address shall be copypasted into the form on the initial webpage.  <br/>
The website makes use of **conditional rendering**, so each user has access to a different page. To actually visualize the page of the current metamask account, it suffices to press again the set smart contract button.  <br/>
The workflow is pretty much as in Remix. To upload a document, click on the logo and an IPFS hash will automatically be created. To actually upload the hash into the smart contract, it suffices to click `Buyer Upload` (specifying as argument only the number of days the seller will have in order to upload the documents) or `Seller Upload`.


[Here](https://github.com/yenerk95/eth-app-final) is the Github repo relative to the website
