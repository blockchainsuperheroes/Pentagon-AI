# Agent Capabilities

**Specialist modules for Pentagon Claws agents**

These capabilities extend what your agent can do — whether cloud-hosted or running locally.

---

## Available Capabilities

### 🎤 Voice Router
Speech-to-text pipeline for voice-controlled agents.
- Whisper GPU transcription
- iOS/Android PWA support
- Sub-second latency

### 🧠 Local Brain
Run inference on your own hardware.
- LAN GPU server setup (RTX 3090/4090/5080)
- Ollama integration
- Fallback to cloud when needed

### 🔒 Security
Hardening and credential management.
- Secrets isolation
- Access control patterns
- Audit logging

### 🩺 Airgap Doctor
Offline diagnostics and recovery.
- Self-healing routines
- Network-independent checks
- Emergency procedures

### 📊 Operations
Monitoring and maintenance guides.
- Health checks
- Resource management
- Update workflows

---

## Adding Capabilities

Each capability is a standalone module. Add what you need:

```bash
# Voice control
cp -r capabilities/voice-router ~/your-agent/

# Local inference
cp -r capabilities/local-brain ~/your-agent/
```

---

## Coming Soon

- **Memory Sync** — Cross-device context persistence
- **Multi-Agent** — Coordination between agents
- **Game Hooks** — Unity/Unreal integration
- **Economic Tools** — On-chain transaction helpers

---

*Build agents that do more.*
