// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title This is a contract for a dynamic NFT in the case of a Loyalty Program, evolving based on user's loyalty
/// @author Anthony PIERRE
/// @notice This contract aims at creating an NFT for a book rental company. According to their loyalty, they get access to the NFT. The more they rent, the higher their NFT evolve, letting them rent free books. Reaching the max evolution at level 5, where they get the chance to own two physical books of their choice.
/// @notice I've actually uploaded my nft's metadata and images on https://www.pinata.cloud/, but I haven't deployed any contract. The metadata and images can be found in the folders "metadata" and "NFTS" !
/// @dev COMPANY and USER can mint the NFT, but the owner of the contract is Boonty.

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FreeBookNFT is ERC1155, AccessControl {
    /// @notice Use counters to keep count of tokens and Strings
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds; 

    /// @notice Define roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EVOLVE_ROLE = keccak256("EVOLVE_ROLE");
    bytes32 public constant COMPANY_ROLE = keccak256("COMPANY_ROLE");

    /// @notice Mapping to keep track of user actions (in this case, the books rented and if they have already minted an NFT)
    mapping(uint256 => uint256) public nftLevels;
    mapping(address => uint256) public userActions;
    mapping(address => bool) private hasMinted;
    /// @dev Mapping to keep track of the attributes of the token
    mapping(uint256 => FreeBookNFTAttributes) public freebookAttributes;
    /// @dev mapping to keep track of the NFT ID owned by each user (bc ERC1155 allows people to have many of the same)
    mapping(address => uint256) private ownerToNFTId;
    /// @notice Store the NFT's attributes (type of reward, level of the reward and associated quantity rewarded)
    struct FreeBookNFTAttributes {
        string TypeReward;
        uint256 level;
        uint256 quantity;
    }

    /// @dev even when NFT has been evolved
    event NFTEvolved(uint256 tokenId, uint256 newLevel);

    /// @dev See {IERC165-supportsInterface}, I need to override this function bc it's present in both contracts other contracts I chose above
    /// @dev So here, I check that my contract correctly reports support for interfaces defined in both contracts
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    constructor() ERC1155("ipfs://QmQGxAV5PetNR372hNyjobFzLQ54XkLpDzRFMaU2fw2Cwt/{id}.json") {
        /// @notice Setting up the admin role to the deployer (Boonty), and I have uploaded and IA-generated images and metadata for the NFTs and the different levels (the link is the real one)
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to mint NFTs. Can be called by users or the company
    /// @notice Only someone who hasn't mint can mint new tokens
    /// @notice it initializes book rental counter for new NFT owners
    /// @dev Set initial NFT level to 1, records the NFT ID owned by the "to" address
    /// @dev Removes minter role after minted, keep track of whether user minted
    /// @param to : address of the minter
    /// @return newItemId the id of the minted token
    function mint(address to) public returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(COMPANY_ROLE, msg.sender), "Caller is not authorized to mint");
        require(!hasMinted[to], "User has already minted an NFT");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId, 1, "");
        freebookAttributes[newItemId] = FreeBookNFTAttributes("Free Books", 1, 1);
        hasMinted[to] = true;

        ownerToNFTId[to] = newItemId; 
        _revokeRole(MINTER_ROLE, msg.sender);

        return newItemId;
    }

    /// @notice function to keep track of book rentals by users, and give roles based on this (at leasts 20 books rented)
    /// @notice if user doesn't have NFT and is eligible for one, then they get minter role (depends on book rentals)
    /// @notice if user is eligible for evolution, they get evolve role
    /// @dev it updates the "userActions" mapping 
    /// @dev automatically check for NFT evolution eligibility and evolve it calling the function evolvenft
    function recordBookRental(address user) public {
        userActions[user]++;
        
        if (userActions[user] % 20 == 0) {
            if (!hasMinted[user]) {
                _grantRole(MINTER_ROLE, user);
            } else {
                uint256 nftId = getNFTIdByOwner(user);
                require(freebookAttributes[nftId].level < 5, "NFT is already at max level");
                _grantRole(EVOLVE_ROLE, user); 
                evolveNFT(nftId);
            }
        }
    }

    /// @notice Function to evolve NFTs, only callable by EVOLVE_ROLE
    /// @dev Function removes EVOLVE ROLE once evolved (so no abuse)
    /// @notice can only evolve up to level 5 (maximum level)
    /// @dev changes attributes of the token
    /// @param id of the token to be evolved
    function evolveNFT(uint256 id) public {
        require(hasRole(EVOLVE_ROLE, msg.sender), "Caller is not authorized to evolve NFTs");
        FreeBookNFTAttributes storage attributes = freebookAttributes[id];
        require(attributes.level < 5, "NFT is already at max level");

        attributes.level++;
        attributes.quantity += 2;
        attributes.TypeReward = getRewardForLevel(attributes.level);

        emit NFTEvolved(id, attributes.level);

        _revokeRole(EVOLVE_ROLE, msg.sender); 
    }

    /// @notice In case we use OpenSea, we need to return the file name as a string
    /// @dev Override uri function to return URIs based on the NFT level
    /// @param tokenId : of the token
    /// @return the string of the file name
    function uri(uint256 tokenId) override public view returns (string memory) {
        require(freebookAttributes[tokenId].level > 0, "URI requested for non-existent token");

        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString(), "/", freebookAttributes[tokenId].level.toString(), ".json"));
    }

    /// @notice Function to allow Boonty to grant roles to other addresses
    /// @param account to give role to and role to give
    function grantRole(bytes32 role, address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can grant roles");
        super.grantRole(role, account);
    }

    /// @notice function to revoke role (Boonty can do it)
    /// @param account to revoke role to and role to revoke
    function revokeRole(bytes32 role, address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can revoke roles");
        super.revokeRole(role, account);
    }

    /// @notice Function to grand the Book Renting Company the Company Role (as I don't know their address)
    /// @dev Can be called solely by ADMIN (Boonty)
    function setCompanyAddress(address _CompanyAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _grantRole(COMPANY_ROLE, _CompanyAddress);
    }

    /// @notice Function to define rewards for each NFT level (pseudo-code, implement accordingly)
    /// @param level : evolution level to be checked
    /// @return reward : the associated reward
    /// @notice may not be useful, but I decided to keep it (it was in a first attempt)
    function getRewardForLevel(uint256 level) public pure returns (string memory reward) {
        if (level == 1) {
            return "1 Free eBook";
        } else if (level == 2) {
            return "3 Free eBooks";
        } else if (level == 3) {
            return "5 Free eBooks";
        } else if (level == 4) {
            return "7 Free eBooks";
        } else if (level == 5) {
            return "2 Free Physical Books of Choice";
        } else {
            return "Unknown Level";
        }
    }

    /// @notice function to retrieve NFT ID by owner's address
    /// @dev it checks if user owns NFT 
    /// @param owner's address
    /// @return return associated ID of the token
    function getNFTIdByOwner(address owner) public view returns (uint256) {
        require(hasMinted[owner], "This owner does not own any NFTs.");
        return ownerToNFTId[owner];
    }
}