// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import {PetNft} from "../../src/PetNft.sol";

contract PetNftTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    PetNft petNft;
    uint256 constant BACKEND_PRIVATE_KEY =
        0x41db5714b235a253243e671839ea733197e5882d8b4b3d687d1312df50bc7a9c;
    address constant BACKEND_SIGNER =
        0x2d82082Bb4ed9cDA7916aE0c44c4419f1a1f0e63;

    address alice;
    uint256 alicePk;

    address user = 0x05b8B8ed022FB7FC2e75983EAb003a6C7202E1A0;

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");

        string[] memory tokenUris = new string[](4);
        tokenUris[0] = "ipfs://QmXbD9cjMZH5NEeuxTJySTVXjBjn7Rf5Z1qiTFSCL7FGyL";
        tokenUris[1] = "ipfs://QmfMypgpQnXa452t9YkNf9XqPsPheyu9hBSUrghUni9TLi";
        tokenUris[2] = "ipfs://QmUoRASuyNcH1MKr2tDTeRVZKe2QwuquYE6i4SDeSiXgLd";
        tokenUris[3] = "ipfs://QmZBtgzuB7LMHciqEEiCzNjPzXqQyYjB9JFVvrtAA4vkHi";
        PetNft.PetType[] memory types = new PetNft.PetType[](4);
        types[0] = PetNft.PetType.CAT;
        types[1] = PetNft.PetType.DOG;
        types[2] = PetNft.PetType.DUCK;
        types[3] = PetNft.PetType.DOVE;

        petNft = new PetNft(tokenUris, types, BACKEND_SIGNER);
    }

    function test_uint2str(uint256 value) public pure {
        string memory actual1 = Strings.toString(value);
        string memory actual2 = _uint2str(value);
        assertEq(actual1, actual2);
    }

    function test_mintNft() public {
        vm.startPrank(user);
        petNft.mintNft(PetNft.PetType.CAT, "cat");
        petNft.mintNft(PetNft.PetType.DOG, "puppy");
        petNft.mintNft(PetNft.PetType.DUCK, "duckling");
        petNft.mintNft(PetNft.PetType.DOVE, "dove");
        vm.stopPrank();
        assertEq(petNft.balanceOf(user), 4);

        string memory uri = petNft.tokenURI(0);
        console.log("uri: ", uri);
    }

    function test_updatePetStat() public {
        vm.prank(user);
        petNft.mintNft(PetNft.PetType.DOVE, "dove");

        uint256 tokenId = 0;
        PetNft.StatType statType = PetNft.StatType.AGILITY;

        uint256 nonce = petNft.getPetNonce(tokenId);

        // Simulate backend signature
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, user, nonce));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        // Sign the message hash using the backend signer's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            BACKEND_PRIVATE_KEY,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Prank as the user to update the stat
        vm.prank(user);
        petNft.updatePetStat(tokenId, statType, signature);

        // Verify that the pet's stat has been updated (level and agility increased)
        PetNft.Pet memory pet = petNft.getTokenIdToPet(tokenId);

        console.log("level: ", pet.level);
        console.log("agility: ", pet.agility);
        console.log("strength: ", pet.strength);
        console.log("intelligence: ", pet.intelligence);

        assertEq(pet.level, 1); // Level should increase by 1
        assertEq(pet.agility, 2); // Agility should increase by 1
        assertEq(pet.strength, 1); // Strength should also increase by 1
        assertEq(pet.intelligence, 1); // Intelligence should increase as well
    }

    function test_updatePetStatFailsForNotUsingRightKey() public {
        vm.prank(user);
        petNft.mintNft(PetNft.PetType.DOVE, "dove");

        uint256 tokenId = 0;
        PetNft.StatType statType = PetNft.StatType.AGILITY;

        // Simulate backend signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(tokenId, user, statType)
        );
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        // Sign the message hash using the backend signer's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePk,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Prank as the user to update the stat
        vm.expectRevert(
            abi.encodeWithSelector(PetNft.PetNft__InvalidSignature.selector)
        );
        vm.prank(user);
        petNft.updatePetStat(tokenId, statType, signature);
    }

    function _uint2str(uint256 _i) public pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
