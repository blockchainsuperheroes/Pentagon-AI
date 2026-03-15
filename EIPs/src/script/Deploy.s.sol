// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/ERC_ANIMA.sol";

contract DeployANIMA is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Platform signer = deployer initially (can transfer later)
        address platformSigner = vm.addr(deployerPrivateKey);
        ERC_ANIMA anima = new ERC_ANIMA("Pentagon ANIMA", "PANIMA", platformSigner);
        
        console.log("ANIMA deployed to:", address(anima));
        
        vm.stopBroadcast();
    }
}
