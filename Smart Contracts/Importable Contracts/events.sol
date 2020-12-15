pragma solidity 0.7.5;
//"SPDX-License-Identifier: UNLICENSED"

/*
* @dev events will allow each user to see what's going on, while preserving privacy as much as possible
*/
contract Events {
    
    // -----------------------------------------  Ballot Events  ----------------------------------------- //
    
    // signal that fintech gives the right to vote    
    event NewVoter(address voter_address);
    // signal that fintech removes the right to vote
    event RemovedVoter(address voter_address);

    // -----------------------------------------  LetterCredit Events  ----------------------------------------- //

    // signal the start of the contract
    event ContractDeployed(uint deadline);
    
    // signal that the buyer has uploaded some money
    event BuyerInstallment();
    
	// signal that the seller has uploaded the document
	event SellerUpload();
	
    // signal an extension of the deadline
    event Deadline_extension(uint deadline);
    
	// signal that the Fintech has evaluated compliance of seller's document
	event ComplianceChecked();
	
	// signal that the buyer has decided either to waive or to end the transaction 
	event BuyerDecision(bool waive);
	
    // signal that someone has withdrawn money
    event Withdrawn(address withdrawer);
    
}