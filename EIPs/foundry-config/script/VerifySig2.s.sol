// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract VerifySig2 is Script {
    function run() external view {
        address caller = 0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177;
        bytes32 modelHash = 0xbe8800dce0dff71e1c349945f6de1ac1f88963ad7f49107af7294b273dfcda55;
        bytes32 memoryHash = 0xb61f2bb4971842949f6e7fdac3e21de6d58c76df007093d6c7d4289ca2065787;
        bytes32 contextHash = 0x38eae41a2b59195ec09b69dc1e5f8849e4626e467a1b0a4f0cfbff3ac933e7c3;
        
        // Test sig1 (without --no-hash)
        bytes memory signature = hex"e20e1695f056a057503859b68520c7107a23e06eceb485080f1a31670c21cbcf10185d718caa0c9d9f2af672cfcb9be2e33e6758cd3709c81a50bc14dce4c0831c";
        
        bytes32 messageHash = keccak256(abi.encodePacked(caller, modelHash, memoryHash, contextHash));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        
        address recovered = ecrecover(prefixedHash, v, r, s);
        console.log("Expected signer:", caller);
        console.log("Recovered signer:", recovered);
        console.log("Match:", recovered == caller);
    }
}
