// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../ERC7857A.sol";

/**
 * @title IERC7857AComposable
 * @notice Extension for composable agent capabilities (ERC-6551 compatible)
 * @dev Allows AI_NFTs to own other NFTs and tokens, building agent "inventories"
 */
interface IERC7857AComposable {
    
    event AssetBound(uint256 indexed tokenId, address indexed asset, uint256 indexed assetId);
    event AssetUnbound(uint256 indexed tokenId, address indexed asset, uint256 indexed assetId);
    event CapabilityAdded(uint256 indexed tokenId, bytes32 indexed capabilityHash, string capabilityURI);
    
    /**
     * @notice Bind an NFT to an AI_NFT (agent owns the asset)
     * @param tokenId The AI_NFT token ID
     * @param asset The NFT contract address
     * @param assetId The NFT token ID to bind
     * @param agentSignature Agent's authorization
     */
    function bindAsset(
        uint256 tokenId,
        address asset,
        uint256 assetId,
        bytes calldata agentSignature
    ) external;
    
    /**
     * @notice Unbind an NFT from an AI_NFT
     * @param tokenId The AI_NFT token ID
     * @param asset The NFT contract address
     * @param assetId The NFT token ID to unbind
     * @param recipient Where to send the unbound NFT
     * @param agentSignature Agent's authorization
     */
    function unbindAsset(
        uint256 tokenId,
        address asset,
        uint256 assetId,
        address recipient,
        bytes calldata agentSignature
    ) external;
    
    /**
     * @notice Add a capability to an agent (skill, tool, permission)
     * @param tokenId The AI_NFT token ID
     * @param capabilityHash Hash of capability definition
     * @param capabilityURI URI pointing to capability spec
     * @param agentSignature Agent's authorization
     */
    function addCapability(
        uint256 tokenId,
        bytes32 capabilityHash,
        string calldata capabilityURI,
        bytes calldata agentSignature
    ) external;
    
    /**
     * @notice Get all assets bound to an AI_NFT
     * @param tokenId The AI_NFT token ID
     * @return assets Array of (contract, tokenId) pairs
     */
    function getBoundAssets(uint256 tokenId) external view returns (
        address[] memory contracts,
        uint256[] memory tokenIds
    );
    
    /**
     * @notice Get all capabilities of an AI_NFT
     * @param tokenId The AI_NFT token ID
     * @return hashes Array of capability hashes
     * @return uris Array of capability URIs
     */
    function getCapabilities(uint256 tokenId) external view returns (
        bytes32[] memory hashes,
        string[] memory uris
    );
    
    /**
     * @notice Check if agent has a specific capability
     * @param tokenId The AI_NFT token ID
     * @param capabilityHash The capability to check
     * @return hasCapability True if agent has the capability
     */
    function hasCapability(uint256 tokenId, bytes32 capabilityHash) external view returns (bool);
}

/**
 * @title ERC7857AComposable
 * @notice Reference implementation of composable agent extension
 * @dev Enables AI_NFTs to own assets and accumulate capabilities
 */
contract ERC7857AComposable is IERC7857AComposable {
    
    ERC7857A public immutable ainft;
    
    struct BoundAsset {
        address assetContract;
        uint256 assetId;
    }
    
    struct Capability {
        bytes32 hash;
        string uri;
        bool active;
    }
    
    // Token ID => bound assets
    mapping(uint256 => BoundAsset[]) private _boundAssets;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private _assetBound;
    
    // Token ID => capabilities
    mapping(uint256 => Capability[]) private _capabilities;
    mapping(uint256 => mapping(bytes32 => bool)) private _hasCapability;
    
    constructor(address _ainft) {
        ainft = ERC7857A(_ainft);
    }
    
    function bindAsset(
        uint256 tokenId,
        address asset,
        uint256 assetId,
        bytes calldata agentSignature
    ) external override {
        // Verify agent signature
        address derivedWallet = ainft.getDerivedWallet(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked("bind", tokenId, asset, assetId));
        require(_verifySignature(messageHash, agentSignature, derivedWallet), "Invalid signature");
        
        require(!_assetBound[tokenId][asset][assetId], "Already bound");
        
        // Transfer asset to this contract (held on behalf of agent)
        IERC721(asset).transferFrom(msg.sender, address(this), assetId);
        
        _boundAssets[tokenId].push(BoundAsset({
            assetContract: asset,
            assetId: assetId
        }));
        _assetBound[tokenId][asset][assetId] = true;
        
        emit AssetBound(tokenId, asset, assetId);
    }
    
    function unbindAsset(
        uint256 tokenId,
        address asset,
        uint256 assetId,
        address recipient,
        bytes calldata agentSignature
    ) external override {
        // Verify agent signature
        address derivedWallet = ainft.getDerivedWallet(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked("unbind", tokenId, asset, assetId, recipient));
        require(_verifySignature(messageHash, agentSignature, derivedWallet), "Invalid signature");
        
        require(_assetBound[tokenId][asset][assetId], "Not bound");
        
        // Remove from array (swap and pop)
        BoundAsset[] storage assets = _boundAssets[tokenId];
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetContract == asset && assets[i].assetId == assetId) {
                assets[i] = assets[assets.length - 1];
                assets.pop();
                break;
            }
        }
        _assetBound[tokenId][asset][assetId] = false;
        
        // Transfer to recipient
        IERC721(asset).transferFrom(address(this), recipient, assetId);
        
        emit AssetUnbound(tokenId, asset, assetId);
    }
    
    function addCapability(
        uint256 tokenId,
        bytes32 capabilityHash,
        string calldata capabilityURI,
        bytes calldata agentSignature
    ) external override {
        // Verify agent signature
        address derivedWallet = ainft.getDerivedWallet(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked("capability", tokenId, capabilityHash, capabilityURI));
        require(_verifySignature(messageHash, agentSignature, derivedWallet), "Invalid signature");
        
        require(!_hasCapability[tokenId][capabilityHash], "Capability exists");
        
        _capabilities[tokenId].push(Capability({
            hash: capabilityHash,
            uri: capabilityURI,
            active: true
        }));
        _hasCapability[tokenId][capabilityHash] = true;
        
        emit CapabilityAdded(tokenId, capabilityHash, capabilityURI);
    }
    
    function getBoundAssets(uint256 tokenId) external view override returns (
        address[] memory contracts,
        uint256[] memory tokenIds
    ) {
        BoundAsset[] storage assets = _boundAssets[tokenId];
        contracts = new address[](assets.length);
        tokenIds = new uint256[](assets.length);
        
        for (uint256 i = 0; i < assets.length; i++) {
            contracts[i] = assets[i].assetContract;
            tokenIds[i] = assets[i].assetId;
        }
        
        return (contracts, tokenIds);
    }
    
    function getCapabilities(uint256 tokenId) external view override returns (
        bytes32[] memory hashes,
        string[] memory uris
    ) {
        Capability[] storage caps = _capabilities[tokenId];
        uint256 activeCount = 0;
        for (uint256 i = 0; i < caps.length; i++) {
            if (caps[i].active) activeCount++;
        }
        
        hashes = new bytes32[](activeCount);
        uris = new string[](activeCount);
        
        uint256 j = 0;
        for (uint256 i = 0; i < caps.length; i++) {
            if (caps[i].active) {
                hashes[j] = caps[i].hash;
                uris[j] = caps[i].uri;
                j++;
            }
        }
        
        return (hashes, uris);
    }
    
    function hasCapability(uint256 tokenId, bytes32 capabilityHash) external view override returns (bool) {
        return _hasCapability[tokenId][capabilityHash];
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
        return ecrecover(prefixedHash, v, r, s) == signer;
    }
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
