// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
 
 import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
 
 // Note: need to delete 'internal' from the constructor of Ownable.sol
 // or need to lower the solidity version
 
contract Ballot 
         is Ownable{
   
   // Define the Voter data-structure, -> who can vote?
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }
    
    // Define the proposal data-structure, -> what can be voted?
    struct Proposal {
        // use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    mapping(address => Voter) public voters;
    address[] public voters_addresses;
    Proposal[] public proposals;

    //  Initialize the two things that a bank can vote for: 
    // compliance of the document or no compliance
    constructor() {
        
        proposals.push(Proposal({
            name: "Compliant",
            voteCount: 0
            }));
        proposals.push(Proposal({
            name: "Not Compliant",
            voteCount: 0
            }));
    }
    
    /** 
     * @dev Give 'voter' the right to vote. May only be called by fintech.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public 
    onlyOwner {
        require(!voters[voter].voted,"The voter already voted.");
        require(voters[voter].weight == 0, "Can only give right to vote to whom doesn't have it yet");
        voters[voter].weight = 1;
        // add his address to the list of voters
        voters_addresses.push(voter);
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /** 
     * @dev Computes whether Compliance won or not
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() 
    onlyOwner 
    public view returns (uint winningProposal_) 
     {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /** 
    *   returns whether compliance won or not
     */
    function winnerName() 
    onlyOwner
    public view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    // gives every voter the right to vote again (for now useless)
    function replenish_all_votes() public 
    onlyOwner {
        for (uint v = 0; v < voters_addresses.length; v++) {
            address addr = voters_addresses[v];
            voters[addr].voted = false;
            }
        }
    
    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }
    
    
}