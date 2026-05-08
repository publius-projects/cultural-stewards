// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { SafeProxyFactory } from "@lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "@lib/safe-smart-account/contracts/Safe.sol";

import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";

import { Soulbound1155 } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";
import { PowersPaymaster } from "@lib/powers-monorepo/solidity/src/helpers/PowersPaymaster.sol";

import { Helpers } from "./Helpers.s.sol";
import { InitialiseOrganisation } from "./actions/InitialiseOrganisation.s.sol";
import { PrimaryLayer } from "./PrimaryLayer.s.sol";
import { DigitalLayer } from "./DigitalLayer.s.sol";
import { IdeasLayer } from "./IdeasLayer.s.sol";
import { ConvergenceLayer } from "./ConvergenceLayer.s.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.
contract Deploy is Script {
    PrimaryLayer primaryLayer;
    DigitalLayer digitalLayer;
    IdeasLayer ideasLayerFactory;
    ConvergenceLayer convergenceLayerFactory;
    Helpers helpers; 
    InitialiseOrganisation initialise;

    string[] public ideasLayerNames = ["Seeing", "Making", "Listening", "Telling", "Remembering", "Imagining", "Tending"];
    
    function run() external { 
        // step 1, setup. 
        primaryLayer = new PrimaryLayer();
        digitalLayer = new DigitalLayer();
        ideasLayerFactory = new IdeasLayer();
        convergenceLayerFactory = new ConvergenceLayer();
        helpers = new Helpers();
        initialise = new InitialiseOrganisation();

        uint256[] memory privateKeys = new uint256[](3);
        privateKeys[0] = vm.envUint("TEST_ACCOUNT_KEY_1");
        privateKeys[1] = vm.envUint("TEST_ACCOUNT_KEY_2");
        privateKeys[2] = vm.envUint("TEST_ACCOUNT_KEY_3");

        // step 2, deploying the core Powers and Powers factory instances: 
        primaryLayer.run();
        digitalLayer.run();
        ideasLayerFactory.run();
        convergenceLayerFactory.run();
        helpers.run();

        // step 3, constituting the powers instances and powers factories. 
        primaryLayer.constitutePowers(
            digitalLayer.getAddress(),
            ideasLayerFactory.getAddress(),
            convergenceLayerFactory.getAddress(),
            helpers.getActivityToken(),
            helpers.getElectionRegistry(),
            digitalLayer.getAssignConvergenceLayer()
        );
        digitalLayer.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getElectionRegistry(),
            primaryLayer.requestAllowanceDigitalLayerId()
        );
        ideasLayerFactory.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getElectionRegistry(),
            primaryLayer.getTreasury(),
            primaryLayer.requestParticipantpowersId(),
            primaryLayer.requestNewConvergenceLayerId()
        );
        convergenceLayerFactory.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getGoverned721(),
            helpers.getActivityToken(),
            helpers.getNominees(),
            primaryLayer.mintPoapTokenId(),
            primaryLayer.requestAllowanceConvergenceLayerId()

        );

        // step 4: transfer ownership of factories to Primary Layer.
        vm.startBroadcast();
        console2.log("Transferring ownership of Organisational factories to Primary Layer...");
        Soulbound1155(helpers.getActivityToken()).transferOwnership(primaryLayer.getAddress());
        Governed721(helpers.getGoverned721()).transferOwnership(primaryLayer.getAddress());
        Nominees(helpers.getNominees()).transferOwnership(primaryLayer.getAddress());
        vm.stopBroadcast();

        // SETUP // 
        
        // step 5a: run setup on primary and digital layer.
        initialise.runSetupMandate(primaryLayer.getAddress(), block.timestamp);
        initialise.runSetupMandate(digitalLayer.getAddress(), block.timestamp);

        // step 5b: create multiple ideas layers for different domains of the organisation + unpack reform packages in these layers.
        for (uint i = 0; i < ideasLayerNames.length; i++) {
            initialise.deployIdeasLayer(primaryLayer.getAddress(), block.timestamp + i, privateKeys);
            address ideasLayer = Powers(payable(primaryLayer.getAddress())).getRoleHolderAtIndex(4, i);
            initialise.unpackReformPackages(ideasLayer, block.timestamp + i);
        }

        // step 5d: create a convergence layer + unpack reform package in this layer. 
        // retrieve ideas layer address.. 
        address ideasLayerAddress = Powers(payable(primaryLayer.getAddress())).getRoleHolderAtIndex(4, 0);
        initialise.deployConvergenceLayer(ideasLayerAddress, primaryLayer.getAddress(), block.timestamp + 100, privateKeys);
        address convergenceLayer = Powers(payable(primaryLayer.getAddress())).getRoleHolderAtIndex(3, 0);
        initialise.unpackReformPackages(convergenceLayer, block.timestamp + 100);

        console2.log("Success! All contracts successfully deployed, unpacked and configured.");
    }
}
