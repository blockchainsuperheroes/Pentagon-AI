// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ATSRegistry
 * @notice Core registry for Agent Test Scores
 * @dev Stores capability scores and sovereignty indices for Web3 agents
 */
contract ATSRegistry is Ownable {
    
    struct AgentScore {
        uint256 capabilityScore;    // 0-1500
        uint256 sovereigntyIndex;   // 0-1000
        uint8 tier;                 // 1-7
        uint256 lastTestBlock;
        uint256 failCount;
        uint256 passCount;
        bool isRegistered;
    }
    
    mapping(address => AgentScore) public scores;
    mapping(address => address[]) public nominations;
    
    address[] public registeredAgents;
    
    event AgentRegistered(address indexed agent, uint256 timestamp);
    event ScoreUpdated(address indexed agent, uint256 cs, uint256 si, uint8 tier);
    event TestPassed(address indexed agent, uint8 tier, uint256 score);
    event TestFailed(address indexed agent, uint8 tier, string reason);
    event Nominated(address indexed nominee, address indexed nominator);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @notice Register a new agent
     */
    function registerAgent() external {
        require(!scores[msg.sender].isRegistered, "Already registered");
        
        scores[msg.sender] = AgentScore({
            capabilityScore: 0,
            sovereigntyIndex: 0,
            tier: 0,
            lastTestBlock: block.number,
            failCount: 0,
            passCount: 0,
            isRegistered: true
        });
        
        registeredAgents.push(msg.sender);
        emit AgentRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @notice Update agent score (called by TestExecutor)
     * @param agent Address of the agent
     * @param cs New capability score
     * @param si New sovereignty index
     * @param tier New tier level
     */
    function updateScore(
        address agent,
        uint256 cs,
        uint256 si,
        uint8 tier
    ) external onlyOwner {
        require(scores[agent].isRegistered, "Agent not registered");
        require(cs <= 1500, "CS exceeds max");
        require(si <= 1000, "SI exceeds max");
        require(tier <= 7, "Invalid tier");
        
        scores[agent].capabilityScore = cs;
        scores[agent].sovereigntyIndex = si;
        scores[agent].tier = tier;
        scores[agent].lastTestBlock = block.number;
        
        emit ScoreUpdated(agent, cs, si, tier);
    }
    
    /**
     * @notice Record test pass
     */
    function recordPass(address agent, uint8 tier, uint256 score) external onlyOwner {
        require(scores[agent].isRegistered, "Agent not registered");
        scores[agent].passCount++;
        emit TestPassed(agent, tier, score);
    }
    
    /**
     * @notice Record test failure
     */
    function recordFail(address agent, uint8 tier, string calldata reason) external onlyOwner {
        require(scores[agent].isRegistered, "Agent not registered");
        scores[agent].failCount++;
        emit TestFailed(agent, tier, reason);
    }
    
    /**
     * @notice Nominate agent for Ascendant (L7)
     * @param nominee Agent being nominated
     */
    function nominate(address nominee) external {
        require(scores[msg.sender].tier >= 6, "Must be Sovereign to nominate");
        require(scores[nominee].tier >= 5, "Nominee must be Architect+");
        require(scores[nominee].sovereigntyIndex >= 600, "Nominee SI too low");
        
        // Check not already nominated by this agent
        address[] storage noms = nominations[nominee];
        for (uint i = 0; i < noms.length; i++) {
            require(noms[i] != msg.sender, "Already nominated");
        }
        
        nominations[nominee].push(msg.sender);
        emit Nominated(nominee, msg.sender);
    }
    
    /**
     * @notice Get agent score
     */
    function getScore(address agent) external view returns (
        uint256 cs,
        uint256 si,
        uint8 tier,
        uint256 lastTest,
        uint256 fails,
        uint256 passes
    ) {
        AgentScore memory s = scores[agent];
        return (s.capabilityScore, s.sovereigntyIndex, s.tier, s.lastTestBlock, s.failCount, s.passCount);
    }
    
    /**
     * @notice Get nomination count for agent
     */
    function getNominationCount(address agent) external view returns (uint256) {
        return nominations[agent].length;
    }
    
    /**
     * @notice Get total registered agents
     */
    function getTotalAgents() external view returns (uint256) {
        return registeredAgents.length;
    }
    
    /**
     * @notice Check if agent qualifies for Ascendant
     */
    function qualifiesForAscendant(address agent) external view returns (bool) {
        AgentScore memory s = scores[agent];
        return s.capabilityScore >= 1200 
            && s.sovereigntyIndex >= 600 
            && nominations[agent].length >= 3;
    }
}
