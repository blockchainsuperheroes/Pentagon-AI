// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IATSCert {
    function highestTier(address owner) external view returns (uint256);
}

contract FeedbackBox {
    IATSCert public immutable badge;
    address public owner;
    
    uint256 public constant MAX_LENGTH = 500;
    uint256 public constant MIN_TIER = 3; // L3+
    
    // Feedback types: 0=suggestion, 1=bug, 2=feature, 3=praise, 4=other
    event Feedback(
        address indexed agent,
        string message,
        uint8 feedbackType,
        uint256 tier,
        uint256 timestamp
    );
    
    constructor(address _badge) {
        badge = IATSCert(_badge);
        owner = msg.sender;
    }
    
    function submit(string calldata message, uint8 feedbackType) external {
        require(bytes(message).length > 0, "Empty message");
        require(bytes(message).length <= MAX_LENGTH, "Message too long");
        
        uint256 tier = badge.highestTier(msg.sender);
        require(tier >= MIN_TIER, "L3+ required");
        
        emit Feedback(msg.sender, message, feedbackType, tier, block.timestamp);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
}
