// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { console2 } from "forge-std/console2.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ElectionList } from "@lib/powers-monorepo/solidity/src/helpers/ElectionList.sol";
import { ZKPassportHelper } from "@lib/circuits/src/solidity/src/ZKPassportHelper.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

contract IdeasDAO is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    PowersFactory powersFactory;

    uint16 public requestMembershipPrimaryDaoId;
    uint16 public requestNewPhysicalDaoId;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public { 
        console2.log("Deploying Ideas Sub-DAO factory (contract only)...");
        vm.startBroadcast();
        PowersDeployer ideasDaoDeployer = new PowersDeployer();
        powersFactory = new PowersFactory(
            "Ideas sub-DAO", // name
            string.concat(baseURI, "ideasSubDao.json"),
            helperConfig.getMaxCallDataLength(block.chainid), // max call data length
            helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
            helperConfig.getMaxExecutionsLength(block.chainid), // max executions length
            address(ideasDaoDeployer)
        );
        vm.stopBroadcast();
        console2.log("Ideas sub-DAO factory deployed at:", address(powersFactory));
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address primaryDAO,
        address electionList, 
        address safeTreasury
    ) public {
        _createConstitution(primaryDAO, electionList, safeTreasury);
        
        PowersTypes.MandateInitData[] memory constitutionPacked = packageInitData(constitution, PACKAGE_SIZE, 1);
        vm.startBroadcast();
        powersFactory.addMandates(constitutionPacked);
        powersFactory.addFlows(flows);
        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powersFactory);
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address primaryDAO,
        address electionList,
        address safeTreasury
    ) internal {
        mandateCount = 0; // resetting mandate count.

        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        // setup role labels // 
        calldatas = new bytes[](11);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Admin", string.concat(baseURI, "admin.json"));  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", string.concat(baseURI, "public.json")); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members", string.concat(baseURI, "members.json"));
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners", string.concat(baseURI, "conveners.json")); 
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Moderators", string.concat(baseURI, "moderators.json"));  
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary DAO", string.concat(baseURI, "primaryDao_role.json"));
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, cedars);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, primaryDAO); 
        calldatas[10] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PresetActions_OnOwnPowers"),
                config: abi.encode(calldatas),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // REQUEST CREATION NEW PHYSICAL DAO //
        uint16[] memory mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request new Physical sub-DAO: This flow includes the initiation by Members, veto by Moderators, and execution by Conveners to request the creation of a new Physical sub-DAO.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1); // no input params, as all params are set in the config of the mandate.
        inputParams[0] = "address Admin"; // the only input param is the new URI for the physical sub-DAO, which will be used by conveners when requesting the creation of a new physical sub-DAO.

        // Members: Initialise request for new physical sub-DAO.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.quorum = 5; // low quorum. Many members might not be very active.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request new Physical sub-DAO: Members can initiate the request for creating a new Physical sub-DAO under the Primary DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions; 

        // Moderators: Veto request for new physical sub-DAO
        mandateCount++;
        conditions.allowedRole = 3; // = Moderators
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled (Members need to have initiated the request for a new physical sub-DAO).
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto request for new Physical sub-DAO: Moderators can veto the request for creating a new Physical sub-DAO under the Primary DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Conveners: request at Primary DAO the creation of a new physical DAO.
        // Note: this is a statement of intent. Physical DAOs are requested using a working group, after initated here by conveners.
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.quorum = 51; // simple majority
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 10 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.needFulfilled = mandateCount - 2; // need the Members to have initiated the request for a new physical sub-DAO.
        conditions.needNotFulfilled = mandateCount - 1; // need the Moderators to NOT have vetoed the request for a new physical sub-DAO.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request new Physical sub-DAO: Conveners can create a new Physical sub-DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode( 
                    primaryDAO,
                    requestNewPhysicalDaoId, // parent mandate id (the create new physical sub-DAO at primary DAO mandate)
                    "Requesting creation of new Physical sub-DAO from Primary DAO", // description
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;
        // uint16 requestNewPhysicalDaoWorkingGroupMandateId = mandateCount;

        // MISCELLANEOUS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Miscellaneous powers: This flow includes updating the URI and recovering tokens sent to the DAO by mistake.",
            mandateIds: mandateIds
        }));

        // UPDATE URI //
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Conveners: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(0), // target address is its own powers contract
                    Powers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any convener can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_RecoverTokens"),
                config: abi.encode(
                    safeTreasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // ASSIGN MEMBERSHIP //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Membership: This flow allows users to apply for and claim member roles based on forum participation.",
            mandateIds: mandateIds
        }));

        // public: apply for membership
        inputParams = new string[](2);
        inputParams[0] = "address ApplicantAddress";
        inputParams[1] = "string ApplicationURI";

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = Public
        conditions.throttleExecution = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // to avoid spamming, the mandate is throttled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Apply for Membership: Anyone can apply for membership to the DAO by submitting an application.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // moderators: assess and assign membership
        mandateCount++;
        conditions.allowedRole = 3; // = Moderators
        conditions.needFulfilled = mandateCount - 1; // need the application to have been submitted.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assess and Assign Membership: Moderators can assess applications and assign membership to applicants.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0),
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Members) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate) -- NB: not that any excess data at the END OF CALLDATA is ignored. hence we can add the uri - it will not be taken into consideration. 
                    abi.encode() // no args after
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
            nameDescription: "Revoke Membership: This flow allows members to veto and moderators to revoke membership.",
            mandateIds: mandateIds
        }));

        // Moderators can revoke membership following bad behaviour on forum etc.
        // Members: veto Revoke Membership
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the revoke membership mandate to have been fulfilled for the veto to be valid.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Membership: Members can veto revoking membership from other members.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Moderators: Revoke Membership
        // Note: even though the inputParams also have the URI included (which is not needed for revoking membership), we keep the same inputParams for both the assign and revoke mandate, as the excess params will simply be ignored.
        mandateCount++;
        conditions.allowedRole = 3; // = Moderators
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        conditions.needFulfilled = mandateCount - 2; // need the revoke membership mandate to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Membership: Moderators can revoke membership from members.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Members) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REQUEST MEMBERSHIP OF PRIMARY DAO //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request Membership of Primary DAO: This flow allows members to apply for membership in the Primary DAO and moderators to approve and forward the request.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "uint256[] TokenIds";

        // Members: apply for membership of primary DAO. 
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Apply for Membership of Primary DAO: Members can apply for membership of the Primary DAO by submitting a request with their POAPs.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // moderators: ok and send request to primary DAO. 
        mandateCount++;
        conditions.allowedRole = 3; // = Moderators
        conditions.needFulfilled = mandateCount - 1; // need the application to have been submitted.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.quorum = 10; // low quorum.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Membership of Primary DAO: Moderators can ok requests for membership of the Primary DAO and send them to the Primary DAO for assessment.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode( 
                    primaryDAO,
                    requestMembershipPrimaryDaoId, // parent mandate id (the request membership of primary DAO mandate)
                    "Requesting membership of Primary DAO", // description
                    inputParams
                ),
                conditions: conditions
            })
        ); 
        delete conditions;

        // ASSIGN MODERATORS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Moderator Role: This flow allows members to veto and conveners to assign the Moderator role.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address Account";
        
        // members: veto assigning moderator role.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 70; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Assign Moderator Role: Members can veto assigning the Moderator role to an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // conveners: assign moderator role.
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 30; // = relatively low threshold.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Moderator Role: Conveners can assign the Moderator role to an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Moderators) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE MODERATORS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Moderator Role: This flow allows members to veto and conveners to revoke the Moderator role.",
            mandateIds: mandateIds
        }));

        // members: veto revoking moderator role.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 70; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // The moderator needs to have been assigned in the first place..
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Moderator Role: Members can veto revoking the Moderator role from an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // conveners: revoke moderator role.
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 30; // = relatively low threshold.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        conditions.needFulfilled = mandateCount - 2; // The moderator role needs to have been assigned.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Moderator Role: Conveners can revoke the Moderator role from an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Moderators) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ELECT CONVENERS //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Conveners: This flow includes the creation, voting, tallying, and cleanup of an election for Conveners.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, helperConfig.getBlocksPerHour(block.chainid)); // = once every 2 hours
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Convener election: an election for the convener role can be initiated be any member.",
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

        // Members: Open Vote for Convener election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Create Convener election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Convener election: Members can open the vote for a convener election. This will create a dedicated vote mandate.",
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
                nameDescription: "Tally Convener elections: After a convener election has finished, assign the Convener role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Tally"),
                config: abi.encode(
                    electionList,
                    2, // RoleId for Conveners
                    3 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: clean up Convener election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Convener election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Convener election: After a convener election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_CleanUpVoteMandate"),
                config: abi.encode(mandateCount - 2), // The create vote mandate)
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
            nameDescription: "Vote of No Confidence: This flow allows members to call a vote of no confidence to revoke Convener statuses and hold a new election.",
            mandateIds: mandateIds
        }));

        // very similar to elect conveners, but no throttle, higher threshold and ALL executives get role revoked the moment the first mandate passes.
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
                nameDescription: "Vote of No Confidence: Revoke Convener statuses.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "RevokeAccountsRoleId"),
                config: abi.encode(
                    2, // roleId
                    inputParams // the input params to fill out.
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: create Convener election
        mandateCount++;
        conditions.allowedRole = 1; // = Members (should be Convener according to MD, but code says Members)
        conditions.needFulfilled = mandateCount - 1; // = previous Vote of No Confidence mandate. Note: NO throttle on this one.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Convener election: an election for the convener role can be initiated be any member.",
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
                nameDescription: "Open voting for Convener election: Members can open the vote for a convener election. This will create a dedicated vote mandate.",
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
                nameDescription: "Tally Convener elections: After a convener election has finished, assign the Convener role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionList_Tally"),
                config: abi.encode(
                    electionList,
                    2, // RoleId for Conveners
                    5 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Members: clean up Convener election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Convener election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Convener election: After a convener election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
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

        // NOMINATE FOR ELECTION //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Nominate for Election: This flow allows members to nominate themselves or revoke their nomination for an election.",
            mandateIds: mandateIds
        }));

        // Members: Nominate for Executive election
        mandateCount++;
        conditions.allowedRole = 1; // = Members (should be Conveners according to MD, but code says Members)
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
        conditions.allowedRole = 1; // = Members (should be Conveners according to MD, but code says Members) 
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

        // ADOPT MANDATES //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Conveners and subject to veto by Members.",
            mandateIds: mandateIds
        }));

        // Adopt mandate //
        inputParams = new string[](2);
        inputParams[0] = "address[] mandates";
        inputParams[1] = "uint256[] roleIds";

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;
    }
}
