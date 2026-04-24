// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";
import { Safe } from "@lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "@lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { ZKPassportHelper } from "@lib/circuits/src/solidity/src/ZKPassportHelper.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { Soulbound1155, Soulbound1155Factory } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { ElectionList } from "@lib/powers-monorepo/solidity/src/helpers/ElectionList.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { SafeProxyFactory } from "@lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";

contract PrimaryDAO is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    Powers powers; 

    uint16 public requestNewPhysicalDaoId;
    uint16 public requestAllowancePhysicalDAOId;
    uint16 public requestAllowanceDigitalDAOId;
    uint16 public mintPoapTokenId;
    uint16 public requestMembershippowersId;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public {
        console2.log("Deploying Primary DAO...");
        vm.startBroadcast();
            powers = new Powers(
                "Primary DAO", // name
                string.concat(baseURI, "powers.json"), // uri
                helperConfig.getMaxCallDataLength(block.chainid), // max call data length
                helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
                helperConfig.getMaxExecutionsLength(block.chainid) // max executions length
            );
        vm.stopBroadcast();

        // setup Safe treasury.
        address[] memory owners = new address[](1);
        owners[0] = address(powers);

        vm.startBroadcast();
        treasury = address(
            SafeProxyFactory(helperConfig.getSafeProxyFactory(block.chainid))
                .createProxyWithNonce(
                    helperConfig.getSafeL2Canonical(block.chainid),
                    abi.encodeWithSelector(
                        Safe.setup.selector,
                        owners,
                        1, // threshold
                        address(0), // to
                        "", // data
                        address(0), // fallbackHandler
                        address(0), // paymentToken
                        0, // payment
                        address(0) // paymentReceiver
                    ),
                    1 // = nonce
                )
        );
        vm.stopBroadcast();
        console2.log("Safe treasury deployed at:", treasury);
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address digitalSubDAO, 
        address ideasDaoFactory, 
        address physicalDaoFactory, 
        address activityToken,
        address electionList
        ) public { // add here dependencies. 
        _createConstitution(digitalSubDAO, ideasDaoFactory, physicalDaoFactory, activityToken, electionList);
         
        for (uint256 i = 0; i < constitution.length; i += PACKAGE_SIZE) {
            uint256 packageLength = constitution.length - i < PACKAGE_SIZE ? constitution.length - i : PACKAGE_SIZE;
            PowersTypes.MandateInitData[] memory constitutionPart = new PowersTypes.MandateInitData[](packageLength);
            for (uint256 j = 0; j < constitutionPart.length; j++) {
                constitutionPart[j] = constitution[i + j];
            }
            vm.startBroadcast();
            powers.constitute(constitutionPart);
            vm.stopBroadcast();
        } 
        vm.startBroadcast();
        powers.closeConstitute(msg.sender, flows); // set msg.sender as admin);
        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powers);
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address digitalSubDAO, 
        address ideasDaoFactory, 
        address physicalDaoFactory, 
        address activityToken,
        address electionList
        ) internal {
        mandateCount = 0;
        
        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        // setup calls //
        // signature for Safe module enabling call
        bytes memory signature = abi.encodePacked(
            uint256(uint160(address(powers))), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        targets = new address[](16);
        values = new uint256[](16);
        calldatas = new bytes[](16);

        for (uint256 i = 0; i < 16; i++) {
            targets[i] = address(powers); // all calls have value 0 in this mandate. To transfer Eth, use a different mandate.
        }
        targets[13] = treasury; // override target for treasury setup call.
        targets[14] = treasury; // override target for allowance module setup call.

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Admin", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members", "");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Executives", "");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Physical sub-DAOs", "");
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas sub-DAOs", "");
        calldatas[6] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital sub-DAOs", "");
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount1);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount2);
        // calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount3);
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, digitalSubDAO);
        calldatas[12] = abi.encodeWithSelector(IPowers.setTreasury.selector, treasury);
        calldatas[13] = abi.encodeWithSelector( // cal to set allowance module to the Safe treasury.
            Safe.execTransaction.selector,
            treasury, // The internal transaction's destination
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module.
                ModuleManager.enableModule.selector,
                helperConfig.getSafeAllowanceModule(block.chainid)
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[14] = abi.encodeWithSelector( // call to set Digital sub-DAO as delegate to the Safe treasury.
            Safe.execTransaction.selector,
            helperConfig.getSafeAllowanceModule(block.chainid), // The internal transaction's destination: the Allowance Module.
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSignature(
                "addDelegate(address)", // == AllowanceModule.addDelegate.selector,  (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                digitalSubDAO
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[15] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assigns role labels, sets up the allowance module, the treasury and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PresetActions"),
                config: abi.encode(
                    targets,
                    values,
                    calldatas
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////
        // CREATE IDEAS DAO //
        uint16[] memory mandateIds = new uint16[](5);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3; 
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;

        flows.push(PowersTypes.Flow({
            nameDescription: "Create an Ideas sub-DAO: This flow includes the initiation and execution of the Ideas sub-DAO creation, as well as the assigning of the role id to the new sub-DAO. This flow can be triggered by any executive.",
            mandateIds: mandateIds
        }));

        // Members: Initiate Ideas sub-DAO creation
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Ideas sub-DAO: Initiate creation of Ideas sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Execute Ideas sub-DAO creation
        mandateCount++;  
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create Ideas sub-DAO: Execute Ideas sub-DAO creation",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(ideasDaoFactory), // calling the ideas factory
                    bytes4(keccak256("createPowers()")),
                    abi.encode()  
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Assign role Id to Ideas sub-DAO //
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign role Id to DAO: Assign role id 4 (Ideas sub-DAO) to the new DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(4), // params before (role id 4 = Ideas sub-DAOs)
                    abi.encode(), // dynamic params (the input params of the parent mandate)
                    mandateCount - 1, // parent mandate id (the create Ideas sub-DAO mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE IDEAS DAO //
        inputParams = new string[](1);
        inputParams[0] = "address IdeasSubDAO";

        // Members: Veto Revoke Ideas sub-DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto revoke Ideas sub-DAO: Veto the revoking of an Ideas sub-DAO from Cultural Stewards",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(
                    inputParams
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Ideas sub-DAO (revoke role Id) //
        mandateCount++;
        conditions.allowedRole = 2;
        conditions.quorum = 66;
        conditions.succeedAt = 51;
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke role Id: Revoke role id 4 (Ideas sub-DAO) from the DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(4), // params before (role id 4 = Ideas sub-DAOs) // the static params
                    abi.encode(), // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // CREATE PHYSICAL DAO // 
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Create a Physical sub-DAO: This flow includes the initiation and execution of the Physical sub-DAO creation, as well as the assigning of the role id to the new sub-DAO and the assigning of delegate status to the new sub-DAO for the Safe treasury. This flow can only be triggered by an Ideas sub-DAO.",
            mandateIds: mandateIds
        }));

        // note: an allowance is set when DAO is created.
        inputParams = new string[](1); 
        inputParams[0] = "address Admin"; // the address of the admin of the new DAO

        // Ideas sub-DAOs: Initiate Physical sub-DAO creation. Any Ideas sub-DAO can propose creating a Physical sub-DAO.
        mandateCount++;
        conditions.allowedRole = 4; // = Ideas sub-DAO
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Physical sub-DAO: Initiate creation of Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;
        requestNewPhysicalDaoId = mandateCount; // needed for call from ideas sub-DAO

        // Executive: deploy a soulbound1155 instance by calling the factory
        // using bespokeAction_advance to be able to keep the admin field as input.  
        // mandateCount++;
        // conditions.allowedRole = 2; // = Any executive 
        // conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Deploy Merit Badge Contract: Deploy a Soulbound1155 contract to be used as merit badges for the Physical sub-DAO",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
        //         config: abi.encode(
        //             registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Soulbound1155Factory"), 
        //             Soulbound1155Factory.createSoulbound1155.selector,
        //             abi.encode("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi"), 
        //             inputParams, // these dynamic params will be ignored by the factory, but are needed to link the mandate to its chain. 
        //             abi.encode() 
        //         ),
        //         conditions: conditions
        //     })
        // ); 

        // Executive update the dependencies of the create Physical sub-DAO mandate to include the newly deployed Soulbound1155 as a dependency, so that it can be used in the config of the execute Physical sub-DAO creation mandate.
        // mandateCount++;
        // conditions.allowedRole = 2; // = Any executive
        // conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled. 
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Add dependency: Add the deployed Soulbound1155 as a dependency to the create Physical sub-DAO mandate",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
        //         config: abi.encode(
        //             address(physicalDaoFactory), // target contract
        //             PowersFactory.addDependency.selector,
        //             abi.encode(), 
        //             inputParams, // these dynamic params will be ignored by the factory, but are needed to link the mandate to its chain. 
        //             mandateCount - 1, // the return value of the deployment needs to be added as dependency.
        //             abi.encode() 
        //         ),
        //         conditions: conditions
        //     })
        // ); 

        // Executives: Execute Physical sub-DAO creation
        mandateCount++; 
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create Physical sub-DAO: Execute Physical sub-DAO creation",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(physicalDaoFactory), // calling the Physical factory 
                    bytes4(keccak256("createPowers(address)")), // function selector for createPowers (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    inputParams // address as input param 
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Assign role Id to Physical sub-DAO //
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign role Id: Assign role Id 3 to Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(uint16(3)), // params before (role id 4 = Ideas sub-DAOs)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 1, // parent mandate id (the create Ideas sub-DAO mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Assign Delegate status to Physical sub-DAO //
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 2; // need the Physical sub-DAO to have been created.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Delegate status: Assign delegate status at Safe treasury to the Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_ExecTransaction_OnReturnValue"),
                config: abi.encode(
                    helperConfig.getSafeAllowanceModule(block.chainid), // target contract
                    bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    abi.encode(), // params before (role id 4 = Ideas sub-DAOs)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the create Physical sub-DAO mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ASSIGN LEGAL REPRESENTATIVE ROLE TO PHYSICAL SUB-DAO //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign legal representative role to Physical sub-DAO: This flow includes the proposal and assigning of the legal representative role for the Physical sub-DAO. To propose a legal representative, an address needs to pass two ZKP checks (age and issuing country of passport) and be proposed by an Ideas sub-DAO. The legal representative can then be assigned by any executive. This flow can be triggered by any Ideas sub-DAO, but requires the execution of mandates by the executives, so effectively the executives have the final say.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](2);
        inputParams[0] = "address PhysicalSubDAO"; // the address of the Physical sub-DAO for which the legal representative is being proposed. This is needed to link the mandate to the correct chain, and to be able to reference the DAO in the next mandate.
        inputParams[1] = "uint16 assignRepMandateId"; // the mandate id of the next mandate (assigning the legal representative role) to link the mandates together.
    
        // anybody: do ZKP check: age > 18 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal representative for the Physical sub-DAO.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Age: Anyone over the age of 18 can propose to be a legal representative for the Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.  
                    false, // no facematch needed for now 
                    ZKPassportHelper.isAgeAboveOrEqual.selector,  
                    abi.encode(18) // the input for the zkp check (age > 18) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // anybody: do ZKP check: Issuing country passport check: GBR
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal representative for the Physical sub-DAO.
        conditions.needFulfilled = mandateCount - 1; // need the age check to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Issuing Country: Anyone with a GBR passport can propose to be a legal representative for the Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.  
                    false, // no facematch needed for now
                    ZKPassportHelper.isIssuingCountryIn.selector,
                    abi.encode(["GBR"]) // the input for the zkp check (issuing country = GBR) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;
        
        // Ideas SubDAO: select one of the people that passed the ZKP check. Note that this can be any of Ideas sub-DAOs
        inputParams = new string[](3);
        inputParams[0] = "address PhysicalSubDAO"; // the address of the Physical sub-DAO for which the legal representative is being proposed. This is needed to link the mandate to the correct chain, and to be able to reference the DAO in the next mandate.
        inputParams[1] = "uint16 assignRepMandateId"; // the mandate id of the next mandate (assigning the legal representative role) to link the mandates together.
        inputParams[2] = "address ProposedLegalRep"; // the address proposed as legal
        
        mandateCount++;
        conditions.allowedRole = 4; // = Proposed by a Ideas sub-DAO. can propose a legal representative for the Physical sub-DAO.
        conditions.needFulfilled = mandateCount - 1; // need both ZKP checks to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Propose Legal Representative: Propose an address as legal representative for the Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // executives: assign legal rep role at physical sub-DAO. 
        inputParams = new string[](1);
        inputParams[0] = "address ProposedLegalRep"; // the address proposed as legal

        mandateCount++;
        conditions.allowedRole = 2; // = Executives. Any executive can assign the legal representative role for the Physical sub-DAO.
        conditions.needFulfilled = mandateCount - 1; // need the proposal of the legal representative to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Legal Representative Role: Assign the legal representative role at the Physical sub-DAO to the proposed address",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Flexible"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE PHYSICAL DAO //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Physical sub-DAO: This flow includes the vetoing and revoking of a Physical sub-DAO. The revoking is done by revoking the role id of the Physical sub-DAO, and revoking the delegate status at the Safe treasury. This flow can be triggered by any executive, but the veto can only be triggered by members.",
            mandateIds: mandateIds
        }));

        // members veto revoking physical DAO
        inputParams = new string[](2);
        inputParams[0] = "address PhysicalSubDAO";
        inputParams[1] = "bool removeAllowance";

        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto revoke Physical sub-DAO: Veto the revoking of an Physical sub-DAO from Cultural Stewards",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Physical sub-DAO (Revoke Role ID) //
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Role Id: Revoke role Id 3 from Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Physical sub-DAOs) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Physical sub-DAO (Revoke Delegate status DAO) //
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.needFulfilled = mandateCount - 1; // need the assign role to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Delegate status: Revoke delegate status Physical sub-DAO at the Safe treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_ExecTransaction"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xdd43a79f), // == AllowanceModule.removeDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly
                    helperConfig.getSafeAllowanceModule(block.chainid) // target contract
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ASSIGN ADDITIONAL ALLOWANCE TO PHYSICAL DAO //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: " Assign additional allowance to a physical sub-DAO: This flow includes the proposal, veto and execution of assigning an additional allowance. Any sub-DAO can propose to assign an additional allowance to either sub-DAO, but only the executives can execute it, and only the members can veto it.",
            mandateIds: mandateIds
        }));

        // Setting input params for allowance mandates
        inputParams = new string[](5);
        inputParams[0] = "address Sub-DAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        // Physical sub-DAO: Veto additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Physical sub-DAOs
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto allowance: Veto setting an allowance to a Physical sub-DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Physical sub-DAO: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Physical sub-DAOs.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request additional allowance: Any Physical sub-DAO can request an allowance from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;
        requestAllowancePhysicalDAOId = mandateCount; // store the mandate id for Digital sub-DAO allowance veto.

        // Executives: Grant Allowance to Physical sub-DAO
        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Set Allowance: Execute and set allowance for a Physical sub-DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Action"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    helperConfig.getSafeAllowanceModule(block.chainid)
                ),
                conditions: conditions // everythign zero == Only admin can call directly
            })
        );
        delete conditions;

        // ASSIGN ADDITIONAL ALLOWANCE TO DIGITAL DAO //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign additional allowance to a Digital sub-DAO: This flow includes the proposal, veto and execution of assigning an additional allowance. Any sub-DAO can propose to assign an additional allowance to either sub-DAO, but only the executives can execute it, and only the members can veto it.",
            mandateIds: mandateIds
        }));

        // Physical sub-DAO: Veto additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Physical sub-DAOs
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto allowance: Veto setting an allowance to the digital sub-DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Digital sub-DAO: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 5; // = Digital sub-DAO.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request additional allowance: The Digital sub-DAO can request an allowance from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;
        requestAllowanceDigitalDAOId = mandateCount; // store the mandate id for Physical sub-DAO allowance veto.

        // Executives: Grant Allowance to Digital sub-DAO
        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Set Allowance: Execute and set allowance for the Digital sub-DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Action"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    helperConfig.getSafeAllowanceModule(block.chainid)
                ),
                conditions: conditions // everythign zero == Only admin can call directly
            })
        );
        delete conditions;

        // UPDATE URI //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Update Primary DAO URI: This flow includes the veto and execution of updating the Primary DAO URI. Only members can veto, but any executive can execute the update.",
            mandateIds: mandateIds
        }));


        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Members: Veto update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto update URI: Members can veto updating the Primary DAO URI",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Cultural Stewards DAOs",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(powers), // calling the allowed tokens contract
                    IPowers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // MISCELLANEOUS //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Miscellaneous powers: This flow includes various powers that do not fit in the other categories, such as minting tokens and recovering tokens sent to the DAO by mistake.",
            mandateIds: mandateIds
        }));

        // EXECUTE VETO ON MANDATE ADOPTION AT OTHER SUB-DAOs //
        inputParams = new string[](2);
        inputParams[0] = "uint16[] MandateId";
        inputParams[1] = "uint256[] roleIds";

        // Executioners: Veto call to Powers instance and mandateIds in other sub-DAOs
        mandateCount++;
        conditions.allowedRole = 2; // = executioners
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Call to sub-Dao: Executioners can veto updating the Primary DAO URI",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Flexible"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // MINT NFTs FOR PHYSICAL SUB-DAO // 
        mandateCount++;
        conditions.allowedRole = 3; // = Physical sub-DAOs
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Mint token Physical sub-DAO: Any Physical sub-DAO can mint new NFTs",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "GovernedToken_MintEncodedToken"),
                config: abi.encode(address(activityToken)),
                conditions: conditions
            })
        );
        delete conditions;
        mintPoapTokenId = mandateCount; // store the mandate id for minting POAP tokens.

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Executives. Any executive can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Primary DAO can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_RecoverTokens"),
                config: abi.encode(
                    treasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;



        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // CLAIM MEMBER PRIMARY DAO // -- on the basis of request at ideas DAO and POAP ownership.
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2; 

        flows.push(PowersTypes.Flow({
            nameDescription: "Claim Member Primary DAO: This flow includes the claiming of membership in the Primary DAO based on a request from an Ideas sub-DAO and the ownership of POAP tokens from the Physical sub-DAO. Any member of an Ideas sub-DAO can trigger this flow, but it requires the ownership of at least 2 POAP tokens from the Physical sub-DAO that are not older than 6 months, so effectively only active members of the Physical sub-DAO can claim membership in the Primary DAO.",
            mandateIds: mandateIds
        }));

        // Ideas DAO: request membership - statement of intent.
        inputParams = new string[](1);
        inputParams[0] = "uint256[] TokenIds";

        mandateCount++;
        conditions.allowedRole = 4; // = ideas sub-DAO
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Membership Step 1: A forwarded quest to become member from an ideas-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode( inputParams ),
                conditions: conditions
            })
        );
        delete conditions;
        requestMembershippowersId = mandateCount;

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Membership Step 2: 2 POAPS from physical DAO are needed that are not older than 6 months.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "GovernedToken_GatedAccess"),
                config: abi.encode(
                    address(activityToken), // soulbound token contract
                    1, // member role Id
                    3, // checks if token is from address that is an Physical sub-DAO
                    daysToBlocks(180, helperConfig.getBlocksPerHour(block.chainid)), // look back period in blocks = 30 days.
                    2 // number of tokens required
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE MEMBERSHIP //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2; 

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Membership: This flow includes the revoking of membership in the Primary DAO based on a request from an Ideas sub-DAO and the ownership of POAP tokens from the Physical sub-DAO. Any member of an Ideas sub-DAO can trigger this flow, but it requires the ownership of at least 2 POAP tokens from the Physical sub-DAO that are not older than 6 months, so effectively only active members of the Physical sub-DAO can revoke membership in the Primary DAO.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address MemberAddress";

        // Members: veto Revoke Membership
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Membership: Members can veto revoking membership from other members.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Membership
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Membership: Executives can revoke membership from members.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Members) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ELECT EXECUTIVES //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4; 

        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Executives: This flow includes the creation of an executive election, opening the vote, tallying the results and cleaning up after the election. Any member can trigger this flow, but it requires multiple steps that need to be executed by different roles, so effectively it requires the coordination of both members and executives to successfully elect new executives.",
            mandateIds: mandateIds
        }));

        // set inputparams for election mandates
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members 
        conditions.throttleExecution = minutesToBlocks(7, helperConfig.getBlocksPerHour(block.chainid)); // = once every 7 minutes
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create an Executive election: an election for the executive role can be initiated be any member.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    electionList, // election list contract
                    ElectionList.createElection.selector, // selector
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Create election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Executive election: Members can open the vote for an executive election. This will create a dedicated vote mandate.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_CreateVoteMandate"),
                config: abi.encode(
                    electionList, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Vote"), // the vote mandate address
                    1, // the max number of votes a voter can cast
                    1 // the role Id allowed to vote (Members)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Tally Executive elections: After an executive election has finished, assign the Executive role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Tally"),
                config: abi.encode(
                    electionList,
                    2, // RoleId for Executives
                    5 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Executive election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Executive election: After an executive election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeMandate.selector, // function selector to call
                    abi.encode(), // params before
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the open vote  mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // VOTE OF NO CONFIDENCE // 
        mandateIds = new uint16[](5);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4; 
        mandateIds[4] = mandateCount + 5;

        flows.push(PowersTypes.Flow({
            nameDescription: "Vote of No Confidence: This flow includes the creation of a vote of no confidence mandate that can be triggered by any member against the executives, and if successful, the revoking of all executive roles. This flow is designed to ensure that the executives remain accountable to the members and can be removed if they are not fulfilling their duties satisfactorily.",
            mandateIds: mandateIds
        }));

        // very similar to elect executives, but no throttle, higher threshold and ALL executives get role revoked the moment the first mandate passes.
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: Vote of No Confidence 
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 77; // high majority
        conditions.quorum = 60; // = high quorum 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Vote of No Confidence: Revoke Executive statuses.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "RevokeAccountsRoleId"),
                config: abi.encode(
                    2, // roleId
                    inputParams // the input params to fill out.
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members 
        conditions.needFulfilled = mandateCount - 1; // = previous Vote of No Confidence mandate. Note: NO throttle on this one.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create an Executive election: an election for the executive role can be initiated be any member.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    electionList, // election list contract
                    ElectionList.createElection.selector, // selector
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Create election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Executive election: Members can open the vote for an executive election. This will create a dedicated vote mandate.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_CreateVoteMandate"),
                config: abi.encode(
                    electionList, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Vote"), // the vote mandate address
                    1, // the max number of votes a voter can cast
                    1 // the role Id allowed to vote (Members)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Tally Executive elections: After an executive election has finished, assign the Executive role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Tally"),
                config: abi.encode(
                    electionList,
                    2, // RoleId for Executives
                    5 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Executive election: After an executive election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeMandate.selector, // function selector to call
                    abi.encode(), // params before
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the open vote  mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Nominate for Executive election: Any member can nominate themselves or other members for the executive election, and can also revoke their nomination. This flow includes the nomination and revoking of nomination for the executive election.",
            mandateIds: mandateIds
        }));

        // Members: Nominate for Executive election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for election: any member can nominate for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Nominate"),
                config: abi.encode(
                    electionList, // election list contract
                    true // nominate as candidate
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members revoke nomination for Executive election.
        mandateCount++;
        conditions.allowedRole = 1; // = Members 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: any member can revoke their nomination for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Nominate"),
                config: abi.encode(
                    electionList, // election list contract
                    false // revoke nomination
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                        REFORM MANDATES                           //
        //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATE //
        mandateIds = new uint16[](9);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;
        mandateIds[6] = mandateCount + 7;
        mandateIds[7] = mandateCount + 8;
        mandateIds[8] = mandateCount + 9;

        flows.push(PowersTypes.Flow({
            nameDescription: " Adopt Mandate: This flow includes the proposal, veto and execution of adopting a new mandate into the constitution. Any sub-DAO can propose to adopt a new mandate into the constitution, but only the executives can execute it, and the members and all sub-DAOs have veto power over it.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // executives: Propose Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        // Note: voting time is longer than the voting time for the 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate mandate adoption: Any executive can propose adopting new mandates into the organization.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        uint16 initiateReformId = mandateCount; // Store the ID of the initiate mandate

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoMembersId = mandateCount;

        // Digital sub-DAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 5; // Digital sub-DAO
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Digital sub-DAO can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoDigitalId = mandateCount;

        // Ideas sub-DAOs: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 4; // Ideas sub-DAO
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Ideas sub-DAO can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoIdeasId = mandateCount;

        // Physical sub-DAOs: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // Physical sub-DAO
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Physical sub-DAO can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoPhysicalId = mandateCount;

        // Checkpoint 1: Executives confirm Members Veto passed (or timed out without veto)
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        conditions.needFulfilled = initiateReformId;
        conditions.needNotFulfilled = vetoMembersId;
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // Match voting period
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 1: Executives confirm Members did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint1Id = mandateCount;

        // Checkpoint 2: Executives confirm Digital Veto passed
        mandateCount++;  
        conditions.allowedRole = 2; // Executives
        conditions.needFulfilled = checkpoint1Id;
        conditions.needNotFulfilled = vetoDigitalId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 2: Executives confirm Digital sub-DAO did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint2Id = mandateCount;

        // Checkpoint 3: Executives confirm Ideas Veto passed
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        conditions.needFulfilled = checkpoint2Id;
        conditions.needNotFulfilled = vetoIdeasId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 3: Executives confirm Ideas sub-DAO did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint3Id = mandateCount;

        // Executives: Adopt Mandates (Final Step)
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); 
        conditions.timelock = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // timelock after voting before execution to give organisations the time to veto.
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        conditions.needFulfilled = checkpoint3Id;
        conditions.needNotFulfilled = vetoPhysicalId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Executives can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;
    }
}
