// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/ERC_AINFT_v2.sol";

contract DeployV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platformSigner = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        ERC_AINFT_v2 ainft = new ERC_AINFT_v2("Pentagon AINFT v2", "PAINFT2", platformSigner);
        
        console.log("AINFT v2 deployed to:", address(ainft));
        console.log("Platform signer:", platformSigner);
        
        vm.stopBroadcast();
    }
}
