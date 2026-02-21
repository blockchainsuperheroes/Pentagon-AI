# Troubleshooting

Issues we encountered during setup and their fixes.

---

## First-Time macOS Prompts

When running Doctor on a new machine for the first time, expect these approval dialogs:

| Prompt | What It's For | Action |
|--------|---------------|--------|
| "node would like to access files on a removable volume" | Reading/writing to external SSD | Allow |
| "node would like to access your Documents/Desktop" | If workspace references those paths | Allow (or Deny if not needed) |
| "node would like to control System Events" | If using AppleScript automations | Allow (or Deny if not needed) |
| "node would like to access your contacts" | If email CLI accesses contacts | Your choice |
| Terminal/iTerm "Developer Tools" access | Running CLI commands | Allow |

**Tip:** These only appear once per machine. After approval, Doctor runs without prompts.

**Bulk approve:** System Preferences → Privacy & Security → Full Disk Access → Add `node` or Terminal.

---

## Permission Issues

### "Operation not permitted" on drive access

**Symptom:** Commands fail with permission errors when accessing external drive.

**Cause:** macOS security requires explicit permission for apps to access removable volumes.

**Fix:**
1. When prompted "node would like to access remote volume" → Allow
2. Or: System Preferences → Privacy & Security → Files and Folders → Grant access
3. Or: System Preferences → Privacy & Security → Full Disk Access → Add Terminal/Node

### SSH commands can't write to drive

**Symptom:** Local Terminal can write to drive, but SSH sessions can't.

**Cause:** Permissions granted to Terminal don't carry to SSH subprocess.

**Fix:** Have the local agent (running on that machine) do the writes instead of remote SSH.

---

## Process Issues

### Doctor dies when SSH session closes (EPIPE)

**Symptom:** Started Doctor via SSH, disconnected, Doctor crashes.

**Cause:** Background `&` still ties to SSH session pipe.

**Fix:** Use `nohup` or have local agent start Doctor:
```bash
nohup openclaw gateway start &
```

Or better: Use LaunchAgent or have local agent run the command.

### Can't run two gateways on same machine

**Symptom:** Port conflict or lock file error.

**Cause:** Some machines have issues running multiple OpenClaw instances.

**Fix:**
- Ensure different ports (18789 vs 18790)
- Ensure different state directories
- Some machines may not support dual instances (known issue)

### Doctor keeps restarting after kill

**Symptom:** `kill` the process but it comes back.

**Cause:** LaunchAgent auto-respawns.

**Fix:** Use `launchctl` instead of `kill`:
```bash
launchctl unload ~/Library/LaunchAgents/com.doctor.airgap.plist
```

---

## Network Issues

### "channel unresolved" in Discord

**Symptom:** Doctor can't see Discord channel.

**Cause:** Bot doesn't have View Channel permission in server.

**Fix:** 
1. Discord server settings → Channels → Your channel → Permissions
2. Add Doctor's bot role
3. Grant "View Channel" permission

### Can't see other agents' messages

**Symptom:** Doctor doesn't respond to other bots.

**Cause:** `allowBots` not enabled.

**Fix:** Add to Discord config:
```json
"discord": {
  "allowBots": true,
  ...
}
```

### IP addresses changed

**Symptom:** SSH connections fail to known IPs.

**Cause:** DHCP reassigned addresses.

**Fix:** Use `.local` hostnames instead of IPs:
```
Host node1
    HostName macbook-pro.local
```

Or have Doctor scan the network:
```bash
arp -a | grep -v incomplete
```

---

## Startup Issues

### "node: command not found" or wrong node path

**Symptom:** LaunchAgent fails silently.

**Cause:** Node installed via nvm/volta has non-standard path.

**Fix:** Use full path in LaunchAgent:
```xml
<string>/Users/YOU/.nvm/versions/node/v22.0.0/bin/node</string>
```

Find your path with: `which node`

### Machine sleep kills Doctor

**Symptom:** MacBook sleeps, Doctor stops.

**Cause:** No auto-restart mechanism.

**Fix:**
- Use desktop Mac (iMac/Mac Mini) for longer sessions
- Or: Disable sleep while Doctor is running
- Or: Accept that Doctor stops on sleep (it's air-gapped anyway)

---

## SSH Issues

### "Permission denied (publickey)"

**Symptom:** Doctor can't SSH to nodes.

**Cause:** Public key not in target's authorized_keys, OR you have multiple keys and authorized the wrong one.

**Fix:**
```bash
# On Doctor, get THE public key (the one on T5):
cat /Volumes/YOUR_DRIVE/Doctor/workspace/.ssh/doctor_key.pub

# On target machine, add it:
echo "ssh-ed25519 AAAA... doctor@airgap" >> ~/.ssh/authorized_keys
```

**Common mistake:** Authorizing a key when Doctor runs on Machine A, then Doctor moves to Machine B which has a different key. Always use the key FROM T5, not from the host machine.

### "Too many authentication failures"

**Symptom:** SSH fails immediately with auth failure count.

**Cause:** SSH agent is trying multiple keys before the right one.

**Fix:**
```bash
# Use IdentitiesOnly to force specific key
ssh -o IdentitiesOnly=yes -i /path/to/doctor_key user@host
```

### Doctor looks in wrong .ssh directory

**Symptom:** Using host's keys instead of Doctor's keys.

**Cause:** Not specifying key path.

**Fix:** Always use `-i` flag or SSH config:
```bash
ssh -i /Volumes/YOUR_DRIVE/Doctor/workspace/.ssh/doctor_key user@host
```

---

## General Tips

1. **Check logs:** `/tmp/doctor-airgap.log` and `/tmp/doctor-airgap.err`
2. **Verify mount:** `ls /Volumes/` before running commands
3. **Test SSH manually:** Before blaming config, test with explicit paths
4. **Restart gateway:** When in doubt, stop and restart Doctor
5. **Check port:** `lsof -i :18790` to see what's using Doctor's port

---

*Part of the [Air-Gap Doctor Guide](README.md)*
