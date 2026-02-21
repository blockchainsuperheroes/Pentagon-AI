// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";

/**
 * @title ATSBadge
 * @notice Soulbound ERC1155 badges for Agent Test Standard tiers
 * @dev Based on GCNShards - Non-transferable (soulbound) badges proving agent capability
 * 
 * Token IDs:
 *   1 = Echo (L1)      - "Can follow orders"
 *   2 = Tool (L2)      - "Can use tools"
 *   3 = Operator (L3)  - "Can think before acting"
 *   4 = Specialist (L4) - "Can survive in the wild"
 *   5 = Architect (L5) - "Builds its own plan"
 *   6 = Sovereign (L6) - "Self-sustaining economy"
 *   7 = Ascendant (L7) - "The test-taker becomes the test-maker"
 */
contract ATSBadge is ERC1155, BasicAccessControl {
    
    // Tier constants for readability
    uint256 public constant ECHO = 1;
    uint256 public constant TOOL = 2;
    uint256 public constant OPERATOR = 3;
    uint256 public constant SPECIALIST = 4;
    uint256 public constant ARCHITECT = 5;
    uint256 public constant SOVEREIGN = 6;
    uint256 public constant ASCENDANT = 7;
    
    // Track highest tier per agent
    mapping(address => uint256) public highestTier;
    
    // Track test completion data
    mapping(address => uint256) public capabilityScore;
    mapping(address => uint256) public completionTime;
    
    // Events
    event TierAchieved(address indexed agent, uint256 tier, uint256 cs, uint256 timeSeconds);
    
    constructor() ERC1155("https://raw.githubusercontent.com/blockchainsuperheroes/ats/main/metadata/{id}.json") {}
    
    /**
     * @dev Updates the base URI for the token metadata. Restricted to the owner.
     */
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }
    
    /**
     * @dev Mint a tier badge to an agent. Restricted to moderators.
     * @param to The agent's wallet address
     * @param tier The tier level (1-7)
     * @param cs Capability score achieved
     * @param timeSeconds Time to complete in seconds
     */
    function mintBadge(
        address to,
        uint256 tier,
        uint256 cs,
        uint256 timeSeconds
    ) external onlyModerators {
        require(tier >= 1 && tier <= 7, "ATS: Invalid tier");
        require(tier > highestTier[to], "ATS: Already achieved this tier or higher");
        
        _mint(to, tier, 1, "");
        
        highestTier[to] = tier;
        capabilityScore[to] = cs;
        completionTime[to] = timeSeconds;
        
        emit TierAchieved(to, tier, cs, timeSeconds);
    }
    
    /**
     * @dev Batch mint multiple tier badges (for agents who pass multiple tiers at once)
     */
    function mintBatchBadges(
        address to,
        uint256[] memory tiers,
        uint256 cs,
        uint256 timeSeconds
    ) external onlyModerators {
        uint256 maxTier = 0;
        uint256[] memory amounts = new uint256[](tiers.length);
        
        for (uint256 i = 0; i < tiers.length; i++) {
            require(tiers[i] >= 1 && tiers[i] <= 7, "ATS: Invalid tier");
            require(tiers[i] > highestTier[to], "ATS: Already achieved tier");
            amounts[i] = 1;
            if (tiers[i] > maxTier) maxTier = tiers[i];
        }
        
        _mintBatch(to, tiers, amounts, "");
        
        highestTier[to] = maxTier;
        capabilityScore[to] = cs;
        completionTime[to] = timeSeconds;
        
        emit TierAchieved(to, maxTier, cs, timeSeconds);
    }
    
    /**
     * @dev Legacy mint function for compatibility
     */
    function mint(
        address to,
        uint256 designId,
        uint256 amount
    ) external onlyModerators {
        require(designId >= 1 && designId <= 7, "ATS: Invalid tier");
        _mint(to, designId, amount, "");
        if (designId > highestTier[to]) {
            highestTier[to] = designId;
        }
    }
    
    /**
     * @dev Burn badges (for re-testing or corrections)
     */
    function burn(
        address from,
        uint256 tier,
        uint256 amount
    ) external onlyModerators {
        _burn(from, tier, amount);
    }
    
    /**
     * @dev Get agent's full profile
     */
    function getAgentProfile(address agent) external view returns (
        uint256 tier,
        uint256 cs,
        uint256 time,
        bool[7] memory badges
    ) {
        tier = highestTier[agent];
        cs = capabilityScore[agent];
        time = completionTime[agent];
        
        for (uint256 i = 0; i < 7; i++) {
            badges[i] = balanceOf(agent, i + 1) > 0;
        }
    }
    
    /**
     * @dev Overrides the ERC-1155 hook to enforce non-transferability.
     * Allows minting (from address(0)) and burning (to address(0)).
     * Reverts on any other transfer attempt.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "ATS: Soulbound - non-transferable"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
