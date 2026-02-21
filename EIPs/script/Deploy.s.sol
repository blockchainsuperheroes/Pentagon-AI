// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/ERC7857A.sol";

contract DeployAINFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Platform signer = deployer initially (can transfer later)
        address platformSigner = vm.addr(deployerPrivateKey);
        ERC7857A ainft = new ERC7857A("Pentagon AINFT", "PAINFT", platformSigner);
        
        console.log("AINFT deployed to:", address(ainft));
        
        vm.stopBroadcast();
    }
}
