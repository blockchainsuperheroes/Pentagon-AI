/**
 * Direct Sovereign Signing (v2)
 * 
 * Full user control — no wrapper key, no backend private key exposure
 * 
 * Flow:
 * 1. Build state transition object client-side
 * 2. Extract signable bytes (Bincode canonical, exclude sig fields)
 * 3. Hash = double-SHA256(signableBytes)
 * 4. ETH wallet signs the hash directly
 * 5. Attach 65-byte sig + pubkeyId=0 to transition
 * 6. Broadcast directly to public DAPI
 * 
 * References:
 * - Dash Platform Extension: https://github.com/pshenmic/dash-platform-extension
 * - State Transition Signing: https://docs.dash.org/projects/platform/en/stable/docs/protocol-ref/identity.html
 */

import { ethers } from 'ethers';
import { sha256 } from '@noble/hashes/sha256';
import { bytesToHex, hexToBytes } from '@noble/hashes/utils';

/**
 * Double SHA-256 hash (Dash standard)
 */
export function doubleSha256(data: Uint8Array): Uint8Array {
  return sha256(sha256(data));
}

/**
 * Signable bytes from state transition
 * Bincode canonical serialization excluding identityId and signature fields
 */
export interface StateTransitionSignable {
  /** Type of transition */
  type: number;
  /** Protocol version */
  protocolVersion: number;
  /** Transition-specific data */
  data: Record<string, unknown>;
}

/**
 * Serialize state transition to signable bytes (Bincode format)
 * Note: This is a simplified version. Production should use official WASM bindings.
 */
export function serializeForSigning(transition: StateTransitionSignable): Uint8Array {
  // In production, use @dashevo/wasm-dpp for proper Bincode serialization
  // This is a placeholder showing the concept
  const jsonStr = JSON.stringify({
    type: transition.type,
    protocolVersion: transition.protocolVersion,
    ...transition.data,
  });
  return new TextEncoder().encode(jsonStr);
}

/**
 * Create signature for state transition using ETH wallet
 */
export async function signStateTransition(
  signer: ethers.Signer,
  signableBytes: Uint8Array
): Promise<{ signature: Uint8Array; pubkeyId: number }> {
  // Double SHA-256 hash
  const hash = doubleSha256(signableBytes);
  
  // Sign with ETH wallet
  // Use eth_sign for raw hash signing (not personal_sign which prefixes)
  const hashHex = bytesToHex(hash);
  
  // Note: Most wallets use personal_sign which adds prefix
  // For raw hash signing, use signMessage with arrayified hash
  const sig = await signer.signMessage(hash);
  
  // Extract r, s, v from signature
  const sigBytes = hexToBytes(sig.slice(2));
  
  return {
    signature: sigBytes, // 65 bytes: r (32) + s (32) + v (1)
    pubkeyId: 0, // Key type 0 for secp256k1
  };
}

/**
 * Attach signature to state transition
 */
export function attachSignature(
  transitionBytes: Uint8Array,
  signature: Uint8Array,
  pubkeyId: number
): Uint8Array {
  // Append signature structure to transition
  // Format: [...transitionBytes, pubkeyId (1 byte), signature (65 bytes)]
  const result = new Uint8Array(transitionBytes.length + 66);
  result.set(transitionBytes);
  result[transitionBytes.length] = pubkeyId;
  result.set(signature, transitionBytes.length + 1);
  return result;
}

/**
 * Broadcast signed transition to DAPI
 */
export async function broadcastToDapi(
  signedTransition: Uint8Array,
  dapiAddress: string = 'https://seed-1.testnet.networks.dash.org:1443'
): Promise<string> {
  const response = await fetch(`${dapiAddress}/platform/broadcastStateTransition`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/octet-stream' },
    body: signedTransition,
  });

  if (!response.ok) {
    throw new Error(`DAPI broadcast failed: ${await response.text()}`);
  }

  const result = await response.json();
  return result.transitionHash;
}

/**
 * Complete sovereign signing flow
 * 
 * @example
 * ```typescript
 * const transition = buildDocumentTransition(docProperties);
 * const signableBytes = serializeForSigning(transition);
 * const { signature, pubkeyId } = await signStateTransition(signer, signableBytes);
 * const signed = attachSignature(signableBytes, signature, pubkeyId);
 * const hash = await broadcastToDapi(signed);
 * ```
 */
export async function sovereignStore(
  signer: ethers.Signer,
  documentData: Record<string, unknown>,
  identityId: string,
  dataContractId: string
): Promise<string> {
  console.log('⚠️ Sovereign signing requires @dashevo/wasm-dpp for production');
  console.log('This is a reference implementation showing the flow');
  
  // Build state transition
  const transition: StateTransitionSignable = {
    type: 1, // Document create
    protocolVersion: 1,
    data: {
      dataContractId,
      documents: [documentData],
      // Note: identityId excluded from signable bytes
    },
  };

  // Serialize (excluding identityId and signature)
  const signableBytes = serializeForSigning(transition);

  // Sign with ETH wallet
  const { signature, pubkeyId } = await signStateTransition(signer, signableBytes);

  // Attach signature
  const signedTransition = attachSignature(signableBytes, signature, pubkeyId);

  // Broadcast
  const transitionHash = await broadcastToDapi(signedTransition);

  return transitionHash;
}

/**
 * DAPI endpoints for reference
 */
export const DAPI_ENDPOINTS = {
  testnet: [
    'https://seed-1.testnet.networks.dash.org:1443',
    'https://seed-2.testnet.networks.dash.org:1443',
    'https://seed-3.testnet.networks.dash.org:1443',
  ],
  mainnet: [
    'https://seed-1.mainnet.networks.dash.org:1443',
    'https://seed-2.mainnet.networks.dash.org:1443',
    'https://seed-3.mainnet.networks.dash.org:1443',
  ],
};
