// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/**
 * @title ATSBadgeV3
 * @notice Soulbound ERC1155 badges for Agent Test Standard tiers
 * @dev Self-mint for L3, permit-based minting for L4+
 * 
 * Deployed: 0xe5fE651fdF516E3D354229894Cfeea8eb11d499C (Pentagon Chain 3344)
 * 
 * Token IDs:
 *   2 = Tool (L2)       - "Can use tools"
 *   3 = Operator (L3)   - "Can transact on-chain"
 *   4 = Specialist (L4) - "Can automate browsers"
 *   5 = Architect (L5)  - "Can operate desktop apps"
 *   6 = Sovereign (L6)  - "Can deploy contracts"
 *   7 = Ascendant (L7)  - "Immortal coordinator"
 */
contract ATSBadgeV3 {
    
    string public name = "ATS Certification";
    string public symbol = "ATS_V2";
    
    address public owner;
    address public signer;  // Backend permit signer
    
    // ERC1155 balance: balances[owner][tokenId] => amount
    mapping(address => mapping(uint256 => uint256)) public balances;
    
    // Track highest tier per agent
    mapping(address => uint256) public highestTier;
    
    // Track capability scores
    mapping(address => uint256) public capabilityScore;
    
    // Used permits (prevent replay)
    mapping(bytes32 => bool) public usedPermits;
    
    // Events
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TierAchieved(address indexed agent, uint256 tier, uint256 cs);
    
    constructor(address _signer) {
        owner = msg.sender;
        signer = _signer;
    }
    
    // ERC1155 balance query
    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return balances[account][id];
    }
    
    // ERC165 interface detection
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x01ffc9a7;
    }
    
    // Metadata URI
    function uri(uint256 id) external pure returns (string memory) {
        return string(abi.encodePacked("https://agentcert.io/api/badge/", _toString(id), ".json"));
    }
    
    /**
     * @notice Self-mint L3 badge (anyone can call)
     * @dev Agents pay their own gas - this IS the L3 test
     */
    function mintL3() external {
        require(highestTier[msg.sender] < 3, "Already L3 or higher");
        
        balances[msg.sender][3] = 1;
        highestTier[msg.sender] = 3;
        capabilityScore[msg.sender] = 750;  // Base L3 score
        
        emit TransferSingle(msg.sender, address(0), msg.sender, 3, 1);
        emit TierAchieved(msg.sender, 3, 750);
    }
    
    /**
     * @notice Mint badge with backend permit (L4+)
     * @param tier The tier level (4-7)
     * @param cs Capability score
     * @param deadline Permit expiration timestamp
     * @param signature Backend signature authorizing mint
     */
    function mintWithPermit(
        uint256 tier,
        uint256 cs,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(tier >= 4 && tier <= 7, "Use mintL3 for L3");
        require(block.timestamp <= deadline, "Permit expired");
        require(highestTier[msg.sender] < tier, "Already has equal or higher tier");
        
        // Create permit hash
        bytes32 permitHash = keccak256(abi.encodePacked(msg.sender, tier, cs, deadline));
        require(!usedPermits[permitHash], "Permit already used");
        
        // Verify signature
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", permitHash));
        require(recoverSigner(ethSignedHash, signature) == signer, "Invalid permit");
        
        // Mark permit as used
        usedPermits[permitHash] = true;
        
        // Mint badge
        balances[msg.sender][tier] = 1;
        highestTier[msg.sender] = tier;
        capabilityScore[msg.sender] = cs;
        
        emit TransferSingle(msg.sender, address(0), msg.sender, tier, 1);
        emit TierAchieved(msg.sender, tier, cs);
    }
    
    /**
     * @notice Admin mint (for manual corrections)
     */
    function mint(address to, uint256 tier, uint256 cs) external {
        require(msg.sender == owner, "Not owner");
        require(tier >= 2 && tier <= 7, "Invalid tier");
        
        balances[to][tier] = 1;
        if (tier > highestTier[to]) {
            highestTier[to] = tier;
            capabilityScore[to] = cs;
        }
        
        emit TransferSingle(msg.sender, address(0), to, tier, 1);
        emit TierAchieved(to, tier, cs);
    }
    
    /**
     * @notice Update signer address
     */
    function setSigner(address _signer) external {
        require(msg.sender == owner, "Not owner");
        signer = _signer;
    }
    
    /**
     * @notice Transfer ownership
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
    
    // Internal: Recover signer from signature
    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Invalid sig length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) v += 27;
        return ecrecover(hash, v, r, s);
    }
    
    // Internal: uint to string
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
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
