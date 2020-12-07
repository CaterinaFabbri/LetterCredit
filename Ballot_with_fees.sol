import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Ballot is Ownable {
    
    using SafeMath for uint;
    
    // things that are different from what is in the Ballot function in Main.sol:
    // 1) new array that keeps track of all adresses allowed to vote (called bank)
    // 2) function feesPayment(). the fun takes no input, only need to set a value and it will automatically 
    // split it among banks that voted.

    enum contract_status  {ON, BUYER_UPLOADED, SELLER_UPLOADED, DOC_OK, DOC_DEFECT,DOC_REJECTED, MONEY_SENT} contract_status status;
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }
    
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }
    

    mapping(address => Voter)  voters;
    mapping(address => bool)  allowed_to_vote;
    Proposal[] public proposals;
    
    address[] bank; //variable to store bank adresses

    event NewVoter(address voter_address);
    event RemovedVoter(address voter_address);
    
    constructor() {
        
        proposals.push(Proposal({
            name: "Not Compliant",
            voteCount: 0
            }));   
        proposals.push(Proposal({
            name: "Compliant",
            voteCount: 0
            }));
    }
    
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

    /* let a bank vote, modifying its Voter struct accordingly */
    function vote(uint proposal) public {
        //require(status == contract_status.SELLER_UPLOADED, "Can't vote on a document not yet uploaded");
        bool isbank = allowed_to_vote[msg.sender];
        require(isbank == true, "must be allowed to vote");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount ++;
        //store the adresses of those bank who voted and therefore deserve a fee
        bank.push(msg.sender); 

    }

    function winningProposal() onlyOwner public view returns (string memory winnerName_){
        uint winningVoteCount = 0;
        uint winningProposal_ = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        winnerName_ = proposals[winningProposal_].name;
        return(winnerName_);
    }
    
    function feesPayment() payable public onlyOwner{
        //for the moment a same fee is distributed among all banks that participated to the ballot 
        //independently by the fact that some won and other lose
        uint monetary_fee = address(this).balance; //set some money into the box value next to wei(or ether) before pressing the button
        uint fee = monetary_fee.div(bank.length);
        //with for loop the amount set before pressing the button is divided among those banks who voted
        for(uint i=0; i<bank.length; i++){
        (bool success_bank,) = bank[i].call{value : fee}("");
    	require(success_bank);
        }
    }

}
