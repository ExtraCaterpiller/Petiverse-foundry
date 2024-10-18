// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PetNft} from "../src/PetNft.sol";

contract MintNft is Script {
    function run() external {
        mintNft();
    }

    function mintNft() public {
        vm.startBroadcast(0x05b8B8ed022FB7FC2e75983EAb003a6C7202E1A0);
        PetNft petNft = PetNft(0x43Cae396DC42D2B5c80ad8b965eBE94Be51Ad239);
        petNft.mintNft(PetNft.PetType.CAT, "Kitty2");
        vm.stopBroadcast();
    }
}
