// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { IMandate } from "@lib/powers-monorepo/solidity/src/interfaces/IMandate.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol";

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment.

contract Initialise is ActionHelpers {
    uint16[] mandateSlots;
    uint256[] actionIds;

    uint256 roleCount;
    uint256 againstVote;
    uint256 forVote;
    uint256 abstainVote;

    function runSetupMandate(address powers, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run.
        mandateSlots.push(findMandateIdInOrg("Initial Setup: Assign role labels and revokes itself after execution", Powers(payable(powers))));

        // step 2: execute mandates. Initial Setup mandate is PUBLIC (allowedRole = type(uint256).max), so any key suffices.
        vm.startBroadcast(privateKeys[0]);
        IPowers(powers).request(mandateSlots[0], abi.encode(), nonce, "Executing initial setup mandate");
        vm.stopBroadcast();
    }

    function unpackReformPackages(address powers, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run by iterating all mandate slots and matching by name.
        uint16 counter = Powers(payable(powers)).mandateCounter();
        for (uint16 i = 1; i < counter; i++) {
            (address mandateAddr,,) = Powers(payable(powers)).getAdoptedMandate(i);
            string memory name = IMandate(mandateAddr).getNameDescription(powers, i);
            if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Reform Package ", vm.toString(i)))) {
                mandateSlots.push(i);
            }
        }
        
        console2.log("Unpacking reform packages for layer: ", Powers(payable(powers)).name());
        console2.log("Found ", mandateSlots.length, " reform packages to unpack.");
        console2.log("total number of mandates in the layer: ", Powers(payable(powers)).mandateCounter()); 

        // public mandates, so no need to check permissions.
        for (uint i = 0; i < mandateSlots.length; i++) {
            vm.startBroadcast();
            Powers(payable(powers)).request(mandateSlots[i], abi.encode(), nonce + i, "Unpacking reform package for Ideas Layer");
            vm.stopBroadcast();
        }
    }

    function deployIdeasLayer1(address primaryLayer, uint256 nonce, string[] memory names, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run.
        mandateSlots.push(findMandateIdInOrg("Initiate Ideas Layer: Initiate creation of Ideas Layer", Powers(payable(primaryLayer))));

        // step 3a: execute mandate: initiate ideas layer: propose
        // "Initiate Ideas Layer" requires role 1 (Participants).
        vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 1, 0, privateKeys));
        for (uint i = 0; i < names.length; i++) {
            actionIds.push(IPowers(primaryLayer).propose(mandateSlots[0], abi.encode(names[i]), nonce + i, string.concat("Initiating create ideas layer: ", names[i])));
        }
        vm.stopBroadcast();

        // voting on proposal (the voteOnProposal function does the broadcasting).
        for (uint i = 0; i < actionIds.length; i++) {
            (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
                primaryLayer,
                mandateSlots[0],
                actionIds[i],
                privateKeys,
                nonce + i, // randomiser
                100 // pass chance in percentage.
            );
            console2.log("Votes cast for initiating ideas layer proposal: ", names [i], ": ", forVote);
        }
    }

    function deployIdeasLayer2(address primaryLayer, uint256 nonce, string[] memory names, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run.
        mandateSlots.push(findMandateIdInOrg("Initiate Ideas Layer: Initiate creation of Ideas Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Create Ideas Layer: Execute Ideas Layer creation", Powers(payable(primaryLayer))));

        // executing proposal.
        for (uint i = 0; i < names.length; i++) {
            // "Initiate Ideas Layer" requires role 1 (Participants).
            vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 1, 0, privateKeys));
            IPowers(payable(primaryLayer)).request(mandateSlots[0], abi.encode(names[i]), nonce + i, string.concat("Executing create ideas layer"));
            vm.stopBroadcast();

            // step 3b: execute mandate: create ideas layer.
            // "Create Ideas Layer" requires role 2 (Stewards).
            vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 2, 0, privateKeys));
            actionIds.push(IPowers(primaryLayer).propose(mandateSlots[1], abi.encode(names[i]), nonce + i, string.concat("Creating ideas layer")));
            vm.stopBroadcast();

            // voting on proposal.
            (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
                primaryLayer,
                mandateSlots[1],
                actionIds[i],
                privateKeys,
                nonce + i, // randomiser
                100 // pass chance in percentage.
            );
            console2.log("Votes cast for creating ideas layer proposal: ", names [i], ": ", forVote);
        }
    }

    function deployIdeasLayer3(address primaryLayer, uint256 nonce, string[] memory names, uint256[] memory privateKeys) public returns (address[] memory deployedIdeasLayer) {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run.
        mandateSlots.push(findMandateIdInOrg("Create Ideas Layer: Execute Ideas Layer creation", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Assign role Id to layer: Assign role id 4 (Ideas Layer) to the new layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Register Ideas Layer to Paymaster: Register the new Ideas Layer to the paymaster as a sponsored target", Powers(payable(primaryLayer))));

        // executing proposal. All mandates require role 2 (Stewards).
        for (uint i = 0; i < names.length; i++) {
            vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 2, 0, privateKeys));
            IPowers(payable(primaryLayer)).request(mandateSlots[0], abi.encode(names[i]), nonce + i, string.concat("Executing create ideas layer"));
            vm.stopBroadcast();

            // step 3c: execute mandate: assign role ID to layer, and register at paymaster.
            vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 2, 0, privateKeys));
            IPowers(primaryLayer).request(mandateSlots[1], abi.encode(names[i]), nonce + i, string.concat("Assigning role ID for ideas layer"));
            IPowers(primaryLayer).request(mandateSlots[2], abi.encode(names[i]), nonce + i, string.concat("Registering ideas layer to paymaster"));
            vm.stopBroadcast();
        }

        deployedIdeasLayer = new address[](names.length);
        for (uint i = 0; i < names.length; i++) {
            deployedIdeasLayer[i] = Powers(payable(primaryLayer)).getRoleHolderAtIndex(4, i);
            console2.log("Deployed Ideas Layer: ", names[i], ": ", deployedIdeasLayer[i]);
            unpackReformPackages(deployedIdeasLayer[i], nonce, privateKeys); // unpack reform packages at the new ideas layer.
            runSetupMandate(deployedIdeasLayer[i], nonce, privateKeys); // run setup mandate at the new ideas layer.
        }

        console2.log("Deployed ", names.length, " Ideas Layers Successfully!");
        return deployedIdeasLayer;
    }

    function deployConvergenceLayer1(address ideasLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run.
        mandateSlots.push(findMandateIdInOrg("Request new Convergence Layer: Participants can initiate the request for creating a new Convergence Layer under the Primary Layer", Powers(payable(ideasLayer))));

        // step 2: propose "Request new Convergence Layer".
        // "Request new Convergence Layer" requires role 1 (Participants) and has a voting period.
        vm.startBroadcast(getPrivateKeyRoleHolder(ideasLayer, 1, 0, privateKeys));
        actionIds.push(IPowers(ideasLayer).propose(mandateSlots[0], abi.encode("London Venue", msg.sender), nonce, string.concat("Initiating request new convergence layer")));
        vm.stopBroadcast();

        // step 3: vote on proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            ideasLayer,
            mandateSlots[0],
            actionIds[0],
            privateKeys,
            nonce,
            100
        );

        console2.log("Votes cast for requesting convergence layer: ", forVote);
        console2.log("Votes cast against: ", againstVote);
        console2.log("Total voters: ", roleCount);
    }

    function deployConvergenceLayer2(address ideasLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run.
        mandateSlots.push(findMandateIdInOrg("Request new Convergence Layer: Participants can initiate the request for creating a new Convergence Layer under the Primary Layer", Powers(payable(ideasLayer))));
        mandateSlots.push(findMandateIdInOrg("Send request: Stewards can send the request to create a new Convergence Layer to the Primary Layer", Powers(payable(ideasLayer))));

        // step 2: execute the voted "Request new Convergence Layer" proposal.
        // "Request new Convergence Layer" requires role 1 (Participants).
        vm.startBroadcast(getPrivateKeyRoleHolder(ideasLayer, 1, 0, privateKeys));
        IPowers(ideasLayer).request(mandateSlots[0], abi.encode("London Venue", msg.sender), nonce, string.concat("Executing request new convergence layer"));
        vm.stopBroadcast();

        // step 3: propose "Send request" to Primary Layer.
        // "Send request" requires role 2 (Stewards) at the Ideas Layer and has a voting period.
        vm.startBroadcast(getPrivateKeyRoleHolder(ideasLayer, 2, 0, privateKeys));
        actionIds.push(IPowers(ideasLayer).propose(mandateSlots[1], abi.encode("London Venue", msg.sender), nonce, string.concat("Sending request for new convergence layer to primary layer")));
        vm.stopBroadcast();

        // step 4: vote on "Send request" proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            ideasLayer,
            mandateSlots[1],
            actionIds[0],
            privateKeys,
            nonce,
            100
        );

        // step 5: execute "Send request" → triggers creation of Convergence Layer at Primary Layer.
        vm.startBroadcast(getPrivateKeyRoleHolder(ideasLayer, 2, 0, privateKeys));
        IPowers(ideasLayer).request(mandateSlots[1], abi.encode("London Venue", msg.sender), nonce, string.concat("Executing send request for new convergence layer"));
        vm.stopBroadcast();

        console2.log("Votes cast for sending convergence layer request: ", forVote);
        console2.log("Votes cast against: ", againstVote);
        console2.log("Total voters: ", roleCount);
    }

    function deployConvergenceLayer3(address primaryLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run at the Primary Layer.
        mandateSlots.push(findMandateIdInOrg("Assign role Id: Assign role Id 3 to Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Assign Delegate status: Assign delegate status at Safe treasury to the Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Register Convergence Layer to Paymaster: Register the new Convergence Layer to the paymaster as a sponsored target, this means gas cost for interacting with the new Convergence Layer can be sponsored by the paymaster", Powers(payable(primaryLayer))));

        // step 2: at Primary Layer: assign role ID to convergence layer, assign it a delegate status at Safe & register at paymaster.
        // All mandates require role 2 (Stewards) at the Primary Layer.
        vm.startBroadcast(getPrivateKeyRoleHolder(primaryLayer, 2, 0, privateKeys));
        IPowers(primaryLayer).request(mandateSlots[0], abi.encode("London Venue", msg.sender), nonce, string.concat("Assigning role ID for convergence layer"));
        IPowers(primaryLayer).request(mandateSlots[1], abi.encode("London Venue", msg.sender), nonce, string.concat("Assigning delegate status for convergence layer"));
        IPowers(primaryLayer).request(mandateSlots[2], abi.encode("London Venue", msg.sender), nonce, string.concat("Registering convergence layer to paymaster"));
        vm.stopBroadcast();

        // unpack reform packages at the new convergence layer.
        address deployedConvergenceLayer = Powers(payable(primaryLayer)).getRoleHolderAtIndex(3, 0); // role 3 = Convergence Layers
        console2.log("Deployed Convergence Layer: ", deployedConvergenceLayer);
        unpackReformPackages(deployedConvergenceLayer, nonce, privateKeys);
        runSetupMandate(deployedConvergenceLayer, nonce, privateKeys);

        console2.log("Deployed Convergence Layer Successfully!");
    }
}
