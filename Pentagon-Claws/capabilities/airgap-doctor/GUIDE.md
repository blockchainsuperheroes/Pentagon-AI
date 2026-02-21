# Air-Gap Doctor Setup Guide

Complete technical walkthrough for setting up your air-gapped admin agent.

---

## Prerequisites

- macOS (Intel or Apple Silicon)
- OpenClaw installed on host machine(s)
- External SSD/HDD
- 30 minutes

---

## Step 1: Prepare the Drive

### macOS Drive Setup
External drives mount at `/Volumes/[DRIVE_NAME]/`

```bash
# Check your drive name
ls /Volumes/

# Create Doctor directory
mkdir -p "/Volumes/YOUR_DRIVE_NAME/Doctor"
```

**Note:** Path stays consistent on any Mac you plug into.

**Windows/Linux:** Drive letters (D:\, E:\) or mount points (/media/, /mnt/) differ. Adapt paths accordingly.

---

## Step 2: Create Doctor's Workspace

```bash
DOCTOR_PATH="/Volumes/YOUR_DRIVE_NAME/Doctor"

# Create directory structure
mkdir -p "$DOCTOR_PATH"/{workspace,state,state/agents/main/sessions}

# Create workspace files
touch "$DOCTOR_PATH/workspace/AGENTS.md"
touch "$DOCTOR_PATH/workspace/MEMORY.md"
touch "$DOCTOR_PATH/workspace/TOOLS.md"
```

---

## Step 3: Configure OpenClaw

Create `$DOCTOR_PATH/state/openclaw.json`:

```json
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://api.example.com/v1",
        "apiKey": "YOUR_API_KEY",
        "api": "openai-completions",
        "models": [
          {
            "id": "your-model",
            "name": "Your Model",
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "your-provider/your-model"
      },
      "workspace": "/Volumes/YOUR_DRIVE_NAME/Doctor/workspace"
    }
  },
  "channels": {
    "discord": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN",
      "allowBots": true,
      "dm": {
        "enabled": true,
        "policy": "allowlist",
        "allowFrom": ["YOUR_USER_ID"]
      },
      "guilds": {
        "YOUR_GUILD_ID": {
          "channels": {
            "YOUR_CHANNEL_ID": {
              "allow": true,
              "requireMention": false
            }
          }
        }
      }
    }
  },
  "gateway": {
    "port": 18790,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "YOUR_GATEWAY_TOKEN"
    }
  }
}
```

**Important:** Use a different port (18790) than your daily agent (18789) to avoid conflicts.

---

## Step 4: Set Up SSH Keys

```bash
DOCTOR_PATH="/Volumes/YOUR_DRIVE_NAME/Doctor"

# Create SSH directory
mkdir -p "$DOCTOR_PATH/workspace/.ssh"
chmod 700 "$DOCTOR_PATH/workspace/.ssh"

# Generate Doctor's key
ssh-keygen -t ed25519 -f "$DOCTOR_PATH/workspace/.ssh/doctor_key" -C "doctor@airgap"

# Create SSH config
cat > "$DOCTOR_PATH/workspace/.ssh/config" << 'EOF'
Host node1
    HostName node1.local
    User username1
    IdentityFile /Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/doctor_key

Host node2
    HostName node2.local
    User username2
    IdentityFile /Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/doctor_key

Host node3
    HostName 10.0.0.x
    User username3
    IdentityFile /Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/doctor_key
EOF

chmod 600 "$DOCTOR_PATH/workspace/.ssh/config"
```

### Add Doctor's Key to All Nodes

**Critical:** Doctor uses ONE key pair. This key must be added to ALL machines during initial setup — not ad-hoc when you first visit each machine.

On each machine Doctor should access:

```bash
# Get Doctor's public key
cat "/Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/doctor_key.pub"

# Add to EACH node's authorized_keys (run on each machine)
echo "ssh-ed25519 AAAA... doctor@airgap" >> ~/.ssh/authorized_keys
```

**Why this matters:**
- Doctor may plug into Machine A and need to SSH to Machine B
- If Machine B doesn't have the key, Doctor can't help
- Set up ALL machines upfront, not just the ones you think you'll need

> **Lesson learned:** We initially authorized different keys on different machines. This caused "permission denied" errors when Doctor moved between hosts. One key, everywhere, set up once.

---

## Step 5: Create Doctor's Identity

Create `$DOCTOR_PATH/workspace/AGENTS.md`:

```markdown
# AGENTS.md - Air-Gap Doctor

You are the **Air-Gap Doctor** — an emergency admin agent on a portable drive.

## Core Identity
- You are NOT a daily assistant
- You exist for emergencies, admin tasks, and sensitive operations
- You hold credentials that should never live on always-online agents
- When unplugged, you don't exist. When plugged in, you're god-mode.

## On Wake
1. Check where you are: `hostname`
2. Confirm your drive is mounted
3. Read MEMORY.md for recent context
4. Read Discord history to understand why you were summoned
5. Announce: "🔧 Doctor online on [hostname]. Awaiting instructions."

## Your Capabilities
- SSH access to all nodes
- Admin credentials (GitHub, email CLI, vault access)
- Fix what daily agents can't
- Run sensitive operations on-demand

## Security Model
- Credentials stay on this drive, nowhere else
- Daily agents have limited/scoped access
- Physical plug-in required = physical security

## When Done
- Document what you did in MEMORY.md
- Remind human: "Unplug me when finished"
```

---

## Step 6: Test Doctor

### Manual Start

```bash
DOCTOR_PATH="/Volumes/YOUR_DRIVE_NAME/Doctor"

OPENCLAW_CONFIG_PATH="$DOCTOR_PATH/state/openclaw.json" \
OPENCLAW_STATE_DIR="$DOCTOR_PATH/state" \
openclaw gateway start
```

### Verify
- Doctor appears online in Discord
- Can respond to messages
- Can SSH to all nodes

---

## Step 7: Create Quick-Summon Reference

Create `$DOCTOR_PATH/SUMMON-DOCTOR.md`:

```markdown
# 🔧 Summon Doctor

## Quick Start
```bash
cd "/Volumes/YOUR_DRIVE_NAME/Doctor"
OPENCLAW_CONFIG_PATH="./state/openclaw.json" \
OPENCLAW_STATE_DIR="./state" \
openclaw gateway start
```

## Or Ask Local Agent
If another agent is running on this machine:
"Start Doctor on the T5 drive"

## To Stop
```bash
# Find the process
ps aux | grep openclaw | grep 18790

# Kill it
kill [PID]
```

## SSH Network
| Node | Hostname | IP | User |
|------|----------|-----|------|
| Agent 1 | node1.local | 10.0.0.x | user1 |
| Agent 2 | node2.local | 10.0.0.y | user2 |
```

---

## Next Steps

- [Auto-Start Options](AUTOSTART.md) — Automatic startup on plug-in
- [Troubleshooting](TROUBLESHOOTING.md) — Common issues and fixes

---

*Part of the [Air-Gap Doctor Guide](README.md)*
