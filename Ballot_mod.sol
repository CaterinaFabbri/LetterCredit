//"SPDX-License-Identifier: UNLICENSED"

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


//if you want to try it remove line 226 (require(msg.sender == fintech || msg.sender == buyer || msg.sender == seller, "Only if allowed can see hashes");) 
//from Latest Prototype_Time.sol

pragma solidity 0.7.5;

contract Ballot is Ownable {
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }
    
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    mapping(address => Voter) public voters;
    mapping(address => bool) public allowed_to_vote;
    address[] public voters_addresses;
    Proposal[] public proposals;

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
    
    function giveRightToVote(address voter) public onlyOwner {
        require(!voters[voter].voted,"The voter already voted.");
        // add his address to the list of voters
        voters_addresses.push(voter);
        allowed_to_vote[voter] = true;
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount ++;
    }

    function winningProposal() onlyOwner public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() onlyOwner public view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function replenish_all_votes() public onlyOwner {
        for (uint v = 0; v < voters_addresses.length; v++) {
            address addr = voters_addresses[v];
            voters[addr].voted = false;
        }
    }

    
}
