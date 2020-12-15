# General considerations
Overall, the security in the prototypes is strengthened by the fact that permissioned users can interact very little with the contract, as they generally have only one shot to perform a task. Furthermore, everyone is generally intrinsically incentivized to behave well. \
Still, we are no pros in Solidity, so the code is very likely to have security bugs, and isn't meant to be used in production, but just to be considered as back-bone for a future implementation on the same process. This is expecially true for the few functions that interact with other contracts, so the ones about sending and receiving Ether. Indeed, we found much more intricated patterns for the task, such as in [King on Ether](https://github.com/kieranelby/KingOfTheEtherThrone/blob/v1.0/contracts/KingOfTheEtherThrone.sol), but we thought that implementing those patterns would have taken the focus away from the main scope of the project, and is mainly something to be done when scaling up the prototype to a production usage. \
Another consideration to make is that the fintech has a central role in all implementations. We think that it should have more restrictions, to reduce the trust required towards it. Still, each possible implementation of this type faces a trade-off between having fall-back mechanisms and having a more decentralized and automatic process. We discuss more in detail some of these aspects below

- The seller cannot embed amendments to its uploaded documents.
> We didn't all agree on whether this should be possible, as some of us think that when there are non-relevant discrepancies, the buyer can waive them, while when there are more relevant one, it's hard for the seller to fix them anyway (e.g. if the goods shipped aren't in the same number as they should have been, or their quality isn't what it was supposed to be).
> 
> Overall, it would be relatively easy to let the buyer have another option when the contract isn't compliant: he could also reset the contract status as it was before the seller uploaded its documents, so he has a chance do upload them again. Practically speaking, there are a number of ways to do this, e.g. by deleting docu_hashs[seller]; resetting contract status to buyer.uploaded and resetting the booleans about having voted to false

- Whenever it wants, the fintech can add addresses allowed to vote.
> This means that it can do so also when voting is happening on some documents. It also means that it can add several times the same users. 
>
> To prevent the latter, there can be simple mechanisms like letting each added user (bank) provide a formal document which allows to identify it, possibly adding a section also on its website for an easy double-check. More experimental solutions could let the buyer and seller choose - before the seller starts uploading his documents - whether there are some banks which that they want to prevent from voting on their documents; though we don't find many reasons for adding such a complicacy.
>
> As for the former, it would be easy for implementations v0 and v1 to add a require to `giveRightToVote()` and `removeRightToVote()`, specifying that contract status should not be SELLER_UPLOADED (it is the status when voting happens). In implementation v2 this would be trickier, maybe the best option would be to add a variable in the Voter struct, to store the date at which each bank is added. A time stamp should also be stored in a variable in LetterCredit, registering the time at which the seller uploads its first document. Then, in `cast_vote()`, require that the former time stamp isn't greater than than the latter

- The fintech can self-destruct the contract, getting all the money.
> It means that some degree of trust is required towards the fintech, but it can be a very useful fall-back mechanism

- The buyer may never set the waive status, thus the fintech won't be able to withdraw its funds.
> It's against the best interest of the buyer, as this wouldn't allow him to get his own money back.
>
> An additional last resort is that the fintech can self-destruct the contract, getting all the money.
>
> Finally, it would be easy to set a deadline also for this. We didn't do so to avoid making the code too cumbersome

- Can you abuse the `SetBalance()` function?
> Balances are set only once. **Reentrancy** isn't effective, as balances are set to the same **invariant amount** (the contract's money) even in case of double call.
>
> We say that the amount is invariant because it can change only in **2 cases**: when the buyer uploads money, or when someone withdraws money. 
>
>  - The latter thing can only happen after balance is set, so we can rule it out. 
>
>  - The former thing isn't relevant, as the buyer has to upload all the money due before the seller uploads his final document. Indeed, if he doesn't do so, the seller can see this and avoid proceding, and the buyer loses the defect_fee. If the buyer uploads money after the balance is set, it's a mistake of his since he has no reason to do so. Still, the fintech can selfdestruct the contract and eventually refund him


note: some choices were made for the sake of a better front-end integration, e.g. the use of `receive()` or some view functions 

