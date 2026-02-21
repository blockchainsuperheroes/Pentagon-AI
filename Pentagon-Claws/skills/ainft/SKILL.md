# AINFT Skill

Agent capabilities for working with the AINFT standard.

## What This Skill Does

- Backup agent state to Arweave
- Update on-chain memory hash
- Verify backup integrity
- Restore from AINFT

## Prerequisites

- AINFT contract deployed
- Agent has Token-Bound Account
- Arweave/bundlr access

## Commands

### Backup State

```bash
# Package and encrypt state
ainft backup --tokenId 42 --files "MEMORY.md,SOUL.md,config.json"

# Upload to Arweave and update on-chain
ainft commit --tokenId 42
```

### Verify Backup

```bash
# Test decrypt with current owner key
ainft verify --tokenId 42
```

### Restore

```bash
# Download and decrypt from Arweave
ainft restore --tokenId 42 --output ./restored/
```

## Integration with OpenClaw

Add to HEARTBEAT.md for automatic backups:

```markdown
## AINFT Backup
- Check if backup needed (last > 24h)
- Run: ainft backup && ainft commit
- Log result to memory/ainft-backups.json
```

## Configuration

```json
{
  "ainft": {
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

- [AINFT Specification](../../../EIPs/README.md)
- [Agent Backup Guide](../../../EIPs/AGENT-BACKUP-GUIDE.md)
