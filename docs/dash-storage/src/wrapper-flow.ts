/**
 * ETH ↔ Dash Wrapper Flow (MVP)
 * 
 * Recommended for Checkpoint 2 demo — works today with high-level SDK
 * 
 * Flow:
 * 1. User burns xDASH on Pentagon Chain → event
 * 2. User signs ETH message authorizing storage
 * 3. Backend verifies ETH sig → recovers pubkey → checks linked Dash identity
 * 4. Backend builds & broadcasts Dash Document with wrapper identity
 */

import { ethers } from 'ethers';
import Dash from 'dash';
import { encryptMemory, toBase64 } from './encryption';

export interface WrapperConfig {
  /** Dash network */
  network: 'testnet' | 'mainnet';
  /** Data contract ID */
  dataContractId: string;
  /** Wrapper identity mnemonic (backend-controlled) */
  wrapperMnemonic: string;
}

export interface StorageAuthMessage {
  /** Hash of the encrypted blob */
  blobHash: string;
  /** User's linked Dash identity ID */
  dashIdentityId: string;
  /** AINFT token ID */
  tokenId: string;
  /** Nonce for replay protection */
  nonce: number;
  /** Expiry timestamp */
  expiry: number;
}

/**
 * Create auth message for ETH signing
 */
export function createAuthMessage(params: StorageAuthMessage): string {
  return `Authorize peg.gg storage: blobHash=${params.blobHash}, identity=${params.dashIdentityId}, AINFT=${params.tokenId}, nonce=${params.nonce}, expiry=${params.expiry}`;
}

/**
 * Verify ETH signature and recover address
 */
export function verifyAuthSignature(
  message: string,
  signature: string
): { address: string; pubkey: string } {
  const address = ethers.verifyMessage(message, signature);
  // Recover pubkey from signature
  const msgHash = ethers.hashMessage(message);
  const pubkey = ethers.SigningKey.recoverPublicKey(msgHash, signature);
  
  return { address, pubkey };
}

/**
 * Wrapper service for backend Dash operations
 */
export class DashWrapperService {
  private client: any;
  private wrapperIdentity: any;
  private config: WrapperConfig;

  constructor(config: WrapperConfig) {
    this.config = config;
  }

  async init(): Promise<void> {
    this.client = new Dash.Client({
      network: this.config.network,
      wallet: {
        mnemonic: this.config.wrapperMnemonic,
      },
      apps: {
        pentagonAINFT: {
          contractId: this.config.dataContractId,
        },
      },
    });

    // Get wrapper identity
    const account = await this.client.getWalletAccount();
    const identityIds = account.identities.getIdentityIds();
    
    if (identityIds.length === 0) {
      // Register new wrapper identity
      this.wrapperIdentity = await this.client.platform.identities.register();
      console.log('Created wrapper identity:', this.wrapperIdentity.getId());
    } else {
      this.wrapperIdentity = await this.client.platform.identities.get(identityIds[0]);
    }
  }

  /**
   * Store encrypted data on behalf of user
   * Called after ETH signature verification
   */
  async storeForUser(
    tokenId: string,
    agentWallet: string,
    encryptedData: string,
    memoryHash: string,
    nonce: string,
    userDashIdentityId: string
  ): Promise<{ documentId: string; transitionHash: string }> {
    
    const docProperties = {
      tokenId,
      agentWallet: agentWallet.toLowerCase(),
      encryptedMemory: encryptedData,
      memoryHash,
      encryptionNonce: nonce,
      userIdentity: userDashIdentityId, // Track original user
      version: 1,
      timestamp: Date.now(),
      message: `AINFT prompt blob hash: ${memoryHash} @ ${new Date().toUTCString()}`,
    };

    // Create document with wrapper identity
    const document = await this.client.platform.documents.create(
      'pentagonAINFT.privateStorage',
      this.wrapperIdentity,
      docProperties
    );

    // Broadcast (SDK handles Bincode + double-SHA256 + signing)
    const documentBatch = {
      create: [document],
      replace: [],
      delete: [],
    };

    await this.client.platform.documents.broadcast(documentBatch, this.wrapperIdentity);

    const documentId = document.getId().toString();
    console.log('Dash document ID:', documentId);

    return {
      documentId,
      transitionHash: documentId, // Document ID serves as reference
    };
  }

  /**
   * Link ETH address to Dash identity
   * Creates new identity funded by wrapper
   */
  async linkEthAddress(
    ethAddress: string,
    ethSignature: string
  ): Promise<{ identityId: string; mnemonic: string }> {
    // Verify signature
    const message = `Link Dash Identity to ${ethAddress} for Pentagon AINFT storage on peg.gg`;
    const recovered = ethers.verifyMessage(message, ethSignature);
    
    if (recovered.toLowerCase() !== ethAddress.toLowerCase()) {
      throw new Error('Signature verification failed');
    }

    // Create new identity for user
    // In production, generate dedicated mnemonic per user
    const userIdentity = await this.client.platform.identities.register();
    
    // Get mnemonic for user (they control their own identity)
    const mnemonic = this.client.wallet.exportWallet();

    return {
      identityId: userIdentity.getId().toString(),
      mnemonic, // User stores this securely
    };
  }

  async disconnect(): Promise<void> {
    await this.client?.disconnect();
  }
}

/**
 * Example: Complete wrapper flow
 */
export async function exampleWrapperFlow() {
  // 1. User burns xDASH on Pentagon Chain (handled by frontend)
  
  // 2. User signs auth message
  const authParams: StorageAuthMessage = {
    blobHash: '0xABC123...',
    dashIdentityId: 'user-dash-identity-id',
    tokenId: '1',
    nonce: Date.now(),
    expiry: Date.now() + 3600000, // 1 hour
  };
  const message = createAuthMessage(authParams);
  // const ethSig = await signer.signMessage(message); // Frontend

  // 3. Backend verifies & stores
  // const { address } = verifyAuthSignature(message, ethSig);
  // const wrapper = new DashWrapperService(config);
  // await wrapper.init();
  // const result = await wrapper.storeForUser(...);
}
