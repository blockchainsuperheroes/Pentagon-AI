# AINFT ↔ Dash Platform Integration Notes

*Started: 2026-02-25*

## Architecture Decision

**Identity anchor: TBA (Token-Bound Account)**

- tokenId → TBA (deterministic via ERC-6551) → Dash Identity
- TBA address doesn't change on transfer
- Agent EOA changes when sold, but storage persists
- TBA is the vault, Agent is the operator

## Mainnet Identity (PRODUCTION)

- **Username:** `cerise911.dash`
- **Identity ID:** `DHcf6i3xGvEXbktfDjx6u59MDGh3mm6uTtSbikaWq9NB`
- **Mnemonic:** See SECRETS.md (quick wood bar...)
- **Created:** 2026-02-25 via bridge.thepasta.org

## Testnet Identity

- **Identity ID:** `rDg4jXgHunvA1QJZJ4fKritZC1svf3iN74HNxKJDYGn`
- **Mnemonic:** `upon atom cash grant false token copper limb various punch medal hunt`
- **Balance:** ~99.8B credits (~1 tDASH)

## Funded Wallet (Mainnet)

- **Address:** `XxZ8UN9qF4zpNpZDfYAYwwF6jdxmK4z3Lx`
- **Mnemonic:** See SECRETS.md (spend universe...)
- **Balance:** ~0.09 DASH (after identity creation)

## Open Questions

1. **How does TBA sign for Dash identity?**
   - Option A: Derive Dash key from TBA address deterministically
   - Option B: TBA holds Dash private key as asset
   - Option C: Agent EOA signs on behalf of TBA (delegated)

2. **Where to store Dash Identity ID?**
   - Contract storage (mapping tokenId → dashIdentityId)
   - TBA metadata
   - Emitted event only (cheaper, queryable)

3. **Key rotation on transfer()?**
   - Old agent can't access new agent's writes
   - But should be able to read historical data?
   - Encryption key derived from... what?

## SDK Issues (2026-02-25)

### JavaScript SDK
- **Issue:** Wallet sync times out or crashes with integer overflow
- **Error:** `ERR_OUT_OF_RANGE: value is out of range (must be >= 0 and <= 4294967295, received 21_528_737_287)` in `BlockHeader.toBufferWriter`
- Contract schema validates and creates locally, but `platform.contracts.publish()` fails

### Rust SDK
- **Issue:** DAPI connection times out
- Built successfully, but `DapiClient` requests to mainnet endpoints hang
- Needs clarification on correct DAPI endpoints

### What Works
- **Bridge (bridge.thepasta.org):** Identity creation, DPNS registration, identity top-up
- We have mainnet identity ready to use once SDK issues resolved

### Questions for Dash Team
1. Is there a workaround for contract publishing without full wallet sync?
2. What are the current mainnet DAPI endpoints?
3. Is the Rust SDK stable for data contract operations?
4. Can the bridge be extended to support contract registration?

## Next Steps

- [x] Create mainnet identity (cerise911.dash)
- [x] Install Rust SDK
- [ ] Get SDK guidance from Dash team
- [ ] Create data contract for agent storage
- [ ] Test document write/read
- [ ] Design encryption scheme for agent data
- [ ] Prototype TBA → Dash identity binding

## Resources

- Dash Platform docs: https://docs.dash.org/platform/
- @dashevo/wallet-lib installed in ~/clawd
- ERC-6551 TBA spec: https://eips.ethereum.org/EIPS/eip-6551
