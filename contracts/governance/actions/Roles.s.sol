// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol";

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment. 

contract Roles is ActionHelpers {
    uint16[] mandateSlots; 
    uint256[] actionIds; 

    uint256 roleCount; 
    uint256 againstVote; 
    uint256 forVote; 
    uint256 abstainVote;

    // NB: All 'negative' actions (revoking roles, removing delegates, etc.) are not included yet. Can be added later. 

    ///////////////////////////////////////////////////////////////
    //                  PRIMARY LAYER ROLES                      // 
    ///////////////////////////////////////////////////////////////
    function getParticipantRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }

    function getStewardsRole_PrimaryLayer(address primaryLayer, address ideasLayer, address convergenceLayer, uint256 nonce) public {
   
    }


    ///////////////////////////////////////////////////////////////
    //                  DIGITAL LAYER ROLES                      // 
    ///////////////////////////////////////////////////////////////
    // Because depends on interaction with github repo, for now not tested. Will be tested later.
    // function getWriterRole_DigitalLayer(address powers, uint256 nonce) public { 

    // }

    // function revokeWriterRole_DigitalLayer(address powers, uint256 nonce) public { 

    // }

    // function getMaintainerRole_DigitalLayer(address powers, uint256 nonce) public { 

    // }

    // function revokeMaintainerRole_DigitalLayer(address powers, uint256 nonce) public { 

    // }


    ///////////////////////////////////////////////////////////////
    //                   IDEAS LAYER ROLES                       // 
    ///////////////////////////////////////////////////////////////
    function getParticipantRole_IdeasLayer(address powers, uint256[] memory privateKeys, uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates in the Assign Participant flow.
        mandateSlots.push(findMandateIdInOrg("Apply for Participant role: Anyone can apply for a Participant role to the Ideas Layer by submitting an application.", Powers(payable(powers))));
        mandateSlots.push(findMandateIdInOrg("Assess and Assign Participant: Assessors can assess applications and assign a Participant role to applicants.", Powers(payable(powers))));

        address testAccount1 = vm.addr(privateKeys[1]);

        // step 2: check if user has the permissions to run these mandates.
        Powers(payable(powers)).canCallMandate(msg.sender, mandateSlots[0]); // should return true (public mandate).
        Powers(payable(powers)).canCallMandate(testAccount1, mandateSlots[1]); // should return true (msg.sender must be Assessor).

        bytes memory callData = abi.encode(msg.sender, "");

        // step 3a: apply for Participant role (public, no voting required).
        vm.startBroadcast();
        IPowers(powers).request(mandateSlots[0], callData, nonce, "Applying for Participant role");
        vm.stopBroadcast();

        // step 3b: assess and assign Participant role (Assessors only, needFulfilled from step 3a).
        vm.startBroadcast(privateKeys[0]);
        IPowers(powers).request(mandateSlots[1], callData, nonce, "Assigning Participant role");
        vm.stopBroadcast();
    }

    function getAssessorsRole_IdeasLayer(address powers, uint256[] memory privateKeys, uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate in the Assign Assessor flow (skipping Participants veto).
        mandateSlots.push(findMandateIdInOrg("Assign Assessor Role: Stewards can assign the Assessor role to an account.", Powers(payable(powers))));

        bytes memory callData = abi.encode(msg.sender);

        // step 2: propose Assessor role assignment (requires voting: 51% majority, 30% quorum).
        vm.startBroadcast(privateKeys[0]);
        actionIds.push(IPowers(powers).propose(mandateSlots[0], callData, nonce, "Proposing to assign Assessor role"));
        vm.stopBroadcast();

        // step 3: vote on proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            powers,
            mandateSlots[0],
            actionIds[0],
            privateKeys,
            nonce,
            100 // pass chance in percentage.
        );

        console2.log("Votes cast for assigning Assessor role: ", forVote);
        console2.log("Votes cast against assigning Assessor role: ", againstVote);
        console2.log("Total voters: ", roleCount);

        // step 4: execute Assessor role assignment (after voting period ends with no fulfilled veto).
        vm.startBroadcast(privateKeys[0]);
        IPowers(powers).request(mandateSlots[0], callData, nonce, "Assigning Assessor role");
        vm.stopBroadcast();
    }


    ///////////////////////////////////////////////////////////////
    //              IDEAS LAYER: ELECT STEWARDS                  //
    // Note: the election flow is time-gated. Run the three      //
    // phases in order, waiting between each:                    //
    //   1. createStewardElection_IdeasLayer  (create + nominate)//
    //   ⏳ wait for nomination period to end                    //
    //   2. voteInStewardElection_IdeasLayer  (open + cast votes)//
    //   ⏳ wait for voting period to end                        //
    //   3. tallyStewardElection_IdeasLayer   (tally + cleanup)  //
    ///////////////////////////////////////////////////////////////
    function createStewardElection_IdeasLayer(
        address ideasLayer,
        uint256[] memory privateKeys,
        uint256 nonce
    ) public returns (uint256 electionId) {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates in the Elect Stewards flow.
        mandateSlots.push(findMandateIdInOrg("Create a Steward election: an election for the Steward role can be initiated by any Participant. The election will be open for 5 minutes.", Powers(payable(ideasLayer))));
        mandateSlots.push(findMandateIdInOrg("Nominate for election: any Participant can nominate for an election.", Powers(payable(ideasLayer))));

        // step 2: create election and have each private-key holder nominate themselves.
        electionId = createElectionAndNominate(
            ideasLayer,
            mandateSlots[0],
            mandateSlots[1],
            "Steward Election 1",
            privateKeys,
            nonce
        );

        console2.log("Steward election created. Election ID: ", electionId);
    }

    function voteInStewardElection_IdeasLayer(
        address ideasLayer,
        address electionRegistry,
        bool[][] memory voteSelections,
        uint256 electionId,
        uint256[] memory privateKeys,
        uint256 nonce
    ) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify the mandate for opening the Steward election vote.
        mandateSlots.push(findMandateIdInOrg("Open voting for Steward election: After five minutes of initiating an election, Participants can open the vote for a Steward election. This will create a dedicated vote mandate.", Powers(payable(ideasLayer))));

        // step 2: open voting and cast votes.
        openVotingAndCastVotes(
            ideasLayer,
            electionRegistry,
            mandateSlots[0],
            electionId,
            "Steward Election 1",
            privateKeys,
            voteSelections,
            nonce
        );
    }

    function tallyStewardElection_IdeasLayer(
        address ideasLayer,
        uint256 nonce
    ) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates for tallying and cleanup.
        mandateSlots.push(findMandateIdInOrg("Tally Steward elections: After five minutes of opening the vote, tally the results and assign the Steward role to the winners.", Powers(payable(ideasLayer))));
        mandateSlots.push(findMandateIdInOrg("Clean up Steward election: After five minutes of tallying the results, clean up related mandates.", Powers(payable(ideasLayer))));

        // step 2: tally results and clean up election mandates.
        tallyElection(
            ideasLayer,
            mandateSlots[0],
            mandateSlots[1],
            "Steward Election 1",
            nonce
        );

        console2.log("Steward election tallied and cleaned up successfully.");
    }


    ///////////////////////////////////////////////////////////////
    //                CONVERGENCE LAYER ROLES                    // 
    ///////////////////////////////////////////////////////////////
    function getAttendeeRole_ConvergenceLayer(address powers, uint256 nonce) public { 

    }

    function getStewardRole_ConvergenceLayer(address convergenceLayer,  uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates in the 'Select Stewards' flow at the Convergence Layer.
        mandateSlots.push(findMandateIdInOrg("ZK-Passport Check Age: Anyone over the age of 18 can propose to be a Steward for the Convergence Layer", Powers(payable(convergenceLayer))));
        mandateSlots.push(findMandateIdInOrg("Nominate for selection: any member can nominate to be selected for Steward role.", Powers(payable(convergenceLayer))));
        mandateSlots.push(findMandateIdInOrg("Select Stewards: Legal Interfacers can select Stewards from the pool of nominees.", Powers(payable(convergenceLayer))));

        // step 2: check permissions (ZKP and nominate are public; PeerSelect requires Legal Interfacer role).
        Powers(payable(convergenceLayer)).canCallMandate(msg.sender, mandateSlots[0]); // should return true (public mandate).
        Powers(payable(convergenceLayer)).canCallMandate(msg.sender, mandateSlots[1]); // should return true (public mandate).
        Powers(payable(convergenceLayer)).canCallMandate(msg.sender, mandateSlots[2]); // msg.sender must be a Legal Interfacer (role 3).

        // step 3a: pass ZKP age check at Convergence Layer (public, no voting).
        // NB: ZKPassport_Check requires an actual ZKP proof (age >= 18, issued within 90 days).
        // The proof bytes must be generated against zKPassport_Registry before broadcasting.
        bytes memory zkpCallData = abi.encode(true); // bool Nominate = true (context param stored alongside ZKP proof).
        vm.startBroadcast();
        IPowers(convergenceLayer).request(mandateSlots[0], zkpCallData, nonce, "Passing ZKP age check for Steward nomination");
        vm.stopBroadcast();

        // step 3b: nominate msg.sender for Steward selection (public, needFulfilled from step 3a).
        // The Nominate mandate records msg.sender as a candidate in the Nominees contract.
        vm.startBroadcast();
        IPowers(convergenceLayer).request(mandateSlots[1], abi.encode(), nonce, "Nominating for Steward selection");
        vm.stopBroadcast();

        // step 3c: Legal Interfacer proposes Steward selection via PeerSelect (requires voting: 51% majority, 80% quorum).
        // PeerSelect selects up to 3 nominees from the pool and assigns them the Steward role.
        // msg.sender must be a Legal Interfacer (role 3).
        bytes memory selectCallData = abi.encode(msg.sender);
        vm.startBroadcast();
        actionIds.push(IPowers(convergenceLayer).propose(mandateSlots[2], selectCallData, nonce, "Proposing Steward selection via PeerSelect"));
        vm.stopBroadcast();

        console2.log("PeerSelect proposed. Action ID: ", actionIds[0]);

        // step 3d: cast vote for PeerSelect (msg.sender as Legal Interfacer).
        // NB: In production all Legal Interfacers must vote; 80% quorum and 51% majority required.
        vm.startBroadcast();
        Powers(payable(convergenceLayer)).castVote(actionIds[0], 1); // = for
        vm.stopBroadcast();

        // step 3e: execute PeerSelect after voting period ends (5 minutes).
        // Assigns the Steward role (role 2) to selected nominees in the Nominees pool.
        vm.startBroadcast();
        IPowers(convergenceLayer).request(mandateSlots[2], selectCallData, nonce, "Executing Steward selection via PeerSelect");
        vm.stopBroadcast();
    }

    function getLegalInterfacerRole_ConvergenceLayer(address convergenceLayer, address primaryLayer, uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates in the 'Assign legal representative role' flow at Primary Layer.
        mandateSlots.push(findMandateIdInOrg("ZK-Passport Check Age: Anyone over the age of 18 can propose to be a legal representative for the Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("ZK-Passport Check Issuing Country: Anyone with a GBR passport can propose to be a legal representative for the Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Propose Legal Representative: Propose an address as legal representative for the Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Assign Legal Representative Role: Assign the legal representative role at the Convergence Layer to the proposed address", Powers(payable(primaryLayer))));

        // step 1b: look up the Assign Legal Interfacers mandate ID at the Convergence Layer.
        // ExternalAction_Flexible in step 4 uses this ID (stored in step 3's callData) to forward the call.
        mandateSlots.push(findMandateIdInOrg("Assign Legal Interfacers: Primary Layer can assign legal Interfacers, who have the power to adopt and revoke executive mandates.", Powers(payable(convergenceLayer))));
        uint16 assignRepsMandateId = mandateSlots[4];

        // step 2: check permissions (ZKP mandates are public; propose requires Ideas Layer role; assign requires Primary Steward role).
        Powers(payable(primaryLayer)).canCallMandate(msg.sender, mandateSlots[0]); // should return true (public mandate).
        Powers(payable(primaryLayer)).canCallMandate(msg.sender, mandateSlots[1]); // should return true (public mandate).
        Powers(payable(primaryLayer)).canCallMandate(msg.sender, mandateSlots[2]); // msg.sender must hold the Ideas Layer role (role 4).
        Powers(payable(primaryLayer)).canCallMandate(msg.sender, mandateSlots[3]); // msg.sender must be a Primary Steward (role 2).

        // step 3a: pass ZKP age check at Primary Layer (public, no voting).
        // NB: The ZKPassport_Check mandate appends the actual ZKP proof to the encoded context params.
        // The proof bytes must be generated externally (age >= 18, issued within 90 days) before broadcasting.
        bytes memory zkpCallData = abi.encode(convergenceLayer, assignRepsMandateId);
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[0], zkpCallData, nonce, "Passing ZKP age check for legal representative");
        vm.stopBroadcast();

        // step 3b: pass ZKP issuing-country check at Primary Layer (public, needFulfilled from step 3a).
        // Same context params; proof must confirm passport issuing country is GBR.
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[1], zkpCallData, nonce, "Passing ZKP country check for legal representative");
        vm.stopBroadcast();

        // step 3c: Ideas Layer proposes msg.sender as legal representative (needFulfilled from step 3b).
        bytes memory proposeCallData = abi.encode(convergenceLayer, assignRepsMandateId, msg.sender);
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[2], proposeCallData, nonce, "Proposing legal representative for Convergence Layer");
        vm.stopBroadcast();

        // step 3d: Primary Steward assigns the legal representative role (needFulfilled from step 3c).
        // ExternalAction_Flexible reads ConvergenceSubLayer + assignRepsMandateId from step 3c's stored callData
        // and calls the Convergence Layer, which in turn calls assignRole(3, msg.sender) on itself.
        bytes memory assignCallData = abi.encode(msg.sender);
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[3], assignCallData, nonce, "Assigning legal representative role at Convergence Layer");
        vm.stopBroadcast();
    }

}
