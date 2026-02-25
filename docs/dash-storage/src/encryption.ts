/**
 * Encryption utilities for AINFT memory storage
 * Uses AES-256-GCM with HKDF key derivation
 */

import { gcm } from '@noble/ciphers/aes';
import { hkdf } from '@noble/hashes/hkdf';
import { sha256 } from '@noble/hashes/sha256';
import { randomBytes } from '@noble/ciphers/webcrypto';
import { bytesToHex, hexToBytes } from '@noble/hashes/utils';

const NONCE_LENGTH = 12; // 96 bits for AES-GCM
const KEY_LENGTH = 32;   // 256 bits

/**
 * Derive deterministic encryption key from agent's private key and token ID
 * Uses HKDF with SHA-256
 */
export function deriveEncryptionKey(
  privateKey: Uint8Array,
  tokenId: string
): Uint8Array {
  const salt = new TextEncoder().encode(`pentagon-ainft-${tokenId}`);
  const info = new TextEncoder().encode('ainft-memory-encryption');
  
  return hkdf(sha256, privateKey, salt, info, KEY_LENGTH);
}

/**
 * Encrypt memory content using AES-256-GCM
 * Returns encrypted data with nonce prepended
 */
export function encryptMemory(
  content: string,
  encryptionKey: Uint8Array
): { ciphertext: Uint8Array; nonce: Uint8Array; hash: string } {
  const plaintext = new TextEncoder().encode(content);
  const nonce = randomBytes(NONCE_LENGTH);
  
  const cipher = gcm(encryptionKey, nonce);
  const ciphertext = cipher.encrypt(plaintext);
  
  // Hash plaintext for on-chain verification
  const hash = bytesToHex(sha256(plaintext));
  
  return { ciphertext, nonce, hash };
}

/**
 * Decrypt memory content using AES-256-GCM
 */
export function decryptMemory(
  ciphertext: Uint8Array,
  nonce: Uint8Array,
  encryptionKey: Uint8Array
): string {
  const cipher = gcm(encryptionKey, nonce);
  const plaintext = cipher.decrypt(ciphertext);
  
  return new TextDecoder().decode(plaintext);
}

/**
 * Verify memory hash matches content
 */
export function verifyMemoryHash(content: string, expectedHash: string): boolean {
  const plaintext = new TextEncoder().encode(content);
  const actualHash = bytesToHex(sha256(plaintext));
  return actualHash === expectedHash;
}

/**
 * Encode bytes to base64
 */
export function toBase64(data: Uint8Array): string {
  return Buffer.from(data).toString('base64');
}

/**
 * Decode base64 to bytes
 */
export function fromBase64(base64: string): Uint8Array {
  return new Uint8Array(Buffer.from(base64, 'base64'));
}

/**
 * Generate shared ECDH key for multi-party access
 * (Used when agent wants to share access with owner)
 */
export async function deriveSharedKey(
  privateKey: Uint8Array,
  publicKey: Uint8Array
): Promise<Uint8Array> {
  // Import private key
  const privateKeyObj = await crypto.subtle.importKey(
    'raw',
    privateKey,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    ['deriveBits']
  );
  
  // Import public key
  const publicKeyObj = await crypto.subtle.importKey(
    'raw',
    publicKey,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    []
  );
  
  // Derive shared secret
  const sharedBits = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: publicKeyObj },
    privateKeyObj,
    256
  );
  
  return new Uint8Array(sharedBits);
}
