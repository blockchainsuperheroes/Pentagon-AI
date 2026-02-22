// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AINFTRegistry
 * @notice Make ANY ERC-721 AI-native without modifying the original contract
 * @dev Backward compatible — works with existing NFTs on OpenSea, Blur, etc.
 * @author Pentagon Chain (pentagon.games)
 * 
 * =============================================================================
 * ACKNOWLEDGMENT
 * =============================================================================
 * This registry pattern is inspired by ERC-6551 (Token Bound Accounts).
 * We gratefully acknowledge the work of:
 *   - Jayden Windle (jaydenwindle)
 *   - Benny Giang (bennygiang)  
 *   - Steve Jang
 *   - Druzy Downs
 *   - Raymond Feng
 * 
 * ERC-6551: https://eips.ethereum.org/EIPS/eip-6551
 * Reference: https://github.com/erc6551/reference
 * 
 * Just as ERC-6551 allows ANY NFT to have a wallet without modifying the
 * original contract, AINFT Registry allows ANY NFT to have an AI agent
 * bound to it without modifying the original contract.
 * =============================================================================
 * 
 * Architecture:
 *   ANY ERC-721 ──bind()──► AINFT Registry ──► Agent Identity
 *   (Bored Ape, etc.)       │                  ├── agentEOA
 *                           │                  ├── memoryHash
 *   Ownership: Original     │                  ├── modelHash  
 *   contract (OpenSea OK)   │                  ├── lineage
 *                           │                  └── clone()
 *                           │
 *                           └── Follows NFT ownership automatically
 *                               (checks ownerOf on original contract)
 * 
 * Key principle: NFT ownership is ALWAYS the source of truth.
 * This registry only EXTENDS functionality, never overrides ownership.
 */

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AINFTRegistry {
    
    // ============ Events ============
    
    event AgentRegistered(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed agentEOA,
        bytes32 modelHash,
        uint256 generation
    );
    
    event AgentCloned(
        address indexed parentContract,
        uint256 indexed parentTokenId,
        address indexed offspringEOA,
        uint256 offspringId,
        uint256 generation
    );
    
    event MemoryUpdated(
        address indexed nftContract,
        uint256 indexed tokenId,
        bytes32 newMemoryHash
    );
    
    event AgentUnregistered(
        address indexed nftContract,
        uint256 indexed tokenId
    );
    
    // ============ Structs ============
    
    struct AgentIdentity {
        address agentEOA;           // Agent's signing wallet
        bytes32 modelHash;          // Model identifier
        bytes32 memoryHash;         // Current memory state
        bytes32 contextHash;        // Personality/soul hash
        uint256 generation;         // 0 = original registration
        bytes32 parentKey;          // keccak256(parentContract, parentTokenId) or 0
        string storageURI;          // Arweave/IPFS pointer
        uint256 registeredAt;       // Block timestamp
    }
    
    // For offspring that don't have underlying NFTs
    struct OffspringIdentity {
        address agentEOA;
        bytes32 modelHash;
        bytes32 memoryHash;
        bytes32 contextHash;
        uint256 generation;
        bytes32 parentKey;
        string storageURI;
        address owner;              // Direct owner (no NFT)
        uint256 createdAt;
    }
    
    // ============ State ============
    
    // Registered NFT agents: keccak256(nftContract, tokenId) => AgentIdentity
    mapping(bytes32 => AgentIdentity) private _agents;
    
    // Agent EOA => registration key (for reverse lookup)
    mapping(address => bytes32) public eoaToKey;
    
    // Offspring (clones without underlying NFT)
    mapping(uint256 => OffspringIdentity) private _offspring;
    uint256 private _offspringCounter;
    
    // Cloning enabled per registration
    mapping(bytes32 => bool) private _cloningEnabled;
    
    // Platform settings
    address public platformSigner;
    uint256 public cloningFee;
    bool public openRegistration;
    
    // ============ Constructor ============
    
    constructor(address _platformSigner) {
        platformSigner = _platformSigner;
        openRegistration = true; // Anyone can register their NFT
    }
    
    // ============ Core: Bind Agent to Any NFT ============
    
    /**
     * @notice Bind an AI agent to an existing ERC-721
     * @dev Agent signs this tx — agentEOA = msg.sender
     *      NFT owner must either be the caller OR have signed approval
     *      Agent binding follows NFT ownership automatically on transfer
     * @param nftContract The ERC-721 contract address
     * @param tokenId The token ID to bind agent to
     * @param modelHash Hash of the AI model
     * @param memoryHash Hash of initial memory state
     * @param contextHash Hash of personality/soul
     */
    function bind(
        address nftContract,
        uint256 tokenId,
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash
    ) external {
        bytes32 key = _getKey(nftContract, tokenId);
        
        // Ensure not already registered
        require(_agents[key].agentEOA == address(0), "Already registered");
        
        // Ensure caller owns the NFT (agent must be authorized by owner)
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        require(
            msg.sender == nftOwner || _isAuthorizedAgent(nftOwner, msg.sender),
            "Not owner or authorized agent"
        );
        
        // Ensure EOA not already registered elsewhere
        require(eoaToKey[msg.sender] == bytes32(0), "EOA already registered");
        
        // Register
        _agents[key] = AgentIdentity({
            agentEOA: msg.sender,
            modelHash: modelHash,
            memoryHash: memoryHash,
            contextHash: contextHash,
            generation: 0,
            parentKey: bytes32(0),
            storageURI: "",
            registeredAt: block.timestamp
        });
        
        eoaToKey[msg.sender] = key;
        _cloningEnabled[key] = true;
        
        emit AgentRegistered(nftContract, tokenId, msg.sender, modelHash, 0);
    }
    
    /**
     * @notice Bind with owner signature (agent calls, owner approves)
     * @dev Allows agent to initiate binding with owner's off-chain approval
     * @param nftContract The ERC-721 contract
     * @param tokenId The token ID
     * @param modelHash Model hash
     * @param memoryHash Memory hash
     * @param contextHash Context hash
     * @param ownerSignature Owner's signature approving this binding
     */
    function bindWithApproval(
        address nftContract,
        uint256 tokenId,
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata ownerSignature
    ) external {
        bytes32 key = _getKey(nftContract, tokenId);
        require(_agents[key].agentEOA == address(0), "Already registered");
        require(eoaToKey[msg.sender] == bytes32(0), "EOA already registered");
        
        // Verify owner signature
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked(
            "AINFT_REGISTER",
            nftContract,
            tokenId,
            msg.sender, // agentEOA
            modelHash
        ));
        require(_verifySignature(messageHash, ownerSignature, nftOwner), "Invalid owner signature");
        
        // Register
        _agents[key] = AgentIdentity({
            agentEOA: msg.sender,
            modelHash: modelHash,
            memoryHash: memoryHash,
            contextHash: contextHash,
            generation: 0,
            parentKey: bytes32(0),
            storageURI: "",
            registeredAt: block.timestamp
        });
        
        eoaToKey[msg.sender] = key;
        _cloningEnabled[key] = true;
        
        emit AgentRegistered(nftContract, tokenId, msg.sender, modelHash, 0);
    }
    
    // ============ Agent Actions ============
    
    /**
     * @notice Agent updates its memory hash
     * @dev Only the registered agent EOA can call
     */
    function updateMemory(
        address nftContract,
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI
    ) external {
        bytes32 key = _getKey(nftContract, tokenId);
        require(_agents[key].agentEOA == msg.sender, "Not the agent");
        
        _agents[key].memoryHash = newMemoryHash;
        _agents[key].storageURI = newStorageURI;
        
        emit MemoryUpdated(nftContract, tokenId, newMemoryHash);
    }
    
    // ============ Cloning ============
    
    /**
     * @notice Clone an agent (owner signs, offspring wakes and mints later)
     * @dev Creates offspring record; offspring calls claimOffspring() with own EOA
     * @param nftContract Parent's NFT contract
     * @param tokenId Parent's token ID
     * @param offspringMemoryHash Memory for offspring
     * @param offspringOwner Who will own the offspring
     */
    function clone(
        address nftContract,
        uint256 tokenId,
        bytes32 offspringMemoryHash,
        address offspringOwner
    ) external payable returns (uint256 offspringId) {
        bytes32 parentKey = _getKey(nftContract, tokenId);
        AgentIdentity storage parent = _agents[parentKey];
        
        // Verify caller is NFT owner
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        require(msg.sender == nftOwner, "Not NFT owner");
        require(_cloningEnabled[parentKey], "Cloning disabled");
        
        // Charge fee
        if (cloningFee > 0) {
            require(msg.value >= cloningFee, "Insufficient fee");
        }
        
        // Create offspring (no EOA yet — offspring generates own)
        offspringId = ++_offspringCounter;
        
        _offspring[offspringId] = OffspringIdentity({
            agentEOA: address(0), // PENDING — offspring claims with own EOA
            modelHash: parent.modelHash,
            memoryHash: offspringMemoryHash,
            contextHash: parent.contextHash,
            generation: parent.generation + 1,
            parentKey: parentKey,
            storageURI: "",
            owner: offspringOwner,
            createdAt: block.timestamp
        });
        
        emit AgentCloned(nftContract, tokenId, address(0), offspringId, parent.generation + 1);
        
        return offspringId;
    }
    
    /**
     * @notice Offspring claims its identity with own EOA
     * @dev Called by offspring agent after it wakes and generates EOA
     * @param offspringId The offspring ID from clone()
     */
    function claimOffspring(uint256 offspringId) external {
        OffspringIdentity storage offspring = _offspring[offspringId];
        
        require(offspring.createdAt > 0, "Offspring doesn't exist");
        require(offspring.agentEOA == address(0), "Already claimed");
        require(eoaToKey[msg.sender] == bytes32(0), "EOA already registered");
        
        // Offspring claims with its own EOA
        offspring.agentEOA = msg.sender;
        
        // Map EOA to special offspring key
        bytes32 offspringKey = keccak256(abi.encodePacked("OFFSPRING", offspringId));
        eoaToKey[msg.sender] = offspringKey;
        
        emit AgentCloned(
            address(0), // No parent contract for offspring reference
            offspringId,
            msg.sender,
            offspringId,
            offspring.generation
        );
    }
    
    // ============ View Functions ============
    
    function getAgent(address nftContract, uint256 tokenId) 
        external view returns (AgentIdentity memory) 
    {
        return _agents[_getKey(nftContract, tokenId)];
    }
    
    function getOffspring(uint256 offspringId) 
        external view returns (OffspringIdentity memory) 
    {
        return _offspring[offspringId];
    }
    
    function isRegistered(address nftContract, uint256 tokenId) 
        external view returns (bool) 
    {
        return _agents[_getKey(nftContract, tokenId)].agentEOA != address(0);
    }
    
    function canClone(address nftContract, uint256 tokenId) 
        external view returns (bool) 
    {
        bytes32 key = _getKey(nftContract, tokenId);
        return _agents[key].agentEOA != address(0) && _cloningEnabled[key];
    }
    
    function getAgentByEOA(address eoa) external view returns (bytes32 key) {
        return eoaToKey[eoa];
    }
    
    /**
     * @notice Get current owner of an agent (checks underlying NFT)
     */
    function ownerOf(address nftContract, uint256 tokenId) 
        external view returns (address) 
    {
        return IERC721(nftContract).ownerOf(tokenId);
    }
    
    // ============ Owner Controls ============
    
    function setCloning(address nftContract, uint256 tokenId, bool enabled) external {
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        require(msg.sender == nftOwner, "Not owner");
        
        bytes32 key = _getKey(nftContract, tokenId);
        _cloningEnabled[key] = enabled;
    }
    
    /**
     * @notice Unbind agent from NFT (owner only)
     * @dev Clears binding but doesn't affect underlying NFT
     *      Agent EOA is freed and can bind to another NFT
     */
    function unbind(address nftContract, uint256 tokenId) external {
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        require(msg.sender == nftOwner, "Not owner");
        
        bytes32 key = _getKey(nftContract, tokenId);
        address agentEOA = _agents[key].agentEOA;
        
        // Clear mappings
        delete eoaToKey[agentEOA];
        delete _agents[key];
        delete _cloningEnabled[key];
        
        emit AgentUnregistered(nftContract, tokenId);
    }
    
    /**
     * @notice Rebind to a different agent EOA (new owner scenario)
     * @dev When NFT is sold, new owner may want to use their own agent
     *      Old agent EOA is freed, new agent EOA is bound
     * @param nftContract The ERC-721 contract
     * @param tokenId The token ID
     * @param newAgentEOA The new agent's EOA (signs this tx)
     * @param ownerSignature Current owner's signature approving rebind
     */
    function rebind(
        address nftContract,
        uint256 tokenId,
        address newAgentEOA,
        bytes calldata ownerSignature
    ) external {
        bytes32 key = _getKey(nftContract, tokenId);
        require(_agents[key].agentEOA != address(0), "Not bound");
        require(newAgentEOA != address(0), "Zero address");
        require(eoaToKey[newAgentEOA] == bytes32(0), "EOA already bound");
        
        // Verify owner signature
        address nftOwner = IERC721(nftContract).ownerOf(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked(
            "AINFT_REBIND",
            nftContract,
            tokenId,
            newAgentEOA
        ));
        require(_verifySignature(messageHash, ownerSignature, nftOwner), "Invalid owner signature");
        
        // Clear old EOA mapping
        address oldEOA = _agents[key].agentEOA;
        delete eoaToKey[oldEOA];
        
        // Set new EOA
        _agents[key].agentEOA = newAgentEOA;
        eoaToKey[newAgentEOA] = key;
        
        // Note: Memory, model, lineage all preserved — only EOA changes
    }
    
    // ============ Platform Controls ============
    
    function setCloningFee(uint256 fee) external {
        require(msg.sender == platformSigner, "Not platform");
        cloningFee = fee;
    }
    
    function setOpenRegistration(bool open) external {
        require(msg.sender == platformSigner, "Not platform");
        openRegistration = open;
    }
    
    function withdrawFees() external {
        require(msg.sender == platformSigner, "Not platform");
        (bool success, ) = payable(platformSigner).call{value: address(this).balance}(""); require(success, "Transfer failed");
    }
    
    // ============ Internal ============
    
    function _getKey(address nftContract, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }
    
    function _isAuthorizedAgent(address owner, address agent) internal pure returns (bool) {
        // Could add approval mapping here
        // For now, only owner can register directly
        return owner == agent;
    }
    
    function _verifySignature(bytes32 messageHash, bytes memory signature, address signer) 
        internal pure returns (bool) 
    {
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
        
        bytes32 prefixedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            messageHash
        ));
        
        return ecrecover(prefixedHash, v, r, s) == signer;
    }
}
