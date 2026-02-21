# 🔧 Summon Doctor — Quick Reference

Emergency cheat sheet. Print this and tape it to your SSD.

---

## Before You Summon (The Patient Brief)

Like visiting a clinic — come prepared. Post in your coordination channel:

**Symptoms:** What's broken?
- "Agent 1 is unresponsive"
- "Can't access email"  
- "Need to revoke compromised SSH key"

**History:** What have you tried?
- "Restarted gateway — didn't help"
- "Peer agents couldn't reach via SSH"

**Current state:** What's running?
- "Agent 2 and 3 are up"
- "Agent 1 machine is reachable via ping but gateway down"

**Why this matters:** Doctor reads recent messages on boot. Good notes = faster diagnosis.

> **Note:** We use Discord for coordination. Your setup may use Slack, Telegram, or another channel where agents converge. Adapt accordingly.

---

## Quick Start (Manual)

```bash
cd "/Volumes/YOUR_DRIVE_NAME/Doctor"

OPENCLAW_CONFIG_PATH="./state/openclaw.json" \
OPENCLAW_STATE_DIR="./state" \
openclaw gateway start
```

---

## If You Have a Local Agent Running

Just ask it:
> "Start Doctor on the external drive"

---

## To Stop Doctor

```bash
# Find the process
ps aux | grep openclaw | grep 18790

# Kill it
kill [PID]

# Or if using LaunchAgent:
launchctl unload ~/Library/LaunchAgents/com.doctor.airgap.plist
```

---

## Disable Auto-Start

```bash
# Create DISABLED flag
touch "/Volumes/YOUR_DRIVE_NAME/Doctor/DISABLED"

# Re-enable later
rm "/Volumes/YOUR_DRIVE_NAME/Doctor/DISABLED"
```

---

## SSH to Nodes

```bash
# Use Doctor's SSH config
ssh -F /Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/config node1
ssh -F /Volumes/YOUR_DRIVE_NAME/Doctor/workspace/.ssh/config node2
```

---

## Something's Wrong?

1. **Is the drive mounted?** `ls /Volumes/`
2. **Is Doctor running?** `ps aux | grep openclaw`
3. **Check logs:** `cat /tmp/doctor-airgap.log`
4. **Port in use?** `lsof -i :18790`

---

## Network Quick Reference

Update this with your actual network:

| Node | Hostname | IP | User |
|------|----------|-----|------|
| Agent 1 | ?.local | 10.0.0.? | ? |
| Agent 2 | ?.local | 10.0.0.? | ? |
| Agent 3 | ?.local | 10.0.0.? | ? |

---

*Full guide: [README.md](README.md)*
