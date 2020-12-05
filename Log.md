# Meeting Roadmap

**05-12 Latest_update.sol**

- Todoes for next meeting:
  - Improve the code with a `centralized fintech`, so to be able to send it to the professor
      - Give the fintech the possibility of uploading a document, when it doesn't judge the document as compliant, to explain the reason why
          
      * Give the seller the possibility to upload several documents , with compliance to be checked for each. One possible implementation is that the number of 'slots', or documents to be uploaded, is specified by the buyer according to the letter of credit. Otherwise, let's simplify and say that the seller uploads just one big document with everything which is required
        
      * Spread the content of our contract into multiple contracts, for security and clarity reasons
      * Give the seller the possibility to upload several documents , with compliance to be checked for each. One possible implementation is that the number of 'slots', or documents to be uploaded, is specified by the buyer according to the letter of credit. Otherwise, let's simplify and say that the seller uploads just one big document with everything which is required

      * Spread the content of our contract into multiple contracts, for security and clarity reasons

      * Reduce the number of view buttons, for example using events, or put them into another contract

      * The buyer shall declare and set the end-time upon uploading the Letter of Credit -- DONE

      * The buyer shall be able to decide whether or not he wants to continue the deal if the documents aren't compliant (he needs to be able to see the fintech's document and we may give this possibility only for relevant lack of compliance) -- DONE

**04-12 Professor Feedback pt. 2**

- Todoes for next meeting:
  - Improve the code with a `centralized fintech`, so to be able to send it to the professor
      - Give the fintech the possibility of uploading a document, when it doesn't judge the document as compliant, to explain the reason why
          
      * Give the seller the possibility to upload several documents , with compliance to be checked for each. One possible implementation is that the number of 'slots', or documents to be uploaded, is specified by the buyer according to the letter of credit. Otherwise, let's simplify and say that the seller uploads just one big document with everything which is required
        
      * Spread the content of our contract into multiple contracts, for security and clarity reasons
      * Give the seller the possibility to upload several documents , with compliance to be checked for each. One possible implementation is that the number of 'slots', or documents to be uploaded, is specified by the buyer according to the letter of credit. Otherwise, let's simplify and say that the seller uploads just one big document with everything which is required

      * Spread the content of our contract into multiple contracts, for security and clarity reasons

      * Reduce the number of view buttons, for example using events, or put them into another contract

      * The buyer shall declare and set the end-time upon uploading the Letter of Credit

      * The buyer shall be able to decide whether or not he wants to continue the deal if the documents aren't compliant (he needs to be able to see the fintech's document and we may give this possibility only for relevant lack of compliance)

  - Keep exploring the possiblities of the  `voting mechanism`, to step-up the project
      * Give the fintech the possibility to revoke the right to vote

      * Start merging the voting system into our contracts

      * Let the voting be on a specific document

      * let the outcome of the vote influence the state of the main contract (compliance, not_compliance etc.)

      * let the fintech create only one network of banks, which can vote on several documents in the same transaction between a buyer and a seller, for several couples of buyers and sellers

      * Implement the rewards for the banks, and the commission fee for the fintech




- What we improved since previous meeting:
  * We implemented all *todoes* coming from the previous meeting




**27-11 App and contract testing**

- Todoes for next meeting:
>
> Give the buyer the possibility to upload money in installments
> 
> Let the seller automatically get the money once there is compliance
>
> Give the Fintech a percentage-based return instead of a fixed one
>
> Add some more integration between the contract and the front-end app
>
>
> Start exploring the voting system in Solidity


- What we improved since previous meeting:
>
> Improved the front-end: now different people from different PCs and metamask accounts can interact with the smart-contract. It also automatically stores in the contract the hashed IPFS version of the documents that the seller and the buyer upload
>
> Added the time element to the contract 
>
> Checked the severity of the security issues in the contract (changing Solidity to 7.5 solves the most relevant ones)
>


**20-11 App and contract testing**

- Todoes for next meeting:
>
> Keep figuring out how to manage external inputs in the contract and how to create a front-end app
>
> Keep improving, refining and double-guessing the contract and what it does/what it should do


- What we improved since previous meeting:
>
> Unified the different .sol files and adapted the code so that it's more choesive
>
> Tested the prototype and improved it (adding more content to it)
>

**16-11 First Prototype**

- Todoes for next meeting:
>
> Better understand Solidity and how to interact with something 'external'
>
> Start working on a convenient front-end app
>
> Improve the basic prototype 

- What we improved since previous meeting:
>
> Created and tested a new basic prototype with a central Fintech
>

**14-11 Professor Feedback**

- Todoes for next meeting:
>
> Start implementing a basic prototype of a Letter of credit blockchain environment in which a centralized Fintech handles everything (basically digitalize the process)
>


- What we did
>
> Thourough discussion with the professor of what we thought of so far. New inputs on how to proceed and where to go
>

**10-11 Brainstorming**

- Todoes for next meeting:
>
> Schedule a meeting with the professor to assess the validity of the ideas and to start working on the one which gets approved
>


- What we did:
>
> Discuss and refine the proposed ideas and solutions
>


**05-11 Kick-off**
- Todoes for next meeting:
>
> Study the material and papers
>
> Familiarize with the topic
>
> Propose ideas and discuss them in the shared file


- What we did:
>
> Discuss the topic
>
> Think about ideas and implementations on how to improve the process related to the letter of credit
>
