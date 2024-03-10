# FreeBookNFT
**Inherits:**
ERC1155, AccessControl

**Author:**
Anthony PIERRE

This contract aims at creating an NFT for a book rental company. According to their loyalty, they get access to the NFT. The more they rent, the higher their NFT evolve, letting them rent free books. Reaching the max evolution at level 5, where they get the chance to own two physical books of their choice.

I've actually uploaded my nft's metadata and images on https://www.pinata.cloud/, but I haven't deployed any contract. The metadata and images can be found in the folders "metadata" and "NFTS" !

*COMPANY and USER can mint the NFT, but the owner of the contract is Boonty.*


## State Variables
### _tokenIds
Use counters to keep count of tokens and Strings


```solidity
Counters.Counter private _tokenIds;
```


### MINTER_ROLE
Define roles


```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```


### EVOLVE_ROLE

```solidity
bytes32 public constant EVOLVE_ROLE = keccak256("EVOLVE_ROLE");
```


### COMPANY_ROLE

```solidity
bytes32 public constant COMPANY_ROLE = keccak256("COMPANY_ROLE");
```


### nftLevels
Mapping to keep track of user actions (in this case, the books rented and if they have already minted an NFT)


```solidity
mapping(uint256 => uint256) public nftLevels;
```


### userActions

```solidity
mapping(address => uint256) public userActions;
```


### hasMinted

```solidity
mapping(address => bool) private hasMinted;
```


### freebookAttributes
*Mapping to keep track of the attributes of the token*


```solidity
mapping(uint256 => FreeBookNFTAttributes) public freebookAttributes;
```


### ownerToNFTId
*mapping to keep track of the NFT ID owned by each user (bc ERC1155 allows people to have many of the same)*


```solidity
mapping(address => uint256) private ownerToNFTId;
```


## Functions
### supportsInterface

*See [IERC165-supportsInterface](/lib/forge-std/src/interfaces/IERC165.sol/interface.IERC165.md#supportsinterface), I need to override this function bc it's present in both contracts other contracts I chose above*

*So here, I check that my contract correctly reports support for interfaces defined in both contracts*


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool);
```

### constructor


```solidity
constructor() ERC1155("ipfs://QmQGxAV5PetNR372hNyjobFzLQ54XkLpDzRFMaU2fw2Cwt/{id}.json");
```

### mint

Setting up the admin role to the deployer (Boonty), and I have uploaded and IA-generated images and metadata for the NFTs and the different levels (the link is the real one)

Function to mint NFTs. Can be called by users or the company

Only someone who hasn't mint can mint new tokens

it initializes book rental counter for new NFT owners

*Set initial NFT level to 1, records the NFT ID owned by the "to" address*

*Removes minter role after minted, keep track of whether user minted*


```solidity
function mint(address to) public returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|: address of the minter|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|newItemId the id of the minted token|


### recordBookRental

function to keep track of book rentals by users, and give roles based on this (at leasts 20 books rented)

if user doesn't have NFT and is eligible for one, then they get minter role (depends on book rentals)

if user is eligible for evolution, they get evolve role

*it updates the "userActions" mapping*

*automatically check for NFT evolution eligibility and evolve it calling the function evolvenft*


```solidity
function recordBookRental(address user) public;
```

### evolveNFT

Function to evolve NFTs, only callable by EVOLVE_ROLE

can only evolve up to level 5 (maximum level)

*Function removes EVOLVE ROLE once evolved (so no abuse)*

*changes attributes of the token*


```solidity
function evolveNFT(uint256 id) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|of the token to be evolved|


### uri

In case we use OpenSea, we need to return the file name as a string

*Override uri function to return URIs based on the NFT level*


```solidity
function uri(uint256 tokenId) public view override returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|: of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|the string of the file name|


### grantRole

Function to allow Boonty to grant roles to other addresses


```solidity
function grantRole(bytes32 role, address account) public override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`bytes32`||
|`account`|`address`|to give role to and role to give|


### revokeRole

function to revoke role (Boonty can do it)


```solidity
function revokeRole(bytes32 role, address account) public override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`bytes32`||
|`account`|`address`|to revoke role to and role to revoke|


### setCompanyAddress

Function to grand the Book Renting Company the Company Role (as I don't know their address)

*Can be called solely by ADMIN (Boonty)*


```solidity
function setCompanyAddress(address _CompanyAddress) public;
```

### getRewardForLevel

Function to define rewards for each NFT level (pseudo-code, implement accordingly)

may not be useful, but I decided to keep it (it was in a first attempt)


```solidity
function getRewardForLevel(uint256 level) public pure returns (string memory reward);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`level`|`uint256`|: evolution level to be checked|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`reward`|`string`|: the associated reward|


### getNFTIdByOwner

function to retrieve NFT ID by owner's address

*it checks if user owns NFT*


```solidity
function getNFTIdByOwner(address owner) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|return associated ID of the token|


## Events
### NFTEvolved
*even when NFT has been evolved*


```solidity
event NFTEvolved(uint256 tokenId, uint256 newLevel);
```

## Structs
### FreeBookNFTAttributes
Store the NFT's attributes (type of reward, level of the reward and associated quantity rewarded)


```solidity
struct FreeBookNFTAttributes {
    string TypeReward;
    uint256 level;
    uint256 quantity;
}
```

