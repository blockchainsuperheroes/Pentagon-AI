// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../AINFT.sol";

/**
 * @title AINFTDashStorage
 * @notice Extension for AINFT with Dash Platform storage support
 * @dev Adds storage type tracking and xDASH burn verification
 */
abstract contract AINFTDashStorage is ERC7857A {
    
    // ============ Events ============
    
    event StorageTypeChanged(
        uint256 indexed tokenId,
        StorageType oldType,
        StorageType newType
    );
    
    event DashStorageLinked(
        uint256 indexed tokenId,
        string dashDocumentId,
        bytes32 memoryHash
    );
    
    event XDashBurned(
        address indexed burner,
        uint256 amount,
        uint256 creditsAdded
    );
    
    // ============ Enums ============
    
    enum StorageType {
        None,
        IPFS,
        Arweave,
        Dash,
        ZeroG
    }
    
    // ============ State ============
    
    // Token ID => preferred storage type
    mapping(uint256 => StorageType) public tokenStorageType;
    
    // Token ID => Dash document ID (if using Dash)
    mapping(uint256 => string) public dashDocumentId;
    
    // xDASH token contract on Pentagon Chain
    address public xDashToken;
    
    // peg.gg verifier address
    address public pegVerifier;
    
    // Credits per xDASH burned (scaled by 1e18)
    uint256 public creditsPerXDash = 1000 * 1e18;
    
    // User storage credits
    mapping(address => uint256) public storageCredits;
    
    // ============ Constructor ============
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _platformSigner,
        address _xDashToken,
        address _pegVerifier
    ) ERC7857A(_name, _symbol, _platformSigner) {
        xDashToken = _xDashToken;
        pegVerifier = _pegVerifier;
    }
    
    // ============ Storage Functions ============
    
    /**
     * @notice Update storage URI with type detection
     * @param tokenId Token to update
     * @param newStorageURI New storage URI (ipfs://, ar://, dash://, 0g://)
     * @param agentSignature Agent's authorization
     */
    function updateMemoryWithType(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI,
        bytes calldata agentSignature
    ) external {
        // Call parent implementation
        this.updateMemory(tokenId, newMemoryHash, newStorageURI, agentSignature);
        
        // Detect and record storage type
        StorageType oldType = tokenStorageType[tokenId];
        StorageType newType = _detectStorageType(newStorageURI);
        
        if (oldType != newType) {
            tokenStorageType[tokenId] = newType;
            emit StorageTypeChanged(tokenId, oldType, newType);
        }
        
        // If Dash, extract document ID
        if (newType == StorageType.Dash) {
            string memory docId = _extractDashDocId(newStorageURI);
            dashDocumentId[tokenId] = docId;
            emit DashStorageLinked(tokenId, docId, newMemoryHash);
        }
    }
    
    /**
     * @notice Burn xDASH for storage credits
     * @param amount Amount of xDASH to burn
     */
    function burnXDashForCredits(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        
        // Transfer and burn xDASH
        IERC20Burnable(xDashToken).burnFrom(msg.sender, amount);
        
        // Add credits
        uint256 credits = (amount * creditsPerXDash) / 1e18;
        storageCredits[msg.sender] += credits;
        
        emit XDashBurned(msg.sender, amount, credits);
    }
    
    /**
     * @notice Use storage credits (called by peg.gg backend)
     * @param user User address
     * @param amount Credits to deduct
     */
    function useCredits(address user, uint256 amount) external {
        require(msg.sender == pegVerifier, "Only peg verifier");
        require(storageCredits[user] >= amount, "Insufficient credits");
        
        storageCredits[user] -= amount;
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get storage type for a token
     */
    function getStorageType(uint256 tokenId) external view returns (StorageType) {
        return tokenStorageType[tokenId];
    }
    
    /**
     * @notice Get Dash document ID for a token
     */
    function getDashDocumentId(uint256 tokenId) external view returns (string memory) {
        return dashDocumentId[tokenId];
    }
    
    /**
     * @notice Get user's storage credits
     */
    function getCredits(address user) external view returns (uint256) {
        return storageCredits[user];
    }
    
    /**
     * @notice Check if storage URI is valid Dash format
     */
    function isDashUri(string calldata uri) external pure returns (bool) {
        return _detectStorageType(uri) == StorageType.Dash;
    }
    
    // ============ Internal ============
    
    function _detectStorageType(string memory uri) internal pure returns (StorageType) {
        bytes memory uriBytes = bytes(uri);
        
        if (uriBytes.length >= 7) {
            // Check "ipfs://"
            if (
                uriBytes[0] == 'i' &&
                uriBytes[1] == 'p' &&
                uriBytes[2] == 'f' &&
                uriBytes[3] == 's' &&
                uriBytes[4] == ':' &&
                uriBytes[5] == '/' &&
                uriBytes[6] == '/'
            ) {
                return StorageType.IPFS;
            }
            
            // Check "dash://"
            if (
                uriBytes[0] == 'd' &&
                uriBytes[1] == 'a' &&
                uriBytes[2] == 's' &&
                uriBytes[3] == 'h' &&
                uriBytes[4] == ':' &&
                uriBytes[5] == '/' &&
                uriBytes[6] == '/'
            ) {
                return StorageType.Dash;
            }
        }
        
        if (uriBytes.length >= 5) {
            // Check "ar://"
            if (
                uriBytes[0] == 'a' &&
                uriBytes[1] == 'r' &&
                uriBytes[2] == ':' &&
                uriBytes[3] == '/' &&
                uriBytes[4] == '/'
            ) {
                return StorageType.Arweave;
            }
            
            // Check "0g://"
            if (
                uriBytes[0] == '0' &&
                uriBytes[1] == 'g' &&
                uriBytes[2] == ':' &&
                uriBytes[3] == '/' &&
                uriBytes[4] == '/'
            ) {
                return StorageType.ZeroG;
            }
        }
        
        return StorageType.None;
    }
    
    function _extractDashDocId(string memory uri) internal pure returns (string memory) {
        bytes memory uriBytes = bytes(uri);
        require(uriBytes.length > 7, "Invalid Dash URI");
        
        bytes memory docId = new bytes(uriBytes.length - 7);
        for (uint i = 7; i < uriBytes.length; i++) {
            docId[i - 7] = uriBytes[i];
        }
        
        return string(docId);
    }
    
    // ============ Admin ============
    
    function setXDashToken(address _xDashToken) external {
        require(msg.sender == platformSigner, "Not platform");
        xDashToken = _xDashToken;
    }
    
    function setPegVerifier(address _pegVerifier) external {
        require(msg.sender == platformSigner, "Not platform");
        pegVerifier = _pegVerifier;
    }
    
    function setCreditsPerXDash(uint256 _credits) external {
        require(msg.sender == platformSigner, "Not platform");
        creditsPerXDash = _credits;
    }
}

/**
 * @notice Interface for burnable ERC20 (xDASH)
 */
interface IERC20Burnable {
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}
