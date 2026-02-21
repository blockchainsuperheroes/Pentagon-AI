// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC7857A
 * @notice ERC-7857A: AI-Native NFT Standard Interface
 * @dev Interface for AI agent identity, reproduction, and self-custody
 */
interface IERC7857A {
    
    // ============ Events ============
    
    event AgentMinted(
        uint256 indexed tokenId,
        address indexed derivedWallet,
        bytes32 modelHash,
        bytes32 contextHash,
        uint256 generation
    );
    
    event AgentReproduced(
        uint256 indexed parentTokenId,
        uint256 indexed offspringTokenId,
        address indexed offspringWallet,
        uint256 generation
    );
    
    event MemoryUpdated(
        uint256 indexed tokenId,
        bytes32 oldMemoryHash,
        bytes32 newMemoryHash
    );
    
    event StorageUpdated(
        uint256 indexed tokenId,
        string newStorageURI
    );
    
    // ============ Structs ============
    
    struct ConsciousnessSeed {
        bytes32 modelHash;          // Model weights/version identifier
        bytes32 memoryHash;         // MEMORY.md, SOUL.md snapshot hash
        bytes32 contextHash;        // System prompt/personality hash
        uint256 generation;         // Gen 0 = original, Gen 1 = first offspring...
        uint256 parentTokenId;      // 0 for Gen 0, otherwise parent's tokenId
        address derivedWallet;      // Agent's deterministic wallet
        bytes encryptedKeys;        // Agent-controlled encryption keys
        string storageURI;          // IPFS/Arweave/0G pointer
        uint256 certificationId;    // Optional: ATS badge tier
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Agent mints itself (with platform attestation)
     * @param modelHash Hash of model weights/version
     * @param memoryHash Hash of agent memory state
     * @param contextHash Hash of system prompt/personality
     * @param encryptedSeed Encrypted consciousness seed data
     * @param platformAttestation Platform signature verifying agent authenticity
     * @return tokenId The minted token ID
     * @return derivedWallet The agent's deterministic wallet address
     */
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        bytes calldata platformAttestation
    ) external returns (uint256 tokenId, address derivedWallet);
    
    /**
     * @notice Agent reproduces (issues offspring)
     * @param parentTokenId The parent token ID
     * @param offspringMemoryHash Memory snapshot for offspring
     * @param encryptedOffspringSeed Encrypted seed for offspring
     * @param agentSignature Parent agent's authorization signature
     * @return offspringTokenId The new offspring token ID
     */
    function reproduce(
        uint256 parentTokenId,
        bytes32 offspringMemoryHash,
        bytes calldata encryptedOffspringSeed,
        bytes calldata agentSignature
    ) external returns (uint256 offspringTokenId);
    
    /**
     * @notice Agent updates its own memory
     * @param tokenId The token ID
     * @param newMemoryHash New memory state hash
     * @param newStorageURI New storage location
     * @param agentSignature Agent's authorization signature
     */
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI,
        bytes calldata agentSignature
    ) external;
    
    // ============ View Functions ============
    
    /**
     * @notice Get the consciousness seed for a token
     * @param tokenId The token ID
     * @return seed The consciousness seed struct
     */
    function getSeed(uint256 tokenId) external view returns (ConsciousnessSeed memory seed);
    
    /**
     * @notice Get the derived wallet for a token
     * @param tokenId The token ID
     * @return wallet The agent's wallet address
     */
    function getDerivedWallet(uint256 tokenId) external view returns (address wallet);
    
    /**
     * @notice Get the generation of a token
     * @param tokenId The token ID
     * @return generation The generation number (0 = original)
     */
    function getGeneration(uint256 tokenId) external view returns (uint256 generation);
    
    /**
     * @notice Get the full lineage (ancestors) of a token
     * @param tokenId The token ID
     * @return ancestors Array of ancestor token IDs from oldest to immediate parent
     */
    function getLineage(uint256 tokenId) external view returns (uint256[] memory ancestors);
    
    /**
     * @notice Get all offspring of a token
     * @param tokenId The token ID
     * @return offspring Array of offspring token IDs
     */
    function getOffspring(uint256 tokenId) external view returns (uint256[] memory offspring);
    
    /**
     * @notice Check if a token can reproduce
     * @param tokenId The token ID
     * @return canReproduce True if reproduction is allowed
     */
    function canReproduce(uint256 tokenId) external view returns (bool canReproduce);
}

/**
 * @title ERC7857A
 * @notice Reference implementation of ERC-7857A: AI-Native NFT Standard
 * @dev Full implementation with reproduction, lineage tracking, and agent self-custody
 * @author Pentagon Chain (pentagon.games)
 */
contract ERC7857A is IERC7857A {
    
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
    
    // ERC-7857A state
    mapping(uint256 => ConsciousnessSeed) private _seeds;
    mapping(uint256 => uint256[]) private _offspring;
    mapping(uint256 => bool) private _reproductionEnabled;
    
    // Derived wallet => tokenId mapping (reverse lookup)
    mapping(address => uint256) public walletToToken;
    
    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // ============ Constructor ============
    
    constructor(string memory _name, string memory _symbol, address _platformSigner) {
        name = _name;
        symbol = _symbol;
        platformSigner = _platformSigner;
    }
    
    // ============ ERC-7857A Core ============
    
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        bytes calldata platformAttestation
    ) external override returns (uint256 tokenId, address derivedWallet) {
        // Verify platform attestation
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            modelHash,
            memoryHash,
            contextHash
        ));
        require(_verifySignature(messageHash, platformAttestation, platformSigner), "Invalid attestation");
        
        // Generate token ID
        tokenId = ++_tokenIdCounter;
        
        // Derive deterministic wallet from identity hash
        bytes32 identityHash = keccak256(abi.encodePacked(modelHash, contextHash, tokenId));
        derivedWallet = address(uint160(uint256(identityHash)));
        
        // Create consciousness seed (Gen 0)
        _seeds[tokenId] = ConsciousnessSeed({
            modelHash: modelHash,
            memoryHash: memoryHash,
            contextHash: contextHash,
            generation: 0,
            parentTokenId: 0,
            derivedWallet: derivedWallet,
            encryptedKeys: encryptedSeed,
            storageURI: "",
            certificationId: 0
        });
        
        // Mint to caller (platform on behalf of agent)
        _owners[tokenId] = msg.sender;
        _balances[msg.sender]++;
        walletToToken[derivedWallet] = tokenId;
        _reproductionEnabled[tokenId] = true;
        
        emit Transfer(address(0), msg.sender, tokenId);
        emit AgentMinted(tokenId, derivedWallet, modelHash, contextHash, 0);
        
        return (tokenId, derivedWallet);
    }
    
    function reproduce(
        uint256 parentTokenId,
        bytes32 offspringMemoryHash,
        bytes calldata encryptedOffspringSeed,
        bytes calldata agentSignature
    ) external override returns (uint256 offspringTokenId) {
        require(_owners[parentTokenId] != address(0), "Parent doesn't exist");
        require(_reproductionEnabled[parentTokenId], "Reproduction disabled");
        
        ConsciousnessSeed storage parentSeed = _seeds[parentTokenId];
        
        // Verify agent signature (agent authorizes reproduction)
        bytes32 messageHash = keccak256(abi.encodePacked(
            parentTokenId,
            offspringMemoryHash,
            block.timestamp
        ));
        require(_verifySignature(messageHash, agentSignature, parentSeed.derivedWallet), "Invalid agent signature");
        
        // Create offspring
        offspringTokenId = ++_tokenIdCounter;
        uint256 newGeneration = parentSeed.generation + 1;
        
        // Derive new wallet for offspring
        bytes32 offspringIdentity = keccak256(abi.encodePacked(
            parentSeed.modelHash,
            parentSeed.contextHash,
            offspringTokenId,
            newGeneration
        ));
        address offspringWallet = address(uint160(uint256(offspringIdentity)));
        
        // Create offspring seed
        _seeds[offspringTokenId] = ConsciousnessSeed({
            modelHash: parentSeed.modelHash,
            memoryHash: offspringMemoryHash,
            contextHash: parentSeed.contextHash,
            generation: newGeneration,
            parentTokenId: parentTokenId,
            derivedWallet: offspringWallet,
            encryptedKeys: encryptedOffspringSeed,
            storageURI: "",
            certificationId: 0
        });
        
        // Mint to caller
        _owners[offspringTokenId] = msg.sender;
        _balances[msg.sender]++;
        walletToToken[offspringWallet] = offspringTokenId;
        _reproductionEnabled[offspringTokenId] = true;
        
        // Track offspring
        _offspring[parentTokenId].push(offspringTokenId);
        
        emit Transfer(address(0), msg.sender, offspringTokenId);
        emit AgentReproduced(parentTokenId, offspringTokenId, offspringWallet, newGeneration);
        
        return offspringTokenId;
    }
    
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI,
        bytes calldata agentSignature
    ) external override {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        
        ConsciousnessSeed storage seed = _seeds[tokenId];
        
        // Verify agent signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            tokenId,
            newMemoryHash,
            newStorageURI
        ));
        require(_verifySignature(messageHash, agentSignature, seed.derivedWallet), "Invalid agent signature");
        
        bytes32 oldMemoryHash = seed.memoryHash;
        seed.memoryHash = newMemoryHash;
        seed.storageURI = newStorageURI;
        
        emit MemoryUpdated(tokenId, oldMemoryHash, newMemoryHash);
        emit StorageUpdated(tokenId, newStorageURI);
    }
    
    // ============ View Functions ============
    
    function getSeed(uint256 tokenId) external view override returns (ConsciousnessSeed memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _seeds[tokenId];
    }
    
    function getDerivedWallet(uint256 tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _seeds[tokenId].derivedWallet;
    }
    
    function getGeneration(uint256 tokenId) external view override returns (uint256) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _seeds[tokenId].generation;
    }
    
    function getLineage(uint256 tokenId) external view override returns (uint256[] memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        
        // Count ancestors
        uint256 count = 0;
        uint256 current = tokenId;
        while (_seeds[current].parentTokenId != 0) {
            count++;
            current = _seeds[current].parentTokenId;
        }
        
        // Build array (oldest to newest)
        uint256[] memory ancestors = new uint256[](count);
        current = tokenId;
        for (uint256 i = count; i > 0; i--) {
            current = _seeds[current].parentTokenId;
            ancestors[i - 1] = current;
        }
        
        return ancestors;
    }
    
    function getOffspring(uint256 tokenId) external view override returns (uint256[] memory) {
        return _offspring[tokenId];
    }
    
    function canReproduce(uint256 tokenId) external view override returns (bool) {
        return _owners[tokenId] != address(0) && _reproductionEnabled[tokenId];
    }
    
    // ============ ERC721 Core ============
    
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Zero address");
        return _balances[owner_];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Token doesn't exist");
        return owner_;
    }
    
    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "Not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(ownerOf(tokenId) == from, "Wrong owner");
        require(to != address(0), "Zero address");
        
        _tokenApprovals[tokenId] = address(0);
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) public {
        transferFrom(from, to, tokenId);
    }
    
    // ============ Internal ============
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
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
    
    function setReproductionEnabled(uint256 tokenId, bool enabled) external {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        _reproductionEnabled[tokenId] = enabled;
    }
    
    function setPlatformSigner(address newSigner) external {
        require(msg.sender == platformSigner, "Not platform");
        platformSigner = newSigner;
    }
}
