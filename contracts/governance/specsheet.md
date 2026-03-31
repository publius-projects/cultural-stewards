# **Experiment: Cultural Stewardship \- Specification**

| WARNING: This project is under development. The organisational specs and deployment addresses are subject to change. This document serves as an initial specification based on the ecosystem architecture. |
| :---- |

## **Context**

### ***The Vision & Mission:***

The experiment's multi-layered DAO ecosystem is designed to foster an interplay between ideational concepts, physical spaces, and digital manifestations. Its primary aim is to act as a steward for cultural endeavours through a "Layered Approach", ensuring a clear separation between different planning activities while facilitating their interactions as different departments within the organisation. 

It aims to teach digital literacy skills and openly **facilitate a continuous conversation around blockchain governance experiments in the cultural sector.** It exists to make DAO tools more easily accessible, by translating complex technological processes into understandable concepts; and hopes to foster meaningful contributions by creating a circular community ecosystem that brings tangible assets to its Participants. More goals include:

* **ONBOARDING:** To be a guide for Participants who are venturing into decentralised governance for the first time. 
* **LEARNING:** To teach Participants about the ecosystem and how it functions.  
* **DISCOVERING:** To allow Participants to jump across various different clusters in the ecosystem, transparently seeing what others have built within the ecosystem.  
* **VOTING:** To give Participants the decision-making power inside the ecosystem, whether they vote on large-scale DAO-wide effects or small-scale local sub-DAO effects.  
* **BUILDING:** To supply Participants with Powers Protocols templates to re-use for building their own structures, thus creating a wide fractal pattern of DAOs and sub-DAOs across an interoperable ecosystem.  
* **PARTICIPATING:** The more the Participants thrive inside the ecosystem, the more successful the ecosystem will be, the more resources the ecosystem has to build with.  
* **VISITING:** Anyone can experience the ecosystem and watch it evolve as an outside visitor. There is no pressure to participate in decision making processes. Alternatively, those interested can visit a physical pop-up event to discover more about the digital layers and meet other Participants IRL. 

***What this could look like, in a practical sense:***   
**www.enterhere.io is the the main checkpoint** where individuals, organisations, or brands with distinct communities (interested in cultural topics such as arts, intangible heritage, exhibitions, publications, media, music, books, magazines, and more...) who are open to involve their communities in the decentralised decision making process can go to discover more about how to get involved. It is the main point of contact to begin exploring the ecosystem. Inside the checkpoint there are onboarding and educational resources, bulletins and live updates from the ecosystem, and a 'DOOR' page with a link to the forum. 

The forum component is a dApp (decentralised app) which is fully maintained by the Participants themselves. There, they can go to vote on decisions within the DAO concerning everything from maintaining the platform itself..to what cultural initivies the DAO wants to begin that will manifest into physical events. 

User experience on this forum looks like interactive elements taken from **game theory**, such as earning internal currency (called Merits), progressing by going to further checkpoints (whether digital or physical) to earn participation badges (called POAPs), working in teams, and exploring other user-created UX/UI built on its open-source infrastructure. Other elements are taken from **social media**, making it a platform where Participants have their own customisable profile. The forum's structure is comprised of side-by-side voting panel layouts that include a chat forum where each step of the decision-making (we call this a governance flow) is discussed in a chat amongst Participants -- even having a ‘timeline’ to scroll through to get a birds eye view of events happening within the ecosystem. This is all to foster active participation. Participants who are active as they interact within the ecosystem, and those who vote on mandates to guide the decision-making process are the ones who become the cultural stewards. 

**Through the digital component www.enterhere.io, which is remotely accessible, the physical components are manifested.** The experiment's governance architecture is setup to have the functionality for physical spaces to spawn from ideas. These physical spaces will be central to the objective; real-life blank walls of a room can be decorated to present the current topic being explored, where Participants can walk into and interact with the digital layers via endless possibilities of physical components in the space. One example of what this could look like, is perhaps a sort of 'reward dispenser' where a Participant can scan a QR-code and are airdropped a POAP token from the ecosystem, which may grant special access or permissions to participate further in the project. The aim is to have these **IRL ‘checkpoints** work in tandem with the digital checkpoint www.enterhere.io -- a physical space that represents the work being done in the digital realm which could manifest itself into the real-world. The possibilities for IRL formats to showcase cultural endeavours is very open, they could be (but are not limitied to) exhibitions, discussons, presentations, workshops, symposiums, and more.

## **Definitions**

* **PrimaryDAO**: The central governance hub (`Powers.sol`) that holds the treasury, mints tokens, and orchestrates the creation of sub-DAOs.
* **DigitalDAO**: A unique sub-DAO (`Powers.sol`) responsible for the digital infrastructure, code repositories, and online interfaces.
* **IdeasDAO**: A type of sub-DAO (`PowersFactory` instance) focused on ideation, incubation of new concepts, and proposing new PhysicalDAOs. Multiple instances can exist.
* **PhysicalDAO**: A type of sub-DAO (`PowersFactory` instance) that manages real-world assets, events, and physical spaces. Multiple instances can exist.
* **Executives**: Elected leaders of the PrimaryDAO who execute high-level decisions and manage the treasury.
* **Conveners**: Elected operational leaders within sub-DAOs (Digital, Ideas, Physical) who manage day-to-day activities.
* **Moderators**: Appointed roles within IdeasDAOs responsible for managing membership and community standards.
* **Repository Admins**: Elected as admins of the DAO repository, managed in the DigitalDAO. 
* **Legal Representatives**: Individuals assigned to PhysicalDAOs to handle off-chain legal responsibilities and act as a bridge between The Cultural Stewards Experiment and real-world legal frameworks.
* **Members**: Participants with voting rights in their respective DAOs.
* **Attendee**: Participants who voting rights inside temporary physical spaces.
* **Split Ratio**: A governance-defined percentage (e.g., 20/20/60) determining the division of funds between the Artist, Local Safe and the PrimaryDAO Treasury. 
* **Treasury (Safe)**: A centralized Safe smart wallet controlled by the PrimaryDAO, holding the organization's financial assets. sub-DAOs operate via allowances (Safe Allowance Module) rather than holding their own funds.


## **Assets and Tokens**

The ecosystem utilises a combination of standard and soulbound tokens to manage governance, reputation, and access. These tokens are controlled by the Cultrual Stewards DAO's PrimaryDAO, but minting rights can also be mandated to sub-DAOs (e.g., PhysicalDAOs minting POAPs). Some tokens are used for gating access to roles (e.g., becoming a Member or Attendee).

The ecosystem utilises the following tokens: 

* **Merit Token (`Soulbound1155`)**: Specific tokens used within Physical sub-DAOs to recognise and reward contributions. They are specifically handed out by an 'Engagement Officer' role. These tokens can be redeemed for financial rewards, this works by burning the token which triggers a smart contract to release a small share of funds to the Participant's wallet.

* **Election Token (`Soulbound1155`)**: This token is assigned by Moderators through subjective assessment, given to Participants to recognise and reward contributions in the IdeasDAO forums. These tokens cannot be exchanged for financial rewards, but can be used to gain access to other types of roles e.g. an IdeasDAO Convenor role or PrimaryDAO Member role.  

* **Achievement Badge (`Soulbound1155`)**: This token is given to Participants when they are successfully elected into a role which requires an election. This not only signifies an achivement, but also ensures that Participants cannot be elected again over the limit, e.g. An IdeasDAO Convenor can only hold this role for 2 terms.

* **Attendance Badge (`POAP`)**: Given to participants for showing up to physical spaces organised via the PhysicalDAO. Cannot be exchanged for financial rewards, but can be used to request membership into the PrimaryDAO.

* **Real World Assets (`Governed721`)**: An externally governed token that can be used to link an NFT (such as an ERC20) through its metadata to an real world cultural artifact, and manages distribution of income at the point of Sale. It does not use the ERC-3643 RWA Tokenization standard at the moment, but this can be integrated at a later date. 

[comment]: <> (in this section I have added the new tokens and updated the descriptions, they will need to be later added into the protocol and written into the mandate tables below) 
 
## **Structure**

***The Architecture of Primary & sub-DAOs:***  
The organisation operates through a federated structure comprising a **PrimaryDAO** and three distinct types of **sub-DAOs**:

1. **PrimaryDAO**: The central authority and root of the ecosystem.
    *   **Role**: Governance of the Treasury, creation/deactivation of sub-DAOs, and high-level dispute resolution.
    *   **Treasury**: Controls the central Safe.
    *   **Governance**: Elected Executives, with checks and balances from Members.
2. **DigitalDAO (sub-DAO)** (Type 1): A singleton entity.
    *   **Role**: Manages the digital realm—code, UI, and online presence.
    *   **Treasury**: Has an allowance from the PrimaryDAO's Safe.
    *   **Governance**: Elected Conveners, subject to Member oversight and PrimaryDAO veto.
3. **IdeasDAO (sub-DAO)** (Type 2): Multiple instances possible (Factory-deployed).
    *   **Role**: Incubator for new initiatives. It is the birthplace of PhysicalDAOs.
    *   **Treasury**: Does *not* typically hold an allowance. Operates on social capital and ideas.
    *   **Governance**: Moderators (appointed) and Conveners (elected). Highly autonomous, with minimal interference from the PrimaryDAO.
4. **PhysicalDAO (sub-DAO)** (Type 3): Multiple instances possible (Factory-deployed).
    *   **Role**: Manages physical assets (spaces, events). Initiated by an IdeasDAO but operates independently once created.
    *   **Treasury**: Has an allowance from the PrimaryDAO's Safe.
    *   **Governance**: Conveners (selected via peer review/voting) and Legal Representatives (assigned for compliance).

### ***Treasury Management:***

* **Centralised Treasury**: The PrimaryDAO’s Safe acts as the single source of truth for funds.
* **Allowance Module**: The PrimaryDAO uses a Safe Allowance Module to delegate spending power.
    *   **DigitalDAO & PhysicalDAO (sub-DAOs)**: Assigned spending limits (allowances) rather than direct funds.
    *   **Request Flow**: sub-DAOs propose budgets/expenses. If approved (via internal sub-DAO vote and PrimaryDAO executive execution), the allowance is updated or a transfer is executed.

* **Recovery**: The PrimaryDAO retains the ultimate power to recover funds or revoke allowances in case of emergencies or disputes.

### ***Deployed Mandates:*** 

Below are the details for the deployed mandates for each DAO. The section summarises the mission of the DAO, the assets it controls and the actions it can take. Subsequently, it outlines the roles the mandates have, and gives outline the executive, electoral, and reform mandates. Executive mandates execute a specific action. Electoral mandates assign accounts to roles. Reform mandates manage the adoption and/or revoking of mandates.

## PrimaryDAO

### ***Mission***

The central governance body holding the Safe Treasury, where the DAO’s assets are stored on-chain.  

### ***Assets*** 

The PrimaryDAO controls the following assets: 

* It is the owner of the treasury (a Safe smart wallet with an allowance module).  
* It is the owner of the ERC-1155 token contract that registers participants' activity.  
* It is the owner of two PowersFactory’s: One that creates new IdeasDAOs, and one that creates new PhysicalDAOs. PowersFactory is a smart contract that deploys bespoke Powers instance. The owner of the contract can save mandates to the contract, and when they call the createPowers function, the contract deploys a Powers instance with these mandates. 


### ***Actions*** 

The PrimaryDAO can take the following actions:

* It can create new IdeasDAOs and confirms the creation of PhysicalDAOs. But PhysicalDAOs can only be created after a proposal is made by an IdeasDAOs. 
* It has the power to deactivate both types of sub-DAOs.
* It also (re)assigns Safe Treasury allowances to its DigitalDAO and its PhysicalDAOs.
* It can set an allowance amount to the DigitalDAO and PhysicalDAOs, but only after a proposal was submitted by either Digital or Physical sub-DAOs.
* It can update its own URI (Uniform Resource Identifier) which contains all the metadata of the organisation, including designations of primary- and sub-DAOs needed in the front-end. In other words, to show new sub-DAOs in the frontend,
the URI needs to be updated separately.
* It can transfer tokens accidentally sent to its address to the Safe Treasury.
* It can assign a membership role to Public accounts.
* It can elect Executives from among PrimaryDAO Members. Roles are not mutually exclusive, e.g. if a DAO Member is elected as an Executive they can still keep their original role and perform the same tasks as before in addition to their new tasks.
* It can remove inactive elected Executives.
* It can adopt new mandates (and as a consequence also revoke old ones).



### ***Membership*** 
* Always acquired indirectly. To be considered, you must first become an active contributor inside
the sub-DAOs of the organisation’s ecosystem.

### ***Roles*** 

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | Admin | Revoked at construction. |
| 1 | PrimaryDAO Members | Must have Attendance Badge from PhysicalDAO and/or directed request from IdeasDAO **
 |
| 2 | PrimaryDAO Executives | Elected every N-months from among Members. |
| 3 | PhysicalDAOs | Assigned at creation of a sub-DAO. Can be removed by Executives. |
| 4 | IdeasDAOs | Assigned at creation of a sub-DAO. Can be removed by Executives. |
| 5 | DigitalDAOs | Assigned at creation of a DAO. Only 1 DigitalDAO at all times. |
| … | Public | Everyone. |

### 

### ***Executive Mandates***

#### Create and revoke IdeasDAO

Members have the right to initiate new IdeasDAOs, while each idea has to be ok-ed by elected executives.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Members | Initiate IdeasDAO creation | StatementOfIntent.sol | "string name, string uri" | none | Initiates creation proposal. Vote, normal threshold. |
| PrimaryDAO Executives | Execute IdeasDAO creation | BespokeActionSimple.sol | (same as above) | Creates IdeasDAO | Vote \+ proposal exists (No allowance assigned) |
| PrimaryDAO Executives | Assign role ID to IdeasDAO | BespokeActionOnReturnValue.sol | (same as above) | Assigns role to return value of previous mandate. | None. Any executive can execute. |
| PrimaryDAO Members  | Veto revoking IdeasDAO | StatementOfIntent.sol | (same as above) | none | Vote, high threshold. |
| PrimaryDAO Executives | Revoke IdeasDAO (Role) | BespokeActionOnReturnValue.sol | (same as above) | Revokes roleId from DAO. | DAO creation should have executed, members should not have vetoed. |

#### Create and revoke PhysicalDAO

IdeasDAOs can initiate the creation of PhysicalDAOs. The PrimaryDAO will be assigned as admin of the new PhysicalDAO and hold veto power of adopting of new mandates. 

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO | Initiate PhysicalDAO Creation | StatementOfIntent.sol | "string name, string uri" | none | Any IdeasDAO can propose. |
| PrimaryDAO Executives | Deploy Merit Badge Contract | BespokeAction_Advanced.sol | (same as above) | Deploys Soulbound1155 | Any executive can execute. |
| PrimaryDAO Executives | Add Dependency | BespokeAction_OnReturnValue.sol | (same as above) | Adds dependency to factory | Any executive can execute. |
| PrimaryDAO Executives | Execute PhysicalDAO Creation | BespokeActionSimple.sol | (same as above) | Creates PhysicalDAO | Proposal exists, veto does not exist |
| PrimaryDAO Executives | Assign role ID to PhysicalDAO | BespokeActionOnReturnValue.sol | (same as above) | Assigns role to return value of previous mandate. | Any executive can execute. Previous action executed. |
| PrimaryDAO Executives | Assign Delegate status | SafeExecTransactionOnReturnValue.sol | (same as above) | Assigns delegate status at Safe treasury. | Any executive can execute. Previous action executed. |
| PrimaryDAO Members | Veto revoking PhysicalDAO | StatementOfIntent.sol | (same as above) | none | Vote, high threshold. |
| PrimaryDAO Executives | Revoke PhysicalDAO (Role) | BespokeActionOnReturnValue.sol | (same as above) | Revokes roleID. | DAO creation should have executed, members should not have vetoed. |
| PrimaryDAO Executives | Revoke Delegate status | SafeExecTransaction.sol | (same as above) | Revokes delegate status. | Any executive can execute. Previous action executed. |

#### Assign Legal Representative to PhysicalDAO

Process for vetting and assigning legal representatives to PhysicalDAOs.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | ZKP Check Age | ZKPassport_Check.sol | "address PhysicalSubDAO, uint16 assignRepMandateId" | Verifies age > 18 | Anyone can execute. |
| Public | ZKP Check Country | ZKPassport_Check.sol | (same as above) | Verifies country is GBR | Must have passed age check. |
| IdeasDAO | Propose Legal Representative | StatementOfIntent.sol | "address PhysicalSubDAO, uint16 assignRepMandateId, address ProposedLegalRep" | None | Proposal from IdeasDAO. |
| PrimaryDAO Executives | Assign Legal Representative Role | PowersAction_Flexible.sol | "address ProposedLegalRep" | Assigns role 3 in PhysicalDAO | Proposal must exist. |

#### Assign additional allowances to PhysicalDAO or DigitalDAO

Physical and Digital sub-DAOs can request allowances for their address in the Safe treasury. Physical sub-DAOs can veto allowances for both.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Physical sub-DAO | Veto allowance | StatementOfIntent.sol | "address sub-DAO, address Token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin" | none | Vote, high threshold. |
| Physical sub-DAO | Request additional allowance | StatementOfIntent.sol | (same as above) | none | Initiates allowance proposal. |
| PrimaryDAO Executives | Grant Allowance to Physical sub-DAO | SafeAllowance_Action.sol | (same as above) | Safe.approve(subDao, amount) | Proposal exists, vote, no Physical sub-DAO veto. |
| Digital sub-DAO | Request additional allowance | StatementOfIntent.sol | (same as above) | none | Initiates allowance proposal. |
| PrimaryDAO Executives | Grant Allowance to Digital sub-DAO | SafeAllowance_Action.sol | (same as above) | Safe.approve(subDao, amount) | Proposal exists, vote, no Physical sub-DAO veto. |

#### Veto Calls to sub-DAOs

The PrimaryDAO can block mandate reforms at DigitalDAO and PhysicalDAOs. It does this by calling the mandateId of the veto law at the target Powers implementation.  

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Executives | Veto Call to sub-Dao | PowersAction_Flexible.sol | "Address PowersTarget, uint16 MandateIdTarget,  uint16[] MandateId, uint256[] roleIds" | Calls to sub-DAOs | Executioners can veto calls to Powers instances in other sub-DAOs. |

#### Update URI

The URI contains all the metadata of the organisation, including designations of sub- and primary-DAOs needed in the front end. In other words, to show new sub-DAOs in the frontend, the URI needs to be updated separately.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Members  | Veto update URI | StatementOfIntent.sol | "string new URI" | none | Vote. |
| PrimaryDAO Executives | Update URI | BespokeAction_Simple.sol | (same as above) | setUri call | IdeasDAO did not veto, timelock. |

#### Mint NFTs PhysicalDAO

PhysicalDAOs can mint NFTs (such as Attendance Badges) via the PrimaryDAO.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO | Mint token PhysicalDAO | GovernedToken_MintEncodedToken.sol | "address to" | Mint function ERC 1155 | None. |

#### Transfer tokens to treasury

It is very likely that someone will, by accident, transfer tokens to the address of the DAO instead of its treasury. This is a major issue, because the DAO has no way of transferring this tokens out. As a backup, there is a mandate that lets DAOs transfer tokens (of which they have an allowance) back to the treasury. 

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Executive | Transfer tokens to treasury | Safe_RecoverTokens.sol | "address treasury, address allowanceModule" | Goes through tokens of which the DAO has an allowance, and if the DAO has any, transfers them to the treasury | None, absolutely anyone can call this mandate and pay for the check & transfer. |

### 

### ***Electoral Mandates***

#### Claim membership PrimaryDAO

This is a two step process to gain membership to the PrimaryDAO. First an IdeasDAO forwards a request, then the public user claims membership by proving ownership of required tokens (Attendance Badges (PhysicalDAO) or Election Tokens (IdeasDAO)).

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO | Request Membership Step 1 | StatementOfIntent.sol | "uint256[] TokenIds" | Forwards request | IdeasDAO vote. |
| Public | Request Membership Step 2 | GovernedToken_GatedAccess.sol | (same as above) | Checks ownership of tokens and Assigns Role | Previous step must be executed. Any public address can request. |

#### Revoke Membership

PrimaryDAO Members can veto revocation, PrimaryDAO Executives can execute revocation.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Members | Veto Revoke Membership | StatementOfIntent.sol | "address MemberAddress" | None | Vote. |
| PrimaryDAO Executives | Revoke Membership | BespokeAction_Advanced.sol | (same as above) | Revokes role | Vote. Timelock. No veto. |

#### Elect PrimaryDAO Executives

This is an electoral flow for assigning PrimaryDAO Executives. First an election is created, it includes a start and end block of the election. Before the election starts, members can nominate themselves. After the start block passes, the electoral vote can be called: it creates a bespoke mandate that contains a list of candidates on which accounts can vote. After the end block passes a tally is taken, old PrimaryDAO Executive roles are revoked and new ones are assigned. Through a final mandate the electoral vote mandate can be cleaned up.   

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Member | Create election | BespokeActionSimple.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Creates election helper | Throttled. |
| PrimaryDAO Member | Open voting for Executive election | ElectionList_CreateVoteMandate.sol | (same as above) | Creates vote mandate | Previous executed. |
| PrimaryDAO Member | Tally Executive elections | ElectionList_Tally.sol | None | Tallys vote | Previous executed. |
| PrimaryDAO Member | Clean up Executive election | BespokeActionOnReturnValue.sol | None | Clean up | Previous executed. |
| PrimaryDAO Member | Vote of No Confidence | RevokeAccountsRoleId.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Revokes all Executive roles | High threshold, high quorum. |
| PrimaryDAO Member | Nominate | ElectionList_Nominate.sol | (bool, nominateMe) | Nomination logged at ElectionList | None, any member can nominate |
| PrimaryDAO Member | Revoke Nomination | ElectionList_Nominate.sol | (bool, nominateMe) | Nomination revoked at ElectionList | None, any member can revoke nomination |

### 

### ***Reform Mandates***

#### Adopt mandate

This process allows the PrimaryDAO to upgrade its governance by adopting new mandates. It initiates a proposal that must pass a member veto and receive approval from sub-DAOs before being executed by Executives.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO Executives | Initiate mandate adoption | StatementOfIntent.sol | "address[] mandates, uint256[] roleids" | None | None. Any PrimaryDAO Executive can initiate call for mandate reform. |
| PrimaryDAO Members | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote, high threshold + quorum |
| DigitalDAO | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote. |
| IdeasDAO | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote. |
| PhysicalDAO | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote. |
| PrimaryDAO Executives | Checkpoint 1 | StatementOfIntent.sol | None | Confirms Members did not veto | Check prev veto not fulfilled. |
| PrimaryDAO Executives | Checkpoint 2 | StatementOfIntent.sol | None | Confirms Digital did not veto | Check prev veto not fulfilled. |
| PrimaryDAO Executives | Checkpoint 3 | StatementOfIntent.sol | None | Confirms IdeasDAO did not veto | Check prev veto not fulfilled. |
| PrimaryDAO Executives | Execute mandate Adoption | Mandates_Adopt.sol | (same as above) | mandate is adopted. | Vote, high threshold + quorum. Confirm PhysicalDAO did not veto. |

## 

## DigitalDAO

### ***Mission***

A sub-DAO format that is responsible for
all things digital infrastructure, code repositories,
and online interfaces.

### ***Assets*** 

The DigitalDAO owns the github repository that includes: 

* The code base for online UI interfaces for all (sub-)DAOs that make up the organisation. These are managed in a single repository.  
* This includes the code base for physical UI digital experiences used by PhysicalDAOs. 

### ***Actions*** 

The DigitalDAO can take the following actions:

* The public can submit receipts with the request for payment for digital work completed.  
* DigitalDAO Members can propose funding for projects to be implemented.  
* It can request an allowance from the PrimaryDAO.    
  * Note: Payments are transferred from the central Safe treasury and have to be within the allowance set by the PrimaryDAO.  
* It can update its own URI (Uniform Resource Identifier).   
* It can transfer tokens accidentally sent to its address to the Safe Treasury.  
* It can assign a membership role to public accounts if they made successful commits to the Github repository.    
* It can elect Repository Admins from among DigitalDAO Members.
* It can adopt new mandates (and as a consequence also revoke old ones) \- but only if no veto was cast from the PrimaryDAO. 

### ***Membership***
* The Public can send commits via Github of code that they have written, contributing to projects that are building within the ecosystem. Merit badges or Election Tokens are rewarded and can be used to support a membership application. 
[comment]: <> This part needs to be worked on - the DigitalDAO currently has no tokenomics or membership application system coded into its governance infrastructure. 


### ***Roles***

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | DigitalDAO Admin | Revoked at setup |
| 1 | DigitalDAO Members | Proof of Activity \- role by git commit |
| 2 | Github Admin | Elected every N-months from among Members. |
| 6 | PrimaryDAO | Assigned at creation. Can only be single address. |
| … | Public | Everyone. |

### 

### ***Executive Mandates***

#### Request Allowances from PrimaryDAO

The DigitalDAO can request additional allowances from the PrimaryDAO Safe Treasury.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Members | Veto request allowance | StatementOfIntent.sol | "address sub-DAO, address Token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin" | none | Vote. |
| Github Admins | Request allowance | PowersAction_Simple.sol | (same as above) | Calls PrimaryDAO | Vote, high threshold. Proposal must exist, no veto. |

#### Payment of receipts

Meant for expenses that have already been made. Payment after completion.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Submit receipt | StatementOfIntent.sol | "address Token, uint256 Amount, address PayableTo" | None | None. Anyone (also non-members) can submit a receipt. |
| Github Admins | Ok-receipt | StatementOfIntent.sol | (Same as above) | None | None. Any Github Admin can ok a receipt. |
| Github Admins | Approve Payment of Receipt | SafeAllowance_Transfer.sol | (Same as above) | Call to safe allowance module: transfer | Vote, ok-receipt executed. |

#### 

#### Payment of projects

Meant for expenses that will be made in future. Payment before completion.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Members | Submit a project for Funding | StatementOfIntent.sol | (Same as above) | None | Vote. Low threshold and quorum. |
| Github Admins | Approve funding of project | SafeAllowance_Transfer.sol | (Same as above) | Call to safe allowance module: transfer | Vote, project should have been submitted. |

#### 

#### Update uri

Allows the Github Admins to update the DAO's metadata URI, ensuring that the organization's public profile (links, description) remains current.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Github Admins | Update URI | BespokeAction_OnOwnPowers.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### 

#### Transfer tokens to Safe Treasury

A recovery mechanism ensuring that any assets accidentally sent to the DigitalDAO's address (instead of the Treasury) can be recovered and moved to the central Safe Treasury.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Github Admins | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, any Github Admin can call this mandate and pay for the transfer. |

### 

### ***Electoral Mandates***

#### Assign membership

Membership in the DigitalDAO is meritocratic, based on verified code contributions. Contributors can claim their role by proving ownership of their GitHub commits.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Apply for member role | Github\_ClaimRoleWithSig.sol | Branch, paths, roleIds, signature | None | None \- anyone can call. |
| Public | Claim Member role | Github\_AssignRoleWithSig.sol | None | Assigns role. | Previous mandate needs to have passed. |

#### Revoke Membership

Repository Admins can revoke membership, subject to DigitalDAO Member veto.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Members | Veto Revoke Membership | StatementOfIntent.sol | "address MemberAddress" | None | Vote. |
| Github Admins | Revoke Membership | BespokeAction_OnOwnPowers_Advanced.sol | (same as above) | Revokes role | Vote. Timelock. No veto. |

#### Elect Repository Admins

A democratic process where DigitalDAO Members elect leadership (Github Admins) to manage the sub-DAO's operations. Github Admins are automatically assigned admin rights to the experiment's Github repository. If an account loses the Github Admin role, their admin rights will be automatically revoked. 

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Member | Create election | BespokeActionSimple.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Creates election helper | Throttled. |
| DigitalDAO Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| DigitalDAO Member | Revoke Nomination | BespokeActionSimple.sol | (bool, nominateMe) | Nomination revoked at Nominees.sol helper contract | None, any member can revoke nomination |
| DigitalDAO Member | Call election | OpenElectionStart.sol | None | Creates an election vote list | Throttled: every N blocks, for the rest none: any member can call the mandate. |
| DigitalDAO Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election. |
| DigitalDAO Member | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any Member can call this. |
| DigitalDAO Members | Clean up election | BespokeActionOnReturnValue.sol | None | Cleans up election mandates | Tally needs to have been executed. |

### 

#### Vote of No Confidence

A fail-safe mechanism allowing DigitalDAO Members to revoke the power of all current Github Admins if they fail to perform their duties, immediately triggering a new election.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Member | Vote of No Confidence | RevokeAccountsRoleId.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Revokes all Executive roles | High threshold, high quorum. |
| DigitalDAO Member | Create election | BespokeActionSimple.sol | (same as above) | Creates election helper | Previous mandate executed. |
| DigitalDAO Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| DigitalDAO Member | Revoke Nomination | BespokeActionSimple.sol | (bool, nominateMe) | Nomination revoked at Nominees.sol helper contract | None, any member can revoke nomination |
| DigitalDAO Member | Call election | OpenElectionStart.sol | None | Creates an election vote list | Throttled: every N blocks, for the rest none: any executive can call the mandate. |
| DigitalDAO Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election. |
| DigitalDAO Members | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any Member can call this. |
| DigitalDAO Members | Clean up election | BespokeActionOnReturnValue.sol | None | Cleans up election mandates | Tally needs to have been executed. |

### 

### ***Reform Mandates***

#### Adopt mandate

DigitalDAO Members can initiate mandate adoption, PrimaryDAO can veto, and Github Admins execute.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| DigitalDAO Members | Initiate Adopting Mandates | StatementOfIntent.sol | "address[] mandates, uint256[] roleIds" | None | Vote, high threshold \+ quorum |
| PrimaryDAO | Veto Adopting Mandates | StatementOfIntent.sol | (same as above) | None | Proposal must exist. |
| Github Admins | Adopt new Mandates | Mandates_Adopt.sol | (same as above) | mandate is adopted. | Vote, high threshold  \+ quorum. No veto |

## 

## IdeasDAO

### ***Mission***

A sub-DAO format for the free and experimental incu-
bation of new concepts. Manages ideas and discussions around ecosystem initiatives. Because role designations define access to the IdeasDAO forum, granting and revoking roles defines who is given a voice in the sub-DAO. It also defines who has the power to initiate the creation of a PhysicalDAO.   

### ***Assets*** 

Intangible assets in relation to cultural initiatives: 

* Ideas, knowledge.   
* Social networks, interaction.   
* Engagement, memes. 

### ***Actions*** 

The IdeasDAO can take the following actions:

* Initiate the creation of PhysicalDAOs.
* Update its own URI (Uniform Resource Identifier).
* Transfer tokens accidentally sent to its address to the Safe Treasury.  
* Moderators can assess and assign membership to applicants.  
* Moderators can revoke membership.
* Members can apply for membership of the PrimaryDAO.
* Conveners can assign and revoke IdeasDAO Moderator roles.
* Elect IdeasDAO Conveners from among IdeasDAO Members.  
* Adopt new mandates (and as a consequence also revoke old ones). There is no veto possible from the PrimaryDAO. 

### ***Membership*** 
* If the Public see a topic being discussed that interests them, they can send an application form to the IdeasDAO of their choice and a Convenor inside will review their application.
* No IdeasDAO Convenor exists upon creation of the IdeasDAO. The first one must be elected after creation. 
* New IdeasDAO Convenors can be elected every 3 months from among IdeasDAO Members. Elections must be triggered manually. 
* IdeasDAO Members can nominate themselves for the IdeasDAO Convenor role. The top three Members with the most Election Tokens get automatically elected as long as they haven't been elected twice before. 
* A maximum of 3 IdeasDAO Convenors can ecist at any given time for a maximum of 2 terms. Achievement Badges are given out not only to signify participation, but to also cancel out over-election from happening inside the governance. 



### ***Roles***

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | IdeasDAO Admin | Revoked at setup |
| 1 | IdeasDAO Members | Assigned by Moderators after application. |
| 2 | IdeasDAO Conveners | Elected every N-months from among Members. |
| 3 | IdeasDAO Moderators  | Assigned by Conveners. |
| 6 | PrimaryDAO | Assigned at setup. |
| … | Public | Everyone. |

### 

### ***Executive Mandates***

#### Request new PhysicalDAO

Gives the IdeasDAO the power to incubate new physical 'event pop-up' initiatives. IdeasDAO Members can initiate the request, IdeasDAO Moderators can veto it, and IdeasDAO Conveners can request the creation at the PrimaryDAO.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Members | Initiate request for new PhysicalDAO | StatementOfIntent.sol | "address Admin" | None | Vote, simple majority. |
| IdeasDAO Moderators | Veto request for new PhysicalDAO | StatementOfIntent.sol | (same as above) | None | Vote. |
| IdeasDAO Conveners | Request new PhysicalDAO | PowersAction_Simple.sol | (same as above) | Requests mandate at PrimaryDAO | Vote, simple majority. Proposal must exist, no veto. |

#### 

#### Update uri

Allows IdeasDAO Conveners to update the DAO's metadata URI.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Conveners | Update URI | BespokeAction.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### 

#### Transfer tokens to treasury

Recovers assets sent to the IdeasDAO address to the central Treasury.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Conveners | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, any convener can call this mandate and pay for the transfer. |

### 

### ***Electoral Mandates***

#### Assign membership

IdeasDAO Membership is assigned by IdeasDAO Moderators following an application by a public participant.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Apply for Membership | StatementOfIntent.sol | "address ApplicantAddress, string ApplicationURI" | None | Throttled. |
| IdeasDAO Moderators | Assess and Assign Membership | BespokeAction_OnOwnPowers_Advanced.sol | (same as above) | Assigns role | Proposal must exist. |

#### Revoke membership

IdeasDAO Moderators can revoke membership following behaviour that goes against the Community Guidelines, subject to a Member veto.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Members | Veto Revoke Membership | StatementOfIntent.sol | "address MemberAddress" | None | Vote. |
| IdeasDAO Moderators | Revoke Membership | BespokeAction_OnOwnPowers_Advanced.sol | (same as above) | Revokes role | Vote. Timelock. No veto. |

#### Request Membership of PrimaryDAO

Members can apply for membership of the PrimaryDAO, which Moderators can then forward to the PrimaryDAO.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Members | Apply for Membership of PrimaryDAO | StatementOfIntent.sol | "uint256[] TokenIds" | None | None. |
| IdeasDAO Moderators | Request Membership of PrimaryDAO | PowersAction_Simple.sol | (same as above) | Calls PrimaryDAO | Vote. Proposal must exist. |

#### Assign and Revoke IdeasDAO Moderators

IdeasDAO Conveners can assign and revoke IdeasDAO Moderator roles, subject to Member veto.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Members | Veto Assign Moderator Role | StatementOfIntent.sol | "address Account" | None | Vote. |
| IdeasDAO Conveners | Assign Moderator Role | BespokeAction_OnOwnPowers_Advanced.sol | (same as above) | Assigns role | Vote. No veto. |
| IdeasDAO Members | Veto Revoke Moderator Role | StatementOfIntent.sol | (same as above) | None | Vote. |
| IdeasDAO Conveners | Revoke Moderator Role | BespokeAction_OnOwnPowers_Advanced.sol | (same as above) | Revokes role | Vote. No veto. |

#### Elect Conveners

Election flow similar to electing Repository Admins at the DigitalDAO for electing IdeasDAO Conveners.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Member | Create election | BespokeActionSimple.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Creates election helper | Throttled. |
| IdeasDAO Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| IdeasDAO Member | Revoke Nomination | BespokeActionSimple.sol | (bool, nominateMe) | Nomination revoked at Nominees.sol helper contract | None, any member can revoke nomination |
| IdeasDAO Member | Call election | OpenElectionStart.sol | None | Creates an election vote list | Throttled: every N blocks, for the rest none: any member can call the mandate. |
| IdeasDAO Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election. |
| IdeasDAO Member | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any member can call this. |
| IdeasDAO Member | Clean up election | ElectionList\_CleanUpVoteMandate.sol | None | Cleans up election mandates | Tally needs to have been executed. |

### 

#### Vote of No Confidence

A fail-safe mechanism allowing IdeasDAO Members to revoke the power of all current IdeasDAO Conveners if they fail to perform their duties, immediately triggering a new election. Same as at the Digital sub-DAO. 

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Member | Vote of No Confidence | RevokeAccountsRoleId.sol | "string Title, uint48 StartBlock, uint48 EndBlock" | Revokes all Executive roles [comment]: <> (Should this not say 'Revokes all Convenor roles' for clarity to not get confused with the actual Executives of the PrimaryDAO?) | High threshold, high quorum. |
| IdeasDAO Member | Create election | BespokeActionSimple.sol | (same as above) | Creates election helper | Previous mandate executed. |
| IdeasDAO Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| IdeasDAO Member | Revoke Nomination | BespokeActionSimple.sol | (bool, nominateMe) | Nomination revoked at Nominees.sol helper contract | None, any member can revoke nomination |
| IdeasDAO Member | Call election | OpenElectionStart.sol | None | Creates an election vote list | Throttled: every N blocks, for the rest none: any executive [comment]: <> (Does this mean the executives from PrimaryDAO?) can call the mandate. |
| IdeasDAO Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any IdeasDAO Member can vote. This mandate ONLY appear by calling call election. |
| IdeasDAO Member | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any IdeasDAO Member can call this. |
| IdeasDAO Member | Clean up election | BespokeActionOnReturnValue.sol | None | Cleans up election mandates | Tally needs to have been executed. |

### ***Reform mandates***

#### Adopt mandate

Note: no veto from outside parties. IdeasDAOs can create their own mandates and roles. Because they do not control any funds, they can be very freewheeling.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| IdeasDAO Members | Veto Adoption | StatementOfIntent.sol | "address[] mandates, uint256[] roleIds" | None | Vote, high threshold \+ quorum |
| IdeasDAO Conveners | Adopt Mandates | Mandates_Adopt.sol | (same as above) | mandate is adopted. | Vote, high threshold \+ quorum. |

## 

## PhysicalDAO

### ***Mission***

A sub-DAO format that interacts with
real-world jurisdictions. Manages physical pop-up events. This involves sale of physical artifacts (such as art works), managing access to physical spaces, compliance to local jurisdictions, etc. PhysicalDAOs are initiated by IdeasDAOs.

### ***Assets*** 

The PhysicalDAO manages any kind of Real World Asset in relation to the event:  

* (Rented, bought) Physical space.   
* Key access to this space.   
* Any type of physical items to be used in conferences, meetings, exhibitions, etc.   
* Cars, bicycle, public transport cards, wheelchairs, on-ramps, or any other physical item needed for mobility and accessibility.
* **Merit Tokens:** A locally deployed Soulbound1155 token contract used for rewarding contributions.

### ***Actions*** 

The PhysicalDAO can take the following actions:

* Conveners can submit and approve payment of receipts. This includes payments for work done by Conveners, such as time spent organising for an IRL event.
* Conveners can sell cultural artifacts which have been minted as ERC-721 NFTs outside of the ecosystem. Creators assign the
PhysicalDAO as an ‘operator’ and the events become an ‘exchange platform’ for their cultural artifact sales. Creators can still sell independently from the PhysicalDAO, as their NFTs are not locked into this system.
* Conveners can mint Attendance Badges from PrimaryDAO and hand out them out to Attendees at the event,
this is done by inputting a wallet ID and manually airdropping the POAP to them.
* It can select up to three Conveners at a time. This is done by Legal Representatives who assign nominees, and attendees
can elect from this list of nominees through a Peer Select mechanism.
* Attendees can mint 'Merit Token' NFTs. This is done via someone who hands out the tokens to them, an additional role of 'Engagement Officer'. 
[comment]: <> (NEW ROLE ALERT: we spoke about this in the meeting to simplify the Merit token flow, so all attendees do not need to vote to give someone a Merit token. I have added this in here but will need to be added into the tables as a new mandate + into the organisation's governance structure) 
* Legal Representatives can adopt and revoke executive mandates.
* Update its own URI (Uniform Resource Identifier).
* It can transfer tokens accidentally sent to its address to the Safe Treasury.
* Adopt new mandates (and as a consequence also revoke old
ones) - but only if no veto was cast from the
PrimaryDAO. 

### ***Roles***

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | PhysicalDAO Admin | Revoked at setup |
| 1 | PhysicalDAO Attendee | Proof of Activity \- POAP/Token check |
| 2 | PhysicalDAO Convener | Selected via Peer Selection. |
| 3 | PhysicalDAO Legal Representative | Assigned by Primary DAO. |
| 6 | PrimaryDAO | Assigned at setup. |
| … | Public | Everyone. |

###  

### ***Executive Mandates***

#### Sell NFT Artwork

PhysicalDAO Conveners can force sell NFT artworks, distributing payment according to splits set by the Governed721 contract.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Conveners | Sell NFT artwork | BespokeAction_Simple.sol | "address oldOwner, address newOwner, uint256 TokenId, bytes Data" | Transfers NFT | Vote. |

#### Payment of receipts

Meant for expenses that have already been made. Payment after completion.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Conveners | Submit & Approve payment of receipt | SafeAllowance_Transfer.sol | "address Token, uint256 Amount, address PayableTo" | Call to safe allowance module: transfer | Vote. |

#### Mint POAPS

Enables PhysicalDAO Conveners to issue Proof of Attendance (POAP) tokens via the PrimaryDAO.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Convener | Mint POAP | PowersAction_Simple.sol | "address To" | Calls PrimaryDAO to mint | Vote. |

#### Merit NFTs for Attendees

System for recognizing contributions. PhysicalDAO Conveners propose, PhysicalDAO Attendees vote to mint.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Conveners | Propose minting 'Merit' NFTs | StatementOfIntent.sol | "address Attendee" | None | Vote. |
| PhysicalDAO Attendees | Vote on 'Merit' NFT proposals | BespokeAction_Advanced.sol | (same as above) | Mints Merit Token | Vote. |

#### Redeem Rewards

Holders of Merit Token NFTs can redeem them for rewards. 

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Attendee | Redeem 'Merit Token' NFTs | GovernedToken_BurnToAccess.sol | "address PayableTo" | Burns token | None. |
| Attendee | Claim payment | SafeAllowance_PresetTransfer.sol | (same as above) | Transfers reward | Previous executed. |

#### Update URI

Allows the PhysicalDAO Conveners to update the DAO's metadata URI.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Conveners | Update URI | BespokeAction_OnOwnPowers.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### Transfer tokens to Safe Treasury

Recovers assets sent to the PhysicalDAO address.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Conveners | Transfer tokens to treasury | Safe_RecoverTokens.sol | "address treasury, address allowanceModule" | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, any PhysicalDAO Convener can call this mandate. |

### 

### ***Electoral Mandates***

#### Claim membership (Attendee)

Grants governance rights to individuals who have attended physical events and hold Attendance Badges and Metrit Tokens.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Attendee | Request Membership | GovernedToken_GatedAccess.sol | None | Assigns role | The caller needs to own 1 token minted by the PhysicalDAO in last 15 days. |

#### Select Conveners

Process for selecting PhysicalDAO Conveners involving ZKP checks and peer selection.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | ZKP Check Age | ZKPassport_Check.sol | "bool Nominate" | Verifies age > 18 | Anyone can execute. |
| Public | Nominate for selection | Nominate.sol | (same as above) | Logs nomination | Previous executed. |
| Legal Rep | Revoke nomination | BespokeAction_Advanced.sol | "address Nominee" | Revokes nomination | Vote. |
| Legal Rep | Adopt Peer Select Mandate | Mandates_Adopt_Prepackaged.sol | None | Adopts Peer Select | Vote. |

#### Assign Legal Representatives

PrimaryDAO assigns Legal Representatives.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PrimaryDAO | Assign Legal Representatives | BespokeAction_OnOwnPowers_Advanced.sol | "address Representative" | Assigns Role | Vote. |

### 

### ***Reform Mandates***

#### Adopt mandate

PhysicalDAO Attendees can initiate, PrimaryDAO can veto, PhysicalDAO Conveners adopt.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
|PhysicalDAO Attendees | Initiate Adopting Mandates | StatementOfIntent.sol | "address[] mandates, uint256[] roleIds" | None | Vote, high threshold \+ quorum |
| PrimaryDAO | Veto Adopting Mandates | StatementOfIntent.sol | (same as above) | None | Proposal must exist. |
| PhysicalDAO Conveners | Adopt new Mandates | Mandates_Adopt.sol | (same as above) | mandate is adopted. | Vote, high threshold  \+ quorum. No veto |

#### Legal Reps Adopt & Revoke

Legal Representatives have the power to adopt or revoke the set of executive mandates, effectively acting as a pause/unpause mechanism for the PhysicalDAO's operations.

| Role | Name | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| PhysicalDAO Legal Rep | Adopt Executive Mandates | Mandates_Adopt_Prepackaged.sol | None | Adopts mandates | Vote. |
| PhysicalDAO Legal Rep | Revoke Executive Mandates | Mandates_Revoke_Prepackaged.sol | None | Revokes mandates | Vote. |


## 

## Off-chain Operations

### ***Dispute Resolution***

Disputes regarding ambiguous mandate conditions or malicious actions by role-holders will be addressed through community discussion in the official communication channels. Final arbitration lies with the **Admin role** of the PrimaryDAO if consensus cannot be reached.

### ***Code of Conduct***

All participants are expected to act in good faith to further the mission of the DAO. The ecosystem relies on the harmonic interaction between the physical, ideational, and digital layers; disruption in one layer may affect the others.

### ***Communication Channels***

Official proposals, discussions, and announcements take place on the community forum. To access it, go to the 'Door' page at www.enterhere.io. 


## Description of Governance

This experiment implements a federated governance model.

* **Remit**: To manage a shared treasury (held by the PrimaryDAO) while empowering specialised sub-DAOs to operate with autonomy in their respective domains (Physical, Ideational, Digital).  
* **Separation of Powers**:  
  * **Financial Control**: Centralised at the PrimaryDAO level to ensure security.  
  * **Operational Control**: Decentralised to sub-DAOs to ensure agility.  
  * **Checks and Balances**: Most sub-DAO actions (like mandates or physical access) are executable by local Conveners but subject to Veto by the PrimaryDAO Executives.  
* **Executive Paths**:  
  * **Funding**: sub-DAOs do not hold funds. They act as "cost centres" that request payment execution from the PrimaryDAO.  
  * **Legislation**: sub-DAOs can create their own internal mandates and roles, provided they are not vetoed by the PrimaryDAO.  
* **Summary**: This structure allows for the PhysicalDAO to worry about rent and keys, while a DigitalDAO worries about commits and code, all bound by a common economic and constitutional framework.

## Risk Assessment

### ***Dependency Chains***

The DigitalDAO (\#3) relies on the recognition of sub-DAOs (\#1 & \#2) to execute payments. If recognition logic fails or desynchronises, operations may stall.

