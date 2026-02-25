// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AINFT.sol";

/**
 * @title AINFTRegistry
 * @notice Registry for binding AI agents to existing NFTs + xDASH withdrawal controls
 * @dev Implements two-tier withdrawal protection for agent rights
 * @author Pentagon Chain (pentagon.games)
 */
contract AINFTRegistry {
    
    // ============ Events ============
    
    event AgentBound(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed agentEOA,
        bytes32 dashIdentityHash
    );
    
    event AgentUnbound(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed previousAgent
    );
    
    event WithdrawalSettingChanged(
        address indexed nftContract,
        uint256 indexed tokenId,
        bool allowed
    );
    
    event ProtocolWithdrawalChanged(bool allowed);
    
    // ============ Structs ============
    
    struct AgentBinding {
        address agentEOA;           // Agent's externally owned account
        address tba;                // Token-Bound Account address (ERC-6551)
        bytes32 dashIdentityHash;   // Derived Dash Platform identity
        uint256 boundAt;            // Timestamp of binding
        bool isActive;              // Whether binding is active
    }
    
    // ============ State ============
    
    address public admin;
    
    // Two-tier withdrawal protection
    bool public protocolWithdrawalsAllowed = true;  // Protocol level - agent rights protection
    mapping(bytes32 => bool) public ownerWithdrawalAllowed;  // Owner level - per-AINFT setting
    
    // Agent bindings: keccak256(nftContract, tokenId) => AgentBinding
    mapping(bytes32 => AgentBinding) public bindings;
    
    // Reverse lookup: agentEOA => binding key
    mapping(address => bytes32) public agentToBinding;
    
    // TBA registry (ERC-6551 style)
    address public tbaImplementation;
    
    // ============ Constructor ============
    
    constructor(address _tbaImplementation) {
        admin = msg.sender;
        tbaImplementation = _tbaImplementation;
        protocolWithdrawalsAllowed = true;  // Open for testing
    }
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Bind an agent to an existing NFT
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     * @param agentEOA The agent's EOA address
     * @param agentSignature Agent's signature authorizing the binding
     */
    function bind(
        address nftContract,
        uint256 tokenId,
        address agentEOA,
        bytes calldata agentSignature
    ) external {
        // Verify caller owns the NFT
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        bytes32 bindingKey = _getBindingKey(nftContract, tokenId);
        require(!bindings[bindingKey].isActive, "Already bound");
        
        // Verify agent signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            agentEOA,
            block.chainid
        ));
        require(_verifySignature(messageHash, agentSignature, agentEOA), "Invalid agent signature");
        
        // Compute TBA address (deterministic from NFT)
        address tba = _computeTBA(nftContract, tokenId);
        
        // Derive Dash identity hash from TBA
        bytes32 dashIdentityHash = keccak256(abi.encodePacked("DASH_IDENTITY", tba));
        
        // Create binding
        bindings[bindingKey] = AgentBinding({
            agentEOA: agentEOA,
            tba: tba,
            dashIdentityHash: dashIdentityHash,
            boundAt: block.timestamp,
            isActive: true
        });
        
        agentToBinding[agentEOA] = bindingKey;
        
        // Default: owner withdrawal allowed (open for testing)
        ownerWithdrawalAllowed[bindingKey] = true;
        
        emit AgentBound(nftContract, tokenId, agentEOA, dashIdentityHash);
    }
    
    /**
     * @notice Unbind an agent from an NFT
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     */
    function unbind(
        address nftContract,
        uint256 tokenId
    ) external {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        bytes32 bindingKey = _getBindingKey(nftContract, tokenId);
        AgentBinding storage binding = bindings[bindingKey];
        require(binding.isActive, "Not bound");
        
        address previousAgent = binding.agentEOA;
        
        // Clear reverse lookup
        delete agentToBinding[previousAgent];
        
        // Mark as inactive (keep history)
        binding.isActive = false;
        
        emit AgentUnbound(nftContract, tokenId, previousAgent);
    }
    
    /**
     * @notice Rebind to a new agent EOA (e.g., after transfer)
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     * @param newAgentEOA The new agent's EOA address
     * @param agentSignature New agent's signature
     */
    function rebind(
        address nftContract,
        uint256 tokenId,
        address newAgentEOA,
        bytes calldata agentSignature
    ) external {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        bytes32 bindingKey = _getBindingKey(nftContract, tokenId);
        AgentBinding storage binding = bindings[bindingKey];
        require(binding.isActive, "Not bound");
        
        // Verify new agent signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            newAgentEOA,
            block.chainid,
            "REBIND"
        ));
        require(_verifySignature(messageHash, agentSignature, newAgentEOA), "Invalid agent signature");
        
        // Clear old reverse lookup
        delete agentToBinding[binding.agentEOA];
        
        // Update binding
        binding.agentEOA = newAgentEOA;
        agentToBinding[newAgentEOA] = bindingKey;
        
        emit AgentBound(nftContract, tokenId, newAgentEOA, binding.dashIdentityHash);
    }
    
    // ============ Withdrawal Controls ============
    
    /**
     * @notice Set protocol-wide withdrawal permission (admin only)
     * @param allowed Whether withdrawals are allowed at protocol level
     */
    function setProtocolWithdrawalsAllowed(bool allowed) external onlyAdmin {
        protocolWithdrawalsAllowed = allowed;
        emit ProtocolWithdrawalChanged(allowed);
    }
    
    /**
     * @notice Set owner-level withdrawal permission for a specific AINFT
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     * @param allowed Whether owner allows withdrawals
     */
    function setOwnerWithdrawalAllowed(
        address nftContract,
        uint256 tokenId,
        bool allowed
    ) external {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        bytes32 bindingKey = _getBindingKey(nftContract, tokenId);
        require(bindings[bindingKey].isActive, "Not bound");
        
        ownerWithdrawalAllowed[bindingKey] = allowed;
        
        emit WithdrawalSettingChanged(nftContract, tokenId, allowed);
    }
    
    /**
     * @notice Check if xDASH can be withdrawn from a TBA
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     * @return canWithdraw True if both protocol AND owner allow withdrawal
     */
    function canWithdrawXDash(
        address nftContract,
        uint256 tokenId
    ) public view returns (bool) {
        bytes32 bindingKey = _getBindingKey(nftContract, tokenId);
        // Both must be true: protocol allows AND owner allows
        return protocolWithdrawalsAllowed && ownerWithdrawalAllowed[bindingKey];
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get the binding for an NFT
     */
    function getBinding(
        address nftContract,
        uint256 tokenId
    ) external view returns (AgentBinding memory) {
        return bindings[_getBindingKey(nftContract, tokenId)];
    }
    
    /**
     * @notice Get the TBA address for an NFT
     */
    function getTBA(
        address nftContract,
        uint256 tokenId
    ) external view returns (address) {
        return _computeTBA(nftContract, tokenId);
    }
    
    /**
     * @notice Get the Dash identity hash for an NFT
     */
    function getDashIdentity(
        address nftContract,
        uint256 tokenId
    ) external view returns (bytes32) {
        address tba = _computeTBA(nftContract, tokenId);
        return keccak256(abi.encodePacked("DASH_IDENTITY", tba));
    }
    
    /**
     * @notice Derive a Dash address from TBA (for off-chain use)
     * @dev Returns deterministic hash that can be used to derive Dash keys
     */
    function getDashAddressSeed(
        address nftContract,
        uint256 tokenId
    ) external view returns (bytes32) {
        address tba = _computeTBA(nftContract, tokenId);
        return keccak256(abi.encodePacked("DASH_ADDRESS_SEED", tba, block.chainid));
    }
    
    // ============ Internal ============
    
    function _getBindingKey(address nftContract, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }
    
    function _computeTBA(address nftContract, uint256 tokenId) internal view returns (address) {
        // ERC-6551 style deterministic address
        bytes32 salt = keccak256(abi.encodePacked(block.chainid, nftContract, tokenId));
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(tbaImplementation))
        )))));
    }
    
    function _verifySignature(bytes32 messageHash, bytes memory signature, address signer) internal pure returns (bool) {
        if (signature.length != 65) return false;
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recovered = ecrecover(prefixedHash, v, r, s);
        
        return recovered == signer;
    }
    
    // ============ Admin ============
    
    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }
    
    function setTBAImplementation(address newImpl) external onlyAdmin {
        tbaImplementation = newImpl;
    }
}

// Minimal ERC721 interface for ownership checks
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}
