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

import { Soulbound1155 } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ElectionList } from "@lib/powers-monorepo/solidity/src/helpers/ElectionList.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

import { Helpers } from "./Helpers.s.sol";
import { PrimaryDAO } from "./PrimaryDAO.s.sol";
import { DigitalDAO } from "./DigitalDAO.s.sol";
import { IdeasDAO } from "./IdeasDAO.s.sol";
import { PhysicalDAO } from "./PhysicalDAO.s.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.
contract Deploy is Script {
    PrimaryDAO primaryDAO;
    DigitalDAO digitalSubDAO;
    IdeasDAO ideasSubDaoFactory;
    PhysicalDAO physicalSubDaoFactory;
    Helpers helpers; 
    
    function run() external { 
        // step 0, setup. 
        primaryDAO = new PrimaryDAO();
        digitalSubDAO = new DigitalDAO();
        ideasSubDaoFactory = new IdeasDAO();
        physicalSubDaoFactory = new PhysicalDAO();
        helpers = new Helpers();

        // deploying the core Powers and Powers factory instances: 
        primaryDAO.run();
        digitalSubDAO.run();
        ideasSubDaoFactory.run();
        physicalSubDaoFactory.run();
        helpers.run();

        // constituting the powers instances and powers factories. 
        primaryDAO.constitutePowers(
            digitalSubDAO.getAddress(),
            ideasSubDaoFactory.getAddress(),
            physicalSubDaoFactory.getAddress(),
            helpers.getActivityToken(),
            helpers.getElectionList()
        );
        digitalSubDAO.constitutePowers(
            primaryDAO.getAddress(),
            helpers.getActivityToken(),
            primaryDAO.requestAllowanceDigitalDAOId()
        );
        ideasSubDaoFactory.constitutePowers(
            primaryDAO.getAddress(),
            helpers.getElectionList(),
            primaryDAO.getTreasury()
        );
        physicalSubDaoFactory.constitutePowers(
            primaryDAO.getAddress(),
            helpers.getGoverned721(),
            helpers.getActivityToken(),
            helpers.getNominees(),
            primaryDAO.mintPoapTokenId()
        );

        // step 5: transfer ownership of factories to primary DAO.
        vm.startBroadcast();
        console2.log("Transferring ownership of DAO factories to Primary DAO...");
        Soulbound1155(helpers.getActivityToken()).transferOwnership(address(primaryDAO));
        Soulbound1155(helpers.getMeritBadges()).transferOwnership(address(primaryDAO)); 
        Governed721(helpers.getGoverned721()).transferOwnership(address(primaryDAO));
        Nominees(helpers.getNominees()).transferOwnership(address(primaryDAO));
        vm.stopBroadcast();

        console2.log("Success! All contracts successfully deployed, unpacked and configured.");
    }
}
