# Auto-Start Options

Three ways to summon Doctor, from most manual to most automatic.

---

## Option A: Manual Only (Most Secure)

**How it works:** You plug in the drive, open Terminal, run the command.

```bash
cd "/Volumes/YOUR_DRIVE_NAME/Doctor"
OPENCLAW_CONFIG_PATH="./state/openclaw.json" \
OPENCLAW_STATE_DIR="./state" \
openclaw gateway start
```

**Pros:**
- Maximum control
- True air-gap (no auto-execution)
- Works on any machine without setup

**Cons:**
- Requires Terminal knowledge
- Easy to forget the command

**Best for:** Security-conscious users, infrequent use

---

## Option B: LaunchAgent Auto-Start (Convenient)

**How it works:** macOS watches for your drive. When mounted, Doctor starts automatically.

### Setup

Create `~/Library/LaunchAgents/com.doctor.airgap.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.doctor.airgap</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>
            DOCTOR_PATH="/Volumes/YOUR_DRIVE_NAME/Doctor"
            if [ -d "$DOCTOR_PATH" ] && [ ! -f "$DOCTOR_PATH/DISABLED" ]; then
                export OPENCLAW_CONFIG_PATH="$DOCTOR_PATH/state/openclaw.json"
                export OPENCLAW_STATE_DIR="$DOCTOR_PATH/state"
                /usr/local/bin/node /path/to/openclaw/dist/index.js gateway --port 18790
            fi
        </string>
    </array>
    
    <key>WatchPaths</key>
    <array>
        <string>/Volumes/YOUR_DRIVE_NAME</string>
    </array>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>StandardOutPath</key>
    <string>/tmp/doctor-airgap.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/doctor-airgap.err</string>
</dict>
</plist>
```

### Install

```bash
# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.doctor.airgap.plist
```

### Enable/Disable Toggle

```bash
# Disable auto-start (Doctor won't launch on plug-in)
touch "/Volumes/YOUR_DRIVE_NAME/Doctor/DISABLED"

# Re-enable auto-start
rm "/Volumes/YOUR_DRIVE_NAME/Doctor/DISABLED"
```

**Pros:**
- Plug and play
- No Terminal needed
- DISABLED flag for override

**Cons:**
- Requires setup on each machine
- Node path may vary by machine
- Less "air-gapped" (auto-execution)

**Best for:** Frequent use, multiple machines with setup done

---

## Option C: Shell Profile Check (Middle Ground)

**How it works:** Add a check to your `.zshrc` or `.bashrc`. On every new terminal, it checks if Doctor's drive is mounted and offers to start.

### Setup

Add to `~/.zshrc`:

```bash
# Doctor auto-detect
DOCTOR_PATH="/Volumes/YOUR_DRIVE_NAME/Doctor"
if [ -d "$DOCTOR_PATH" ] && [ ! -f "$DOCTOR_PATH/DISABLED" ]; then
    echo "🔧 Doctor drive detected. Start Doctor? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        export OPENCLAW_CONFIG_PATH="$DOCTOR_PATH/state/openclaw.json"
        export OPENCLAW_STATE_DIR="$DOCTOR_PATH/state"
        openclaw gateway start &
    fi
fi
```

**Pros:**
- Prompts but doesn't auto-run
- Works on any machine with shell config
- Human confirmation required

**Cons:**
- Only triggers on new terminal window
- Requires shell config on each machine

**Best for:** Users who want awareness without full automation

---

## Recommendation

| Use Case | Recommended Option |
|----------|-------------------|
| Maximum security | Option A (Manual) |
| Daily use, setup done | Option B (LaunchAgent) |
| Occasional use, prompts | Option C (Shell check) |

**Note:** Options B and C require setup on each machine where you might plug in Doctor. If you use many different machines, Option A (manual) may be simpler overall.

---

*Part of the [Air-Gap Doctor Guide](README.md)*
