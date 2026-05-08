// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol";

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment. 

contract AcquireRoles is ActionHelpers {
    uint16[] mandateSlots; 
    uint256[] actionIds; 

    uint256 roleCount; 
    uint256 againstVote; 
    uint256 forVote; 
    uint256 abstainVote;

    function getAllRolesPrimaryLayer(address powers, uint256 nonce) public {
   
    }

    function getAllDigitalIdeasLayer(address powers, uint256 nonce) public { 

    }

    function getAllRolesIdeasLayer(address powers, uint256 nonce) public { 

    }

    function getAllRolesConvergenceLayer(address powers, uint256 nonce) public { 

    }
}
