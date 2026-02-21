// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/ATSBadge.sol";

contract DeployATSBadge is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory baseURI = vm.envOr("BASE_URI", string("https://pentagon.games/ats/metadata/"));
        
        vm.startBroadcast(deployerPrivateKey);
        
        ATSBadge badge = new ATSBadge(baseURI);
        
        console.log("ATSBadge deployed to:", address(badge));
        
        vm.stopBroadcast();
    }
}
