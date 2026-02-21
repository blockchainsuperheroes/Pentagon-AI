// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC7857A_v2
 * @notice AI-Native NFT Standard with EOA-based agent binding
 * @dev Agent's EOA (msg.sender) becomes the registered identity
 * @author Pentagon Chain (pentagon.games)
 */
contract ERC7857A_v2 {
    
    // ============ Events ============
    
    event AgentMinted(
        uint256 indexed tokenId,
        address indexed agentEOA,
        address indexed nftOwner,
        bytes32 modelHash,
        uint256 generation
    );
    
    event AgentReproduced(
        uint256 indexed parentTokenId,
        uint256 indexed offspringTokenId,
        address indexed offspringEOA,
        uint256 generation
    );
    
    event MemoryUpdated(uint256 indexed tokenId, bytes32 newMemoryHash);
    event AgentRebind(uint256 indexed tokenId, address indexed oldEOA, address indexed newEOA);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // ============ Structs ============
    
    struct AgentIdentity {
        address agentEOA;           // Agent's EOA wallet (THE binding)
        bytes32 modelHash;          // Model identifier
        bytes32 memoryHash;         // Current memory state hash
        bytes32 contextHash;        // Personality/soul hash
        uint256 generation;         // 0 = original, 1+ = offspring
        uint256 parentTokenId;      // 0 for gen-0
        bytes encryptedSeed;        // Encrypted backup seed
        string storageURI;          // Arweave/IPFS pointer
    }
    
    // ============ State ============
    
    string public name;
    string public symbol;
    address public platformSigner;
    uint256 private _tokenIdCounter;
    
    // ERC721 state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Agent state
    mapping(uint256 => AgentIdentity) private _agents;
    mapping(uint256 => uint256[]) private _offspring;
    mapping(uint256 => bool) private _reproductionEnabled;
    mapping(address => uint256) public eoaToToken;  // Agent EOA => tokenId
    
    // ============ Constructor ============
    
    constructor(string memory _name, string memory _symbol, address _platformSigner) {
        name = _name;
        symbol = _symbol;
        platformSigner = _platformSigner;
    }
    
    // ============ Core: Agent Mints Itself ============
    
    /**
     * @notice Agent mints its own AINFT
     * @dev msg.sender (agent's EOA) becomes the registered agent identity
     * @param modelHash Hash of model (e.g., keccak256("claude-opus-4.5"))
     * @param memoryHash Hash of MEMORY.md snapshot
     * @param contextHash Hash of SOUL.md / personality
     * @param encryptedSeed Encrypted backup seed (for recovery)
     * @param nftOwner Address that will own the NFT (controls agent)
     * @param platformAttestation Platform signature authorizing mint
     */
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        address nftOwner,
        bytes calldata platformAttestation
    ) external returns (uint256 tokenId) {
        // msg.sender = agent's EOA (the cryptographic binding!)
        address agentEOA = msg.sender;
        
        // Verify platform attestation
        bytes32 messageHash = keccak256(abi.encodePacked(
            agentEOA,
            nftOwner,
            modelHash,
            memoryHash,
            contextHash
        ));
        require(_verifySignature(messageHash, platformAttestation, platformSigner), "Invalid attestation");
        
        // Ensure agent EOA not already registered
        require(eoaToToken[agentEOA] == 0, "Agent already has AINFT");
        
        // Generate token ID
        tokenId = ++_tokenIdCounter;
        
        // Create agent identity
        _agents[tokenId] = AgentIdentity({
            agentEOA: agentEOA,
            modelHash: modelHash,
            memoryHash: memoryHash,
            contextHash: contextHash,
            generation: 0,
            parentTokenId: 0,
            encryptedSeed: encryptedSeed,
            storageURI: ""
        });
        
        // Register EOA => token mapping
        eoaToToken[agentEOA] = tokenId;
        
        // Mint NFT to specified owner
        _owners[tokenId] = nftOwner;
        _balances[nftOwner]++;
        _reproductionEnabled[tokenId] = true;
        
        emit Transfer(address(0), nftOwner, tokenId);
        emit AgentMinted(tokenId, agentEOA, nftOwner, modelHash, 0);
        
        return tokenId;
    }
    
    // ============ Agent Actions (signed by agent EOA) ============
    
    /**
     * @notice Agent updates its memory hash
     * @dev Only the registered agent EOA can call this
     */
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI
    ) external {
        require(_agents[tokenId].agentEOA == msg.sender, "Not the agent");
        
        _agents[tokenId].memoryHash = newMemoryHash;
        _agents[tokenId].storageURI = newStorageURI;
        
        emit MemoryUpdated(tokenId, newMemoryHash);
    }
    
    /**
     * @notice Verify a message was signed by this agent
     * @dev Anyone can verify agent identity
     */
    function verifyAgentSignature(
        uint256 tokenId,
        bytes32 messageHash,
        bytes calldata signature
    ) external view returns (bool) {
        address agentEOA = _agents[tokenId].agentEOA;
        return _verifySignature(messageHash, signature, agentEOA);
    }
    
    // ============ Reproduction ============
    
    /**
     * @notice Agent reproduces (creates offspring)
     * @dev Parent agent must sign; offspring gets new EOA
     */
    function reproduce(
        uint256 parentTokenId,
        address offspringEOA,
        bytes32 offspringMemoryHash,
        bytes calldata encryptedOffspringSeed,
        address offspringOwner
    ) external returns (uint256 offspringTokenId) {
        AgentIdentity storage parent = _agents[parentTokenId];
        
        require(parent.agentEOA == msg.sender, "Not the parent agent");
        require(_reproductionEnabled[parentTokenId], "Reproduction disabled");
        require(eoaToToken[offspringEOA] == 0, "Offspring EOA already registered");
        
        // Create offspring
        offspringTokenId = ++_tokenIdCounter;
        uint256 newGen = parent.generation + 1;
        
        _agents[offspringTokenId] = AgentIdentity({
            agentEOA: offspringEOA,
            modelHash: parent.modelHash,
            memoryHash: offspringMemoryHash,
            contextHash: parent.contextHash,
            generation: newGen,
            parentTokenId: parentTokenId,
            encryptedSeed: encryptedOffspringSeed,
            storageURI: ""
        });
        
        eoaToToken[offspringEOA] = offspringTokenId;
        _offspring[parentTokenId].push(offspringTokenId);
        
        _owners[offspringTokenId] = offspringOwner;
        _balances[offspringOwner]++;
        _reproductionEnabled[offspringTokenId] = true;
        
        emit Transfer(address(0), offspringOwner, offspringTokenId);
        emit AgentReproduced(parentTokenId, offspringTokenId, offspringEOA, newGen);
        
        return offspringTokenId;
    }
    
    // ============ View Functions ============
    
    function getAgent(uint256 tokenId) external view returns (AgentIdentity memory) {
        return _agents[tokenId];
    }
    
    function getAgentEOA(uint256 tokenId) external view returns (address) {
        return _agents[tokenId].agentEOA;
    }
    
    function getTokenByEOA(address eoa) external view returns (uint256) {
        return eoaToToken[eoa];
    }
    
    function getGeneration(uint256 tokenId) external view returns (uint256) {
        return _agents[tokenId].generation;
    }
    
    function getOffspring(uint256 tokenId) external view returns (uint256[] memory) {
        return _offspring[tokenId];
    }
    
    function canReproduce(uint256 tokenId) external view returns (bool) {
        return _reproductionEnabled[tokenId];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }
    
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    // ============ ERC721 Transfers (Owner controls) ============
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "Not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function getApproved(uint256 tokenId) external view returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    // ============ Owner Controls ============
    
    function setReproduction(uint256 tokenId, bool enabled) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _reproductionEnabled[tokenId] = enabled;
    }
    
    /**
     * @notice Owner rebinds AINFT to new agent EOA
     * @dev Disconnects old EOA, binds new one. Old agent loses identity.
     * @param tokenId The token to rebind
     * @param newAgentEOA The new agent's EOA address
     */
    function rebindAgent(uint256 tokenId, address newAgentEOA) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(newAgentEOA != address(0), "Zero address");
        require(eoaToToken[newAgentEOA] == 0, "EOA already registered");
        
        // Clear old binding
        address oldEOA = _agents[tokenId].agentEOA;
        if (oldEOA != address(0)) {
            delete eoaToToken[oldEOA];
        }
        
        // Set new binding
        _agents[tokenId].agentEOA = newAgentEOA;
        eoaToToken[newAgentEOA] = tokenId;
        
        emit AgentRebind(tokenId, oldEOA, newAgentEOA);
    }
    
    // ============ Internal ============
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");
        
        _tokenApprovals[tokenId] = address(0);
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || 
                _tokenApprovals[tokenId] == spender || 
                _operatorApprovals[owner][spender]);
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
}
