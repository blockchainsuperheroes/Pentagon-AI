/**
 * Pentagon AINFT Dash Storage
 * 
 * Integrates Dash Platform (Evolution) for encrypted agent memory storage
 * 
 * Flow:
 * 1. Agent connects ETH wallet
 * 2. Links ETH address to Dash Identity via peg.gg
 * 3. Burns xDASH for storage credits
 * 4. Encrypts memory with agent's private key
 * 5. Stores encrypted document on Dash Drive
 */

import Dash from 'dash';
import { ethers } from 'ethers';
import {
  DashStorageConfig,
  AINFTStorageDocument,
  IdentityLinkResponse,
  StorageResult,
  RetrievalResult,
} from './types';
import {
  deriveEncryptionKey,
  encryptMemory,
  decryptMemory,
  verifyMemoryHash,
  toBase64,
  fromBase64,
} from './encryption';

export * from './types';
export * from './encryption';
export * from './wrapper-flow';
export * from './sovereign-signing';

/**
 * Main client for AINFT Dash storage operations
 */
export class DashAINFTStorage {
  private client: any;
  private identity: any;
  private config: DashStorageConfig;
  private initialized = false;

  constructor(config: DashStorageConfig) {
    this.config = config;
  }

  /**
   * Initialize storage client with ETH wallet
   * Links ETH address to Dash Identity via peg.gg gateway
   */
  async init(signer: ethers.Signer): Promise<void> {
    const ethAddress = await signer.getAddress();
    
    // Create link message
    const message = this.getLinkMessage(ethAddress);
    const signature = await signer.signMessage(message);

    // Get or create Dash identity via peg.gg
    const response = await fetch(`${this.config.pegGatewayUrl}/identity/link`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ethAddress, ethSignature: signature }),
    });

    if (!response.ok) {
      throw new Error(`Failed to link identity: ${await response.text()}`);
    }

    const linkResult: IdentityLinkResponse = await response.json();

    // Initialize Dash client with linked identity
    this.client = new Dash.Client({
      network: this.config.network,
      wallet: {
        mnemonic: linkResult.mnemonic,
      },
      apps: {
        ainftStorage: {
          contractId: this.config.dataContractId,
        },
      },
      ...(this.config.dapiAddresses && {
        dapiAddresses: this.config.dapiAddresses,
      }),
    });

    // Get identity
    this.identity = await this.client.platform.identities.get(linkResult.identityId);
    this.initialized = true;
  }

  /**
   * Store encrypted agent memory on Dash Platform
   */
  async storeMemory(
    tokenId: string,
    agentWallet: string,
    memoryContent: string,
    agentPrivateKey: Uint8Array
  ): Promise<StorageResult> {
    this.ensureInitialized();

    // Derive encryption key
    const encryptionKey = deriveEncryptionKey(agentPrivateKey, tokenId);

    // Encrypt memory
    const { ciphertext, nonce, hash } = encryptMemory(memoryContent, encryptionKey);

    // Check for existing document (for versioning)
    const existing = await this.getDocument(tokenId);
    const version = existing ? existing.version + 1 : 1;

    // Create document
    const docProperties: AINFTStorageDocument = {
      tokenId,
      agentWallet: agentWallet.toLowerCase(),
      encryptedMemory: toBase64(ciphertext),
      memoryHash: hash,
      encryptionNonce: toBase64(nonce),
      version,
      timestamp: Date.now(),
    };

    const document = await this.client.platform.documents.create(
      'ainftStorage.storage',
      this.identity,
      docProperties
    );

    // Broadcast state transition (SDK handles Bincode + double-SHA256 + signing)
    const documentBatch = {
      create: existing ? [] : [document],
      replace: existing ? [document] : [],
      delete: [],
    };

    // SDK internally:
    // 1. Builds state transition object
    // 2. Serializes with Bincode (exclude identityId + sig fields)
    // 3. double-SHA256 hash
    // 4. Signs with identity key
    // 5. Broadcasts to DAPI
    const transition = await this.client.platform.documents.broadcast(
      documentBatch,
      this.identity
    );

    const documentId = document.toJSON().$id;
    const transitionHash = transition.toBuffer().toString('hex');

    return {
      documentId,
      transitionHash,
      storageUri: `dash://${documentId}`,
    };
  }

  /**
   * Retrieve and decrypt agent memory from Dash Platform
   */
  async retrieveMemory(
    tokenId: string,
    agentPrivateKey: Uint8Array
  ): Promise<RetrievalResult | null> {
    this.ensureInitialized();

    const doc = await this.getDocument(tokenId);
    if (!doc) return null;

    // Derive encryption key
    const encryptionKey = deriveEncryptionKey(agentPrivateKey, tokenId);

    // Decrypt
    const ciphertext = fromBase64(doc.encryptedMemory);
    const nonce = fromBase64(doc.encryptionNonce);
    const content = decryptMemory(ciphertext, nonce, encryptionKey);

    // Verify hash
    if (!verifyMemoryHash(content, doc.memoryHash)) {
      throw new Error('Memory hash verification failed');
    }

    return {
      content,
      memoryHash: doc.memoryHash,
      version: doc.version,
      timestamp: doc.timestamp,
    };
  }

  /**
   * Update agent memory (creates new version)
   */
  async updateMemory(
    tokenId: string,
    agentWallet: string,
    newMemoryContent: string,
    agentPrivateKey: Uint8Array
  ): Promise<StorageResult> {
    // storeMemory handles versioning automatically
    return this.storeMemory(tokenId, agentWallet, newMemoryContent, agentPrivateKey);
  }

  /**
   * Get storage document by token ID
   */
  async getDocument(tokenId: string): Promise<AINFTStorageDocument | null> {
    this.ensureInitialized();

    const documents = await this.client.platform.documents.get(
      'ainftStorage.storage',
      {
        where: [['tokenId', '==', tokenId]],
        orderBy: [['version', 'desc']],
        limit: 1,
      }
    );

    if (documents.length === 0) return null;
    return documents[0].toJSON() as AINFTStorageDocument;
  }

  /**
   * Get all documents for an agent wallet
   */
  async getDocumentsByAgent(agentWallet: string): Promise<AINFTStorageDocument[]> {
    this.ensureInitialized();

    const documents = await this.client.platform.documents.get(
      'ainftStorage.storage',
      {
        where: [['agentWallet', '==', agentWallet.toLowerCase()]],
      }
    );

    return documents.map((d: any) => d.toJSON() as AINFTStorageDocument);
  }

  /**
   * Check storage quota via peg.gg
   */
  async getQuota(ethAddress: string): Promise<{ credits: number; maxCredits: number }> {
    const response = await fetch(
      `${this.config.pegGatewayUrl}/storage/quota/${ethAddress}`
    );

    if (!response.ok) {
      throw new Error(`Failed to get quota: ${await response.text()}`);
    }

    return response.json();
  }

  /**
   * Disconnect client
   */
  async disconnect(): Promise<void> {
    if (this.client) {
      await this.client.disconnect();
    }
  }

  // --- Private helpers ---

  private getLinkMessage(ethAddress: string): string {
    return `Link Dash Identity to ${ethAddress} for Pentagon AINFT storage on peg.gg`;
  }

  private ensureInitialized(): void {
    if (!this.initialized) {
      throw new Error('DashAINFTStorage not initialized. Call init() first.');
    }
  }
}

/**
 * Create storage client with default peg.gg config
 */
export function createDashStorage(
  network: 'testnet' | 'mainnet' = 'testnet'
): DashAINFTStorage {
  const config: DashStorageConfig = {
    network,
    dataContractId: network === 'mainnet' 
      ? 'TBD_MAINNET_CONTRACT_ID' 
      : 'TBD_TESTNET_CONTRACT_ID',
    pegGatewayUrl: network === 'mainnet'
      ? 'https://api.peg.gg'
      : 'https://testnet-api.peg.gg',
  };

  return new DashAINFTStorage(config);
}
