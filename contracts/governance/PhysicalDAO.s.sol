// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { console2 } from "forge-std/console2.sol";
import { DeploySetup } from "./PrimaryDAO.s.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ZKPassportHelper } from "@lib/circuits/src/solidity/src/ZKPassportHelper.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

contract PhysicalDAO is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    PowersFactory powersFactory;

    uint16 public assignRepsMandateId;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() external { 
        // Deploy factories first (empty) so their addresses are available
        console2.log("Deploying Physical sub-DAO factory (contract only)...");
        vm.startBroadcast();
        PowersDeployer physicalDaoDeployer = new PowersDeployer();  // £todo: I think this can be deployed as a singleton contract
        powersFactory = new PowersFactory(
            "Physical sub-DAO", // name
            string.concat(baseURI, "physicalSubDao.json"), // uri
            helperConfig.getMaxCallDataLength(block.chainid), // max call data length
            helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
            helperConfig.getMaxExecutionsLength(block.chainid), // max executions length 
            address(physicalDaoDeployer)
        );
        vm.stopBroadcast(); 
        console2.log("Physical sub-DAO factory deployed at:", address(powersFactory));
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address primaryDAO,
        address governed721,
        address activityToken,
        address nominees,
        uint16 mintPoapTokenId
    ) public {
        _createConstitution(primaryDAO, governed721, activityToken, nominees, mintPoapTokenId);
        
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
        address governed721,
        address activityToken,
        address nominees,
        uint16 mintPoapTokenId
    ) internal {
        mandateCount = 4; // resetting mandate count. 
        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////

        // setup role labels // 
        calldatas = new bytes[](10);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Admin", string.concat(baseURI, "admin.json"));  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", string.concat(baseURI, "public.json")); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Attendee", string.concat(baseURI, "attendee.json"));
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Convener", string.concat(baseURI, "convener.json")); 
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Legal Representative", string.concat(baseURI, "legalRep.json"));
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary DAO", string.concat(baseURI, "primaryDao_role.json"));
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, address(primaryDAO)); 
        calldatas[9] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use. 

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
        // £NB: Minting and setting the URI no all managed externally from this DAO. 
        // The artist has to assign the sub-DAO as approved to transfer artworks. 
  
        // CONVENERS FORCE SELL NFT ART WORK //
        uint16[] memory mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Sell NFT artwork: This flow allows conveners to sell NFT art works, automatically transferring the NFT and distributing payments.",
            mandateIds: mandateIds
        }));

        // NOTE: Owners of art works can always decide to sell art work on their own account. Income of sell will be distributed in both cases. 
        inputParams = new string[](4); 
        inputParams[0] = "address oldOwner";
        inputParams[1] = "address newOwner";
        inputParams[2] = "uint256 TokenId";
        inputParams[3] = "bytes Data"; // encoded PaymentToken + quantity + nonce. 
        // Note that technically the Physical sub-DAO can pay for sale if the buyer paid the Sub-DAO directly. It would result in the sub-DAO owning the NFT, while buyer has the physical artwork. 

        // NB: this will only work if the physical sub-DAO has been approved by the artist to transfer the art work NFTs. This is to ensure that artists have control over which art works can be sold through the sub-DAO.
        mandateCount++;
        conditions.allowedRole = 2; // Conveners. 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Sell NFT artwork: conveners can sell NFT art works, which will automatically transfer from the owner of the NFT to the buyer and distribute payments according to splits set by the governed721DAO.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    governed721,
                    Governed721.safeTransferFrom.selector,
                    inputParams
                ),
                conditions: conditions
            })
        ); 
        delete conditions;

        // PAYMENT OF RECEIPTS //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Payment of Receipts: This flow allows Conveners to submit and approve payment of receipts.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Conveners: Submit & approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Conveners can propose and vote on receipts.   
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 67;
        conditions.quorum = 50; 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit & Approve payment of receipt: Execute a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        // MINT POAPS FOR ATTENDEES //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Mint POAPs for Attendees: This flow allows Conveners to mint POAPs for event attendees.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address To";

        // Conveners: Mint POAPs for attendees
        // Note: for now this is managed through a bespoke Soulbound1155 contract. 
        // Before a physical event is organised, this should be implemented through either POAP.xyz, or IYK protocols.    
        mandateCount++;
        conditions.allowedRole = 1; // = Conveners
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Mint POAP: Any Convener can mint a POAP.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode(
                    address(primaryDAO),
                    mintPoapTokenId, // parent mandate id (the mint POAP token at primary DAO mandate)
                    "Requesting minting of POAP from Primary DAO",
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // MINT & DISTRIBUTE 'MERIT' NFTS TO ATTENDEES THROUGH VOTING ON CONTRIBUTIONS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Mint 'Merit' NFTs: This flow allows Conveners to propose and Attendees to vote on minting 'Merit' NFTs for attendees.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address Attendee"; // attendee being considered

        // Convener: proposes minting of 'Merit' NFTs to attendees based on their contributions (e.g. participation in events, volunteering, etc.).
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Propose minting 'Merit' NFTs for attendees: Conveners can propose minting 'Merit' NFTs to recognize attendees' contributions.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams), // input params can include details about the proposal, such as the criteria for awarding 'Merit' NFTs and the attendees being considered.
                conditions: conditions
            })
        );
        delete conditions;

        ///////////////////////////////////////// IMPORTANT NOTE /////////////////////////////////////////
        // NB, TODO: The problem of deploying bespoke merit tokens should be solved through a single 1155 token contract. Encoding the address where they are minted. 
        ///////////////////////////////////////// IMPORTANT NOTE /////////////////////////////////////////
        
        // Attendees: vote on the proposal to mint 'Merit' NFTs. If the proposal passes, the specified attendees receive their 'Merit' NFTs as recognition for their contributions.
        mandateCount++;
        conditions.allowedRole = 1; // = Attendees
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold to ensure active participation in the voting process.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Vote on 'Merit' NFT proposals: Attendees can vote on proposals to mint 'Merit' NFTs. If a proposal passes, the specified attendees receive their 'Merit' NFTs.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    createPlaceholderAddress("Dependency0"), // the actvityToken contract where 'Merit' NFTs are minted
                    bytes4(keccak256("mint(address,uint256)")), // Soulbound1155.mint.selector, // function selector to call
                    abi.encode(), // params before (role id 1 = Attendees) // the static params
                    inputParams, // the dynamic params (== address to)
                    abi.encode(block.number, address(0)) // We simply mint the id of the block number of the mint, the address input is that of artist, here not used.  
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // The following to mandates I still have to think through. Don't know if they are a good idea. 
        // I do think the Artist one is a nice example of voting on range fo actions. A common use case and not implemented yet. 
        // MINT & DISTRIBUTE 'MERIT' NFTS TO ARTIST THROUGH VOTING ON ART WORKS //
        // £TODO - implement? 

        // £todo Still need some type of payment for conveners. - not solved yet. 

        // REDEEM MERIT NFTS FOR REWARD  //
        // inputParams = new string[](1);
        // inputParams[0] = "address PayableTo"; // the address of the participant redeeming the 'Merit' NFT

        // mandateCount++;
        // conditions.allowedRole = type(uint256).max; // = anyone
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Redeem 'Merit' NFTs for a rewards: Anyone with a 'Merit' NFT can redeem for a reward.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "GovernedToken_BurnToAccess"),
        //         config: abi.encode(
        //             inputParams,
        //             createPlaceholderAddress("Dependency0") // the actvityToken contract where 'Merit' NFTs are minted
        //             ), // input params can include details about the redemption process, such as the rewards available and the criteria for redeeming 'Merit' NFTs.
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // // public: claim preset payment. 
        // // Note that this can be changed / update by adopting new mandate. 
        // mandateCount++;
        // conditions.allowedRole = type(uint256).max;
        // conditions.needFulfilled = mandateCount - 1; // need the previous redeem 'Merit' NFTs for rewards mandate to be fulfilled.  
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Claim payment: Anyone can claim a preset payment for redeeming 'Merit' NFTs.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_PresetTransfer"),
        //         config: abi.encode(
        //             deployMandates.getInitialisedAddress("Erc20Taxed"), 
        //             1 * 10 ** 18, // amount to be paid out for redeeming 'Merit' NFTs. For example, 100 tokens with 18 decimals.
        //             helperConfig.getSafeAllowanceModule(block.chainid), 
        //             treasury
        //             ),
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

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
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_RecoverTokens"), // maybe functionality has to change slightly: have token to be transferred as input param. 
                config: abi.encode(
                    treasury, 
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // CLAIM ATTENDEE ROLE //   
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Claim Attendee Role: This flow allows anyone to become a member if they have sufficient activity tokens.",
            mandateIds: mandateIds
        }));

        // I think this will work. Still needs to be tested though. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO 1 tokens during the last 15 days.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "GovernedToken_GatedAccess"),
                config: abi.encode(
                    activityToken, // soulbound token contract
                    1, // attendee role Id
                    0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself).
                    1, // number of tokens required. Only one POAP needed for membership.
                    daysToBlocks(15, helperConfig.getBlocksPerHour(block.chainid)) // look back period in blocks = 15 days.
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // SELECT CONVENERS //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Select Conveners: This flow allows for the nomination, selection, and peer election of conveners.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "bool Nominate"; 

        // anybody: do ZKP check: age >= 18 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal representative for the Physical sub-DAO.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Age: Anyone over the age of 18 can propose to be a convener for the Physical sub-DAO",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.
                    false, // facematch not required (for now) 
                    ZKPassportHelper.isAgeAboveOrEqual.selector,  
                    abi.encode(18) // the input for the zkp check (age > 18) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // Anyone: Nominate for selection to be convener.
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        conditions.needFulfilled = mandateCount - 1; // need the previous ZKP check mandate to be fulfilled to nominate for convener selection.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for selection: any member can nominate to be selected for convener role.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Nominate"),
                config: abi.encode(
                    nominees, // election list contract
                    true // nominate as candidate
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // legal reps: force revoke nomination.
        mandateCount++;
        inputParams = new string[](1);
        inputParams[0] = "address Nominee"; // the address of the nominee whose nomination is to be revoked.

        conditions.allowedRole = 3; // = legal representatives.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: Legal Representatives can revoke nominations for convener elections.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    nominees, // election list contract
                    Nominees.revokeNomination.selector,
                    abi.encode(), // params before
                    inputParams,
                    abi.encode(false) // params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Legal Representatives: adopt peer select mandate to select conveners from the pool of nominees. 
        PowersTypes.MandateInitData[] memory initData = new PowersTypes.MandateInitData[](1);
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 80; // = 80% quorum
        initData[0] = PowersTypes.MandateInitData({
                nameDescription: "Select Conveners: Legal Representatives can select conveners from the pool of nominees.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PeerSelect"),
                config: abi.encode(
                    3, // numberToSelect
                    2, // RoleId for Conveners
                    nominees // election list contract // 
                ),
                conditions: conditions
            });
        delete conditions;

        // mandateCount++;
        // conditions.allowedRole = 3; // = legal representatives.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Adopt Peer Select Mandate: Legal Representatives can adopt the Peer Select mandate to select conveners from the pool of nominees.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Preset_Mandates"),
        //         config: abi.encode(
        //             initData // the peer select mandate init data. 
        //         ),
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // ASSIGN LEGAL REPS //
        mandateIds = new uint16[](1);
        mandateIds[0] = mandateCount + 1;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Legal Representatives: This flow allows the Primary DAO to assign legal representatives.",
            mandateIds: mandateIds
        }));

        // Primary DAO: assign Legal Representative. 
        mandateCount++;
        inputParams = new string[](2);
        inputParams[0] = "address Representative"; 
        conditions.allowedRole = 6; // = Primary DAO.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Legal Representatives: Primary DAO can assign legal representatives, who have the power to adopt and revoke executive mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(0), // target is its own powers contract
                    IPowers.assignRole.selector,
                    abi.encode(3), // roleId of Legal Representative role
                    inputParams,
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;
        assignRepsMandateId = mandateCount;
        // These should be assigned directly by Primary DAO. 
        // -- should have a specific related governance flow to select these. + ZKP check.  
        

        // //////////////////////////////////////////////////////////////////////
        // //                        REFORM MANDATES                           //
        // //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATES //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Members, adopted by Conveners, and subject to veto by the Primary DAO.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // PrimaryDAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 6; // PrimaryDAO = role 6. 
        conditions.needFulfilled = mandateCount - 1;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: PrimaryDAO can veto proposals to adopt new mandates", 
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 2;
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

        // LEGAL REPS ADOPT & REVOKE EXECUTIVE MANDATES //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Executive Mandates Management: This flow allows Legal Representatives to adopt or revoke executive mandates, effectively controlling the DAO's functional state.",
            mandateIds: mandateIds
        }));

        // (Effectively giving power to pause functioning of the sub-DAO). 
        // Mandates to be adopted / revoked: (£todo: for now this is a placeholder, need to decide which Mandates to place here!).  
        /** 
        The following mandates: 
        - Sell NFT artwork
        - Submit & approve payment of receipt
        - Mint POAP for attendees
        - Vote on 'Merit' NFT proposals 
        - Update URI
        */ 

        initData = new PowersTypes.MandateInitData[](1);
        initData[0] = PowersTypes.MandateInitData({ 
            nameDescription: "Deploy actvityToken Merit token: This mandate sets up a sub-DAO specific actvityToken token to be used for merit badges and other internal uses. The mandate self-destructs after execution.",
            targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PresetActions"),
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }); 

        // // Legal Reps: Adopt Executive Mandates
        // mandateCount++; 
        // conditions.allowedRole = 3; // This is a legal representative mandate. Only legal reps can call it.
        // conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        // conditions.succeedAt = 66; // 66% majority needed to pass the mandate
        // conditions.quorum = 80; // 80% quorum needed to pass the mandate
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Adopt Executive Mandates: The Legal Representatives adopt executive mandates, enabling the physical DAO to function.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Preset_Mandates"),
        //         config: abi.encode(initData), // The mandates that will be adopted. 
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // Legal Reps: Revoke Executive Mandates
        // mandateCount++;
        // conditions.allowedRole = 3; // This is a legal representative mandate. Only legal reps
        // conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        // conditions.succeedAt = 66; // 66% majority needed to pass the mandate
        // conditions.quorum = 80; // 80% quorum needed to pass the mandate
        // conditions.needFulfilled = mandateCount - 1; // need the previous mandate to have been fulfilled for this revoke mandate to be valid.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Revoke Executive Mandates: The Legal Representatives can revoke executive mandates, effectively pausing the physical DAO.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Revoke_Mandates_Prepackaged"),
        //         config: abi.encode(), // The mandates that will be revoked. 
        //         conditions: conditions
        //     })
        // );
        // delete conditions;
    }
}
