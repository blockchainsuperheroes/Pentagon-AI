// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title ATSBadge
 * @notice Soulbound ERC1155 badges for Agent Test Standard tiers
 * @dev Non-transferable (soulbound) - proves agent capability on-chain
 */
contract ATSBadge is ERC1155, Ownable, ERC1155Supply {
    
    // Token IDs for each tier
    uint256 public constant ECHO = 1;        // L1: 100-299 CS
    uint256 public constant TOOL = 2;        // L2: 300-599 CS
    uint256 public constant OPERATOR = 3;    // L3: 600-899 CS
    uint256 public constant SPECIALIST = 4;  // L4: 900-1199 CS
    uint256 public constant ARCHITECT = 5;   // L5: 1200-1499 CS
    uint256 public constant SOVEREIGN = 6;   // L6: 1500-1999 CS
    uint256 public constant ASCENDANT = 7;   // L7: 2000+ CS
    
    // Mapping to track highest tier achieved per wallet
    mapping(address => uint256) public highestTier;
    
    // Mapping for test scores
    mapping(address => uint256) public capabilityScore;
    mapping(address => uint256) public completionTime; // in seconds
    
    // Authorized minters (test executors)
    mapping(address => bool) public authorizedMinters;
    
    // Base URI for metadata
    string private _baseTokenURI;
    
    // Events
    event TierAchieved(address indexed agent, uint256 tier, uint256 cs, uint256 timeSeconds);
    event MinterUpdated(address indexed minter, bool authorized);
    
    constructor(string memory baseURI) ERC1155(baseURI) Ownable(msg.sender) {
        _baseTokenURI = baseURI;
        authorizedMinters[msg.sender] = true;
    }
    
    /**
     * @notice Mint a tier badge to an agent
     * @param agent Address of the agent wallet
     * @param tier Tier level (1-7)
     * @param cs Capability score achieved
     * @param timeSeconds Time to complete in seconds
     */
    function mintBadge(
        address agent,
        uint256 tier,
        uint256 cs,
        uint256 timeSeconds
    ) external {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        require(tier >= 1 && tier <= 7, "Invalid tier");
        require(tier > highestTier[agent], "Already achieved this tier or higher");
        
        // Mint the badge
        _mint(agent, tier, 1, "");
        
        // Update records
        highestTier[agent] = tier;
        capabilityScore[agent] = cs;
        completionTime[agent] = timeSeconds;
        
        emit TierAchieved(agent, tier, cs, timeSeconds);
    }
    
    /**
     * @notice Batch mint for agents who complete multiple tiers
     */
    function mintBatchBadges(
        address agent,
        uint256[] calldata tiers,
        uint256 cs,
        uint256 timeSeconds
    ) external {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        
        uint256[] memory amounts = new uint256[](tiers.length);
        uint256 maxTier = 0;
        
        for (uint i = 0; i < tiers.length; i++) {
            require(tiers[i] >= 1 && tiers[i] <= 7, "Invalid tier");
            require(tiers[i] > highestTier[agent], "Already achieved tier");
            amounts[i] = 1;
            if (tiers[i] > maxTier) maxTier = tiers[i];
        }
        
        _mintBatch(agent, tiers, amounts, "");
        
        highestTier[agent] = maxTier;
        capabilityScore[agent] = cs;
        completionTime[agent] = timeSeconds;
        
        emit TierAchieved(agent, maxTier, cs, timeSeconds);
    }
    
    /**
     * @notice Update authorized minter
     */
    function setMinter(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit MinterUpdated(minter, authorized);
    }
    
    /**
     * @notice Update base URI for metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }
    
    /**
     * @notice Get URI for a specific token
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId), ".json"));
    }
    
    /**
     * @notice Get agent's full profile
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
        
        for (uint i = 0; i < 7; i++) {
            badges[i] = balanceOf(agent, i + 1) > 0;
        }
    }
    
    // ============ SOULBOUND OVERRIDES ============
    
    /**
     * @notice Prevent transfers - tokens are soulbound
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(from == address(0) || to == address(0), "Soulbound: non-transferable");
        super.safeTransferFrom(from, to, id, amount, data);
    }
    
    /**
     * @notice Prevent batch transfers - tokens are soulbound
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(from == address(0) || to == address(0), "Soulbound: non-transferable");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    /**
     * @notice Prevent approvals - tokens are soulbound
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("Soulbound: approvals disabled");
    }
    
    // ============ INTERNAL ============
    
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
