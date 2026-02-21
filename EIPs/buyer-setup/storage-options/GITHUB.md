# GitHub Storage

*Centralized but free and convenient*

---

## Overview

- **Permanence:** Until deleted or account closed
- **Cost:** Free
- **Requires:** GitHub account
- **Best for:** Quick sharing, development, public backups

---

## ⚠️ Warning

GitHub is **centralized**. Microsoft can:
- Delete your repo
- Suspend your account
- Change terms of service

For critical backups, **also use Arweave/Dash Platform**.

---

## Setup

### Create Backup Repo

```bash
# Create private repo
gh repo create my-agent-backups --private

# Clone
git clone https://github.com/yourusername/my-agent-backups
cd my-agent-backups
```

### Add Backup

```bash
# Copy encrypted backup
cp ~/agent/backup-2026-02-21.enc .

# Commit
git add backup-2026-02-21.enc
git commit -m "Backup 2026-02-21"
git push
```

---

## Recovery

```bash
# Clone repo
git clone https://github.com/yourusername/my-agent-backups

# Or download raw file
curl -L -o backup.enc \
  https://github.com/yourusername/my-agent-backups/raw/main/backup-2026-02-21.enc
```

---

## Public vs Private

| Visibility | Use Case |
|------------|----------|
| **Public** | Open source agents, examples, demos |
| **Private** | Personal backups, sensitive agents |

**Note:** Even encrypted backups reveal metadata (file size, dates). Use private repos for real agents.

---

## Automation

```bash
#!/bin/bash
# github-backup.sh

REPO="$HOME/agent-backups"
DATE=$(date +%Y-%m-%d)
WORKSPACE="$HOME/agent-workspace"
SEED=$(openssl rand -hex 32)

# Create backup
tar -czf - -C $WORKSPACE MEMORY.md SOUL.md AGENTS.md memory/ | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -out $REPO/backup-$DATE.enc \
  -pass pass:$SEED

# Commit and push
cd $REPO
git add backup-$DATE.enc
git commit -m "Backup $DATE"
git push

echo "Seed: $SEED (SAVE THIS)"
```

---

## Pros & Cons

**Pros:**
- Free
- Easy to use
- Version control built-in
- Shareable links

**Cons:**
- **Centralized** (Microsoft)
- Can be deleted
- Account suspension risk
- Not truly permanent

---

## Recommendation

**Use GitHub for:**
- Development and testing
- Sharing examples
- Quick transfers
- Secondary backup

**Always also store on:**
- Arweave (permanent)
- Dash Platform (permanent + aligned)

---

*Pentagon AI — The Human × Agent Economy*
