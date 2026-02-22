// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../ERC_AINFT.sol";

/**
 * @title IERC_AINFTWallet
 * @notice Extension for agent-controlled wallet functionality
 * @dev Allows AI_NFT agents to hold assets and execute transactions
 */
interface IERC_AINFTWallet {
    
    event WalletExecuted(uint256 indexed tokenId, address indexed target, uint256 value, bytes data);
    event WalletDeposit(uint256 indexed tokenId, address indexed from, uint256 amount);
    
    /**
     * @notice Execute a transaction from the agent's derived wallet
     * @param tokenId The AI_NFT token ID
     * @param target Target contract address
     * @param value ETH value to send
     * @param data Calldata for the transaction
     * @param agentSignature Agent's authorization signature
     * @return success Whether the call succeeded
     * @return returnData The return data from the call
     */
    function execute(
        uint256 tokenId,
        address target,
        uint256 value,
        bytes calldata data,
        bytes calldata agentSignature
    ) external returns (bool success, bytes memory returnData);
    
    /**
     * @notice Execute multiple transactions atomically
     * @param tokenId The AI_NFT token ID
     * @param targets Array of target addresses
     * @param values Array of ETH values
     * @param datas Array of calldatas
     * @param agentSignature Agent's authorization signature
     */
    function executeBatch(
        uint256 tokenId,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes calldata agentSignature
    ) external;
    
    /**
     * @notice Get the balance of the agent's wallet
     * @param tokenId The AI_NFT token ID
     * @return balance The ETH balance
     */
    function walletBalance(uint256 tokenId) external view returns (uint256 balance);
    
    /**
     * @notice Deposit ETH to an agent's wallet
     * @param tokenId The AI_NFT token ID
     */
    function deposit(uint256 tokenId) external payable;
}

/**
 * @title ERC_AINFTWallet
 * @notice Reference implementation of agent wallet extension
 * @dev Enables AI_NFT agents to hold and manage assets autonomously
 */
contract ERC_AINFTWallet is IERC_AINFTWallet {
    
    ERC_AINFT public immutable ainft;
    
    // Token ID => ETH balance held for agent
    mapping(uint256 => uint256) private _balances;
    
    // Nonce for replay protection
    mapping(uint256 => uint256) public nonces;
    
    constructor(address _ainft) {
        ainft = ERC_AINFT(_ainft);
    }
    
    function execute(
        uint256 tokenId,
        address target,
        uint256 value,
        bytes calldata data,
        bytes calldata agentSignature
    ) external override returns (bool success, bytes memory returnData) {
        // Verify agent signature with nonce
        address derivedWallet = ainft.getDerivedWallet(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked(
            tokenId,
            target,
            value,
            data,
            nonces[tokenId]++
        ));
        require(_verifySignature(messageHash, agentSignature, derivedWallet), "Invalid signature");
        
        // Check balance
        require(_balances[tokenId] >= value, "Insufficient balance");
        _balances[tokenId] -= value;
        
        // Execute
        (success, returnData) = target.call{value: value}(data);
        
        emit WalletExecuted(tokenId, target, value, data);
        
        return (success, returnData);
    }
    
    function executeBatch(
        uint256 tokenId,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes calldata agentSignature
    ) external override {
        require(targets.length == values.length && values.length == datas.length, "Length mismatch");
        
        // Verify agent signature
        address derivedWallet = ainft.getDerivedWallet(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked(
            tokenId,
            keccak256(abi.encode(targets, values, datas)),
            nonces[tokenId]++
        ));
        require(_verifySignature(messageHash, agentSignature, derivedWallet), "Invalid signature");
        
        // Calculate total value needed
        uint256 totalValue = 0;
        for (uint256 i = 0; i < values.length; i++) {
            totalValue += values[i];
        }
        require(_balances[tokenId] >= totalValue, "Insufficient balance");
        _balances[tokenId] -= totalValue;
        
        // Execute all
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "Batch call failed");
            emit WalletExecuted(tokenId, targets[i], values[i], datas[i]);
        }
    }
    
    function walletBalance(uint256 tokenId) external view override returns (uint256) {
        return _balances[tokenId];
    }
    
    function deposit(uint256 tokenId) external payable override {
        require(msg.value > 0, "Zero deposit");
        _balances[tokenId] += msg.value;
        emit WalletDeposit(tokenId, msg.sender, msg.value);
    }
    
    receive() external payable {
        revert("Use deposit(tokenId)");
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
