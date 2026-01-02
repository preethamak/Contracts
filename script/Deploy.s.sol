// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {GenesisPass} from "../src/GenesisPass.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying GenesisPass contract...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        GenesisPass genesisPass = new GenesisPass(deployer);
        
        console.log("GenesisPass deployed at:", address(genesisPass));
        console.log("Owner:", genesisPass.owner());
        console.log("Mint Price:", genesisPass.mintPrice());
        console.log("Max Supply:", genesisPass.MAX_SUPPLY());
        console.log("Tokens per NFT:", genesisPass.TOKENS_PER_NFT());
        
        vm.stopBroadcast();
    }
}

