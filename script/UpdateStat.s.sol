// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PetNft} from "../src/PetNft.sol";

contract Updatestat is Script {
    function run() external {
        updateStat();
    }

    function updateStat() public {
        vm.startBroadcast();
        PetNft petNft = PetNft(0x43Cae396DC42D2B5c80ad8b965eBE94Be51Ad239);
        // The signature will not work duo to chnages in the smart contract
        petNft.updatePetStat(
            0,
            PetNft.StatType.AGILITY,
            hex"81727b84dc2b39bae47c6f695a776f98066ce9f9c12eb3a3e69a153201ccbefb2936d77d581266e8ea65d3578cba3f2dfc5c15033b4a90e1aa013a6ae8bcc4881c"
        );
        vm.stopBroadcast();
    }
}
