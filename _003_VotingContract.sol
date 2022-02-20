// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;


/*
OVERVIEW:

This contract allows a user to create a voting proposal, where a topic can be voted on yes or no. 
A voting proposal consists of the following elements: 
    Name of proposal
    Chairman (user) who created the proposal
    Time deadline (in minutes)
    Vote counts for yes and no. 

Once a proposal has been created, it can be voted on by any registered voter. To register, a voter must call getVotes function. 
    getVotes function simply gives the voter the specified number of votes. 
    Currently, there are no limitations on getting user votes. 

To vote on a proposal, the user must 
    Call the vote() function,
    Specifiy which proposal they are voting for,
    Specify how many votes they are using, and 
    Specify if they are in favor of the proposal (true) or against the proposal (false)

The proposal concludes when the time elapsed surpasses the amount of time specified when the proposal was created. 

Landon Crowther
02/20/2022

*/
contract VotingContract {

    address[] private voterAddressArray;
    mapping (address => Voter) public voterMapping;
    Proposal[] public proposalArray;

    struct Voter {
        uint numberOfVotes;
    }

    struct Proposal {
        string proposalName;
        address chairman; //account which starts proposal;
        // for now, only two options - yes or no
        uint votesForYes;
        uint votesForNo;
        uint deadline; // proposal time (in minutes) 
        // eventually a timeframe;
    }


    // creates a new proposal and adds it to the proposal array. 
    function createProposal(string memory _proposalName, uint _proposalMinutes ) public {
        // calculate future time value that proposal will close
        uint deadline = block.timestamp + (_proposalMinutes * 1 minutes);
        // update proposalArray. 
        Proposal memory p = Proposal(_proposalName, msg.sender, 0, 0, deadline);
        proposalArray.push(p);      

    }

    // determines the time remaining for a given proposal in seconds. 
    function getSecondsRemaining(uint _proposalIdx) public view returns(int) {
        Proposal memory p = proposalArray[_proposalIdx];

        uint proposalDeadline = p.deadline;
        uint currentTime = block.timestamp;
        int timeRemaining = int(proposalDeadline - currentTime);
        return timeRemaining;
        
    }

    // returns true if proposal is still eligible for voting
    function proposalStillOpen(uint _proposalIdx) public view returns(bool) {
        Proposal memory p = proposalArray[_proposalIdx];
        uint proposalDeadline = p.deadline;
        uint currentTime = block.timestamp;
        if (proposalDeadline > currentTime) {return true;}
        else {return false;}
    }


    // Adds votes to the address calling function. If voter does not exist, voter is created. Otherwise, adds more votes.
    function getVotes(uint _numVotes) public {
        
        if (voterExists(msg.sender)) { // voter exists, add to existing vote count
            voterMapping[msg.sender].numberOfVotes += _numVotes; 
        } else { // voter does not exist; create voter, add voter to voterAddressArray and voterMapping
            Voter memory v = Voter( _numVotes);
            voterMapping[msg.sender] = v;
            voterAddressArray.push(msg.sender);
        }
    }

    /*
        If proposal time has elapsed, the result of the proposal is determined. 
        Arguments:
            _proposalIdx: the index for the given proposal
        Returns:
            -1: votes for no > votes for yes
            0: votes for no = votes for yes
            1: votes for yes > votes for no. 
    */ 
    function determineProposalResult(uint _proposalIdx) public view returns(int8) {

        require( proposalStillOpen(_proposalIdx) == false, "Proposal has not yet concluded." );
        Proposal memory p = proposalArray[_proposalIdx];
        if (p.votesForYes == p.votesForNo) {return 0;}
        if (p.votesForYes > p.votesForNo) {return 1;}
        else {return -1;}

    }

    /*
    Arguments: 
        _proposalIdx: index of which proposal is being voted on
        _numberOfVotes: how many votes the voter wishes to use
        _voteForYes: if true, voter votes in favor of proposal. If false, voter votes against proposal. 

    Vote functoin for proposal. Vote function operates in the following way: 
        1. Make sure that given proposal is still open and that the deadline has not passed. 
        2. Make sure that the voter is eligible to vote. 
        3. If voting criteria allows, update the vote count on the given proposal
        4. If voting criteria allows, update the remianing votes of the voter. 
    */
    function vote(uint _proposalIdx, uint _numberOfVotes, bool _voteForYes) public {
       
        // 1. make sure that proposal is still open
        require( proposalStillOpen(_proposalIdx) , "Proposal has closed." );
        // 2. ensure that the voter is eligible to vote: voter.voteSpent is false & voter has sufficient votes. 
        require ( voterEligibleToVote( msg.sender, _numberOfVotes ) ); // verify voter is eligible for voting;

        // 3. update the vote count for the specific proposal
        Proposal storage proposal = proposalArray[_proposalIdx];
        if (_voteForYes) {
            proposal.votesForYes += _numberOfVotes;
        } else {
            proposal.votesForNo += _numberOfVotes;
        }

        // 4. update voter details (number of Votes spent & voteSpent boolean)
        Voter storage v = voterMapping[msg.sender];
        v.numberOfVotes -= _numberOfVotes;   //update number of votes remaining for voter
    }

    // Helper function that checks voter eligibility. 
    function voterEligibleToVote(address _voterAddress, uint _numberOfVotes) private view  returns (bool) {
        require( voterExists(_voterAddress), "Voter does not exist." ); //check if voter exists. 
        uint numVotes =  voterMapping[_voterAddress].numberOfVotes;
        require (numVotes >= _numberOfVotes, "User does not have enough votes."); // check if voter has enough votes. 
        return true;
    }

    // Helper function to determine if voter exists. Loops through voters in voterAddressArray. 
    function voterExists(address _voterAddress) view private returns(bool) {
        for (uint i=0; i < voterAddressArray.length; i++) {
            if ( voterAddressArray[i] == _voterAddress ) {
                return true;
            }
        }
        return false;
    }


 
    

}
