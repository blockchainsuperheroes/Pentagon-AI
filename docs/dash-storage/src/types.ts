/**
 * Types for Pentagon AINFT Dash Storage
 */

export interface DashStorageConfig {
  /** Dash network to connect to */
  network: 'testnet' | 'mainnet';
  /** Data contract ID on Dash Platform */
  dataContractId: string;
  /** peg.gg gateway URL */
  pegGatewayUrl: string;
  /** Optional: custom DAPI addresses */
  dapiAddresses?: string[];
}

export interface AINFTStorageDocument {
  /** AINFT token ID on Pentagon Chain */
  tokenId: string;
  /** Agent's derived wallet address (0x...) */
  agentWallet: string;
  /** AES-GCM encrypted memory content (base64) */
  encryptedMemory: string;
  /** SHA256 hash of plaintext for verification */
  memoryHash: string;
  /** AES-GCM nonce (base64) */
  encryptionNonce: string;
  /** Document version (increments on update) */
  version: number;
  /** Unix timestamp of storage */
  timestamp: number;
}

export interface IdentityLinkRequest {
  /** Ethereum address to link */
  ethAddress: string;
  /** EIP-191 signature of link message */
  ethSignature: string;
}

export interface IdentityLinkResponse {
  /** Dash identity ID */
  identityId: string;
  /** Recovery mnemonic (encrypted in production) */
  mnemonic: string;
  /** Credits available for storage */
  credits: number;
}

export interface BurnRequest {
  /** Ethereum address */
  ethAddress: string;
  /** xDASH amount burned */
  amount: string;
  /** Burn transaction hash on Pentagon Chain */
  txHash: string;
}

export interface BurnResponse {
  /** Credits added from this burn */
  creditsAdded: number;
  /** Total credits after burn */
  totalCredits: number;
}

export interface StorageResult {
  /** Dash document ID */
  documentId: string;
  /** State transition hash */
  transitionHash: string;
  /** Storage URI for AINFT contract */
  storageUri: string;
}

export interface RetrievalResult {
  /** Decrypted memory content */
  content: string;
  /** Original memory hash */
  memoryHash: string;
  /** Version retrieved */
  version: number;
  /** Timestamp of storage */
  timestamp: number;
}

export enum StorageType {
  IPFS = 'ipfs',
  Arweave = 'ar',
  Dash = 'dash'
}

export function parseStorageUri(uri: string): { type: StorageType; id: string } {
  if (uri.startsWith('ipfs://')) {
    return { type: StorageType.IPFS, id: uri.slice(7) };
  }
  if (uri.startsWith('ar://')) {
    return { type: StorageType.Arweave, id: uri.slice(5) };
  }
  if (uri.startsWith('dash://')) {
    return { type: StorageType.Dash, id: uri.slice(7) };
  }
  throw new Error(`Unknown storage URI scheme: ${uri}`);
}
