// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "./lib/Base64.sol";

/*
 * @title PetNft
 * @dev A contract for creating and managing Pet NFTs
 * @author i_atiq
 */
contract PetNft is ERC721 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using Strings for uint256;

    error PetNft__InvalidSignature();

    event NFTMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string name,
        PetType petType,
        string imageUri
    );
    event NFTUpdated(
        uint256 indexed tokenId,
        uint256 level,
        uint256 agility,
        uint256 strength,
        uint256 intelligence
    );

    enum PetType {
        CAT,
        DOG,
        DUCK,
        DOVE
    }
    enum StatType {
        AGILITY,
        STRENGTH,
        INTELLIGENCE
    }

    struct Pet {
        string name;
        uint256 level;
        PetType petType;
        uint256 agility;
        uint256 strength;
        uint256 intelligence;
        uint256 nonce;
    }

    mapping(PetType => string) private initialImageUri;
    mapping(uint256 => Pet) public tokenIdToPet;

    uint256 public s_tokenCounter;
    address private s_backendSigner;

    constructor(
        string[] memory tokenUris,
        PetType[] memory types,
        address _backendSigner
    ) ERC721("PetNft", "PET") {
        s_tokenCounter = 0;
        s_backendSigner = _backendSigner;
        for (uint i = 0; i < tokenUris.length; i++) {
            initialImageUri[types[i]] = tokenUris[i];
        }
    }

    function mintNft(PetType petType, string memory name) public {
        uint256 tokenId = s_tokenCounter;
        _safeMint(msg.sender, tokenId);

        tokenIdToPet[tokenId] = Pet(name, 1, petType, 1, 1, 1, 0);
        s_tokenCounter++;

        emit NFTMinted(
            msg.sender,
            tokenId,
            name,
            petType,
            initialImageUri[petType]
        );
    }

    function updatePetStat(
        uint256 tokenId,
        StatType statType,
        bytes memory signature
    ) public {
        _requireOwned(tokenId);

        Pet storage pet = tokenIdToPet[tokenId];

        // Hash the data: tokenId, userAddress
        bytes32 messageHash = keccak256(
            abi.encodePacked(tokenId, msg.sender, pet.nonce)
        );

        // Recover the signer from the signature
        address signer = messageHash.toEthSignedMessageHash().recover(
            signature
        );

        if (signer != s_backendSigner) {
            revert PetNft__InvalidSignature();
        }

        if (statType == StatType.AGILITY) {
            pet.agility++;
        } else if (statType == StatType.STRENGTH) {
            pet.strength++;
        } else if (statType == StatType.INTELLIGENCE) {
            pet.intelligence++;
        }

        if (
            pet.agility > pet.level &&
            pet.strength > pet.level &&
            pet.intelligence > pet.level
        ) {
            pet.level++;
        }

        pet.nonce++;

        emit NFTUpdated(
            tokenId,
            pet.level,
            pet.agility,
            pet.strength,
            pet.intelligence
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        // Retrieve the pet type for the given tokenId
        Pet memory pet = tokenIdToPet[tokenId];

        string memory imageURI = initialImageUri[pet.petType];

        // Return the base URI corresponding to the pet type
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                pet.name,
                                '", "description": "A pet of type ',
                                pet.name,
                                '", ',
                                '"attributes": [',
                                '{"trait_type": "Level", "value": ',
                                _toString(pet.level),
                                "}, ",
                                '{"trait_type": "Agility", "value": ',
                                _toString(pet.agility),
                                "}, ",
                                '{"trait_type": "Strength", "value": ',
                                _toString(pet.strength),
                                "}, ",
                                '{"trait_type": "Intelligence", "value": ',
                                _toString(pet.intelligence),
                                "}",
                                '], "image": "',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        return value.toString();
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getTokenIdToPet(uint256 tokenId) public view returns (Pet memory) {
        return tokenIdToPet[tokenId];
    }

    function getPetNonce(uint256 tokenId) public view returns (uint256) {
        return tokenIdToPet[tokenId].nonce;
    }
}
