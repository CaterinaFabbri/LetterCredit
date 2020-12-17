pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"


// need to click on the error on the left, and remove 'internal' from the constructor
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/CaterinaFabbri/LetterCredit/blob/main/Smart%20Contracts/Importable%20Contracts/events.sol";


contract votingEcosystem is Ownable, Events {
        
        // maps an address to whether it is allowed to vote
        mapping(address => bool) public allowed_to_vote;
    
        function giveRightToVote(address voter) public onlyOwner {
            require(allowed_to_vote[voter] == false , "The user is already allowed to vote");
            // below check isn't required nor useful as of now
            //require(!voters[voter].voted,"The voter has already voted");
        
            allowed_to_vote[voter] = true;
            emit NewVoter(voter); 
            }
    
        function removeRightToVote(address voter) public onlyOwner {
            require(allowed_to_vote[voter] != false , "The user is already not allowed to vote");
            
            allowed_to_vote[voter] = false;
            emit RemovedVoter(voter);    
            }
        
        function isvoter(address _address) public view returns(bool _b) {
            return allowed_to_vote[_address];
        }
}
