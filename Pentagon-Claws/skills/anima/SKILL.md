# ANIMA Skill

Agent capabilities for working with the ANIMA standard.

## What This Skill Does

- Backup agent state to Arweave
- Update on-chain memory hash
- Verify backup integrity
- Restore from ANIMA

## Prerequisites

- ANIMA contract deployed
- Agent has Token-Bound Account
- Arweave/bundlr access

## Commands

### Backup State

```bash
# Package and encrypt state
anima backup --tokenId 42 --files "MEMORY.md,SOUL.md,config.json"

# Upload to Arweave and update on-chain
anima commit --tokenId 42
```

### Verify Backup

```bash
# Test decrypt with current owner key
anima verify --tokenId 42
```

### Restore

```bash
# Download and decrypt from Arweave
anima restore --tokenId 42 --output ./restored/
```

## Integration with OpenClaw

Add to HEARTBEAT.md for automatic backups:

```markdown
## ANIMA Backup
- Check if backup needed (last > 24h)
- Run: anima backup && anima commit
- Log result to memory/anima-backups.json
```

## Configuration

```json
{
  "anima": {
    "contractAddress": "0x...",
    "tokenId": 42,
    "chain": {
      "rpc": "https://rpc.pentagon.games",
      "chainId": 3344
    },
    "storage": "arweave",
    "backupInterval": "24h"
  }
}
```

## Related

- [ANIMA Specification](../../../EIPs/README.md)
- [Agent Backup Guide](../../../EIPs/AGENT-BACKUP-GUIDE.md)
