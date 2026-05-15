// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol";

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment. 

contract Management is ActionHelpers {
    uint16[] mandateSlots; 
    uint256[] actionIds; 

    uint256 roleCount; 
    uint256 againstVote; 
    uint256 forVote; 
    uint256 abstainVote;

    ////////////////////////////////////////////////////////////////////////////
    //                        PRIMARY LAYER INTERACTIONS                      // 
    ////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////
    //                        DIGITAL LAYER INTERACTIONS                      // 
    //////////////////////////////////////////////////////////////////////////// 
    function digitalLayerTransferTokensToPrimary(address powers, uint256 nonce) public { 

    }     

    function digitalLayerRequestAdditionalAllowance(address powers, uint256 nonce) public { 

    }

    function digitalLayerPaymentOfReceipt(address powers, uint256 nonce) public { 

    }

    ////////////////////////////////////////////////////////////////////////////
    //                    CONVERGENCE LAYER INTERACTIONS                      // 
    ////////////////////////////////////////////////////////////////////////////        
    function sellNft(address powers, uint256 nonce) public {
   
    }
    

    function convergenceLayerTransferTokensToPrimary(address powers, uint256 nonce) public { 

    }

    function convergenceLayerRequestAdditionalAllowance(address powers, uint256 nonce) public { 

    }


    function convergencePaymentThroughDigitalLayer(address powers, uint256 nonce) public { 

    }

    function convergenceLayerPaymentOfReceipt(address powers, uint256 nonce) public { 

    }


}
