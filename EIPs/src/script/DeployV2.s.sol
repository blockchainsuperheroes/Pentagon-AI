// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/ERC_ANIMA_v2.sol";

contract DeployV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platformSigner = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        ERC_ANIMA_v2 anima = new ERC_ANIMA_v2("Pentagon ANIMA v2", "PANIMA2", platformSigner);
        
        console.log("ANIMA v2 deployed to:", address(anima));
        console.log("Platform signer:", platformSigner);
        
        vm.stopBroadcast();
    }
}
