- The fintech can self-destruct the contract, getting all the money
> It means that some degree of trust is required towards the fintech, but it can be a very useful fall-back mechanism

- the buyer may never set the waive status, thus the fintech won't be able to withdraw its funds.
>It's against the best interest of the buyer, as this wouldn't allow him to get is own money back.
>
>An additional last resort is that the fintech can self-destruct the contract, getting all the money.
>
>Finally, it would be easy to set a deadline also for this. We didn't do so to avoid making the code too cumbersome

- Can you abuse the `SetBalance()` function?
>Balances are set only once. **Reentrancy** isn't effective, as balances are set to the same **invariant amount** (the contract's money) even in case of double call.
>
>We say that the amount is invariant because it can change only in **2 cases**: when the buyer uploads money, or when someone withdraws money. 
>
>  - The latter thing can only happen after balance is set, so we can rule it out. 
>
>  - The former thing isn't relevant, as the buyer has to upload all the money due before the seller uploads his final document. Indeed, if he doesn't do so, the seller can see this and avoid proceding, and the buyer loses the defect_fee. If the buyer uploads money after the balance is set, it's a mistake of his since he has no reason to do so. Still, the fintech can selfdestruct the contract and eventually refund him