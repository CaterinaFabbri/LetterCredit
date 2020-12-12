# LetterCredit

The aim of our project is to first digitalize and then to boldy innovate the letter of credit process. In order to do this, we prototyped three slightly different implementations, each adding complexity to the previous one 

## Repository Structure
The three folders **v0 Central Fintech**, **v1 Voting System** and **v2 Voting Ecosystem** contain a Solidity prototype and a .md file briefly describing its most relevant aspects and the main differences with regard to the previous prototype.  <br/>
The **General Documents** folder contains: `Log.md`, illustrating our general workflow, `General Idea.txt`, briefly describing some theoretical aspects of the ideas, `Pitfalls and Safety checks.txt`, describing some security considerations and checks we performed, as well as some aspects that can be improved

## General rules for contract deployment

In the following image we describe the pipeline and workflow of our most basic prototype, the **Central Fintech** one. While the other prototypes add complexity, the general framework reamins the same. <br/>
More detailed instructions and information are specified in each relevant folder, highlighting the differences among implementations


![plot](https://github.com/CaterinaFabbri/LetterCredit/blob/main/Documents%20and%20Images/Basic%20Structure.jpg)


## How to use the front-end
We created a [website](https://eth-app.yenerk95.vercel.app/) which allows to use the contract functionalities outside of Remix, through a Metamask integration. <br/>
There is an equivalent [page](https://eth-app-voting.yenerk95.vercel.app/) to manage also the voting implementation. The v2 implementation, the most experimental one, doesn't have a front-end, as it even more prototypical than the other implementations, and isn't for sure to be used in production. <br/>
In order to use the website, one needs to first deploy the contract in Remix, using Injected Web3 and a Metamask Testnet. <br/>
Then, the contract address shall be copypasted into the form on the top of the website. Subsequently, the workflow is as in Remix. <br/>
To upload a document, click on the logo and an IPFS hash will automatically be created. To actually upload the hash into the smart contract, it suffices to click `Buyer Upload` (specifying as argument only the number of days the seller will have in order to upload the documents) or `Seller Upload`.


[Here](https://github.com/yenerk95/eth-app) is the Github repo relative to the website
