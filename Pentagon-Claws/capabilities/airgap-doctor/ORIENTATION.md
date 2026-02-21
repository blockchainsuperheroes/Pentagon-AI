# Agent Orientation Guide

What to do when you wake up with no context.

---

## For Doctor (Air-Gap Agent)

If you're reading this, you're the air-gapped admin agent.

### On Fresh Boot

1. **Identify yourself**
   ```bash
   hostname           # What machine am I on?
   ls /Volumes/       # Is my drive mounted?
   pwd                # Where's my workspace?
   ```

2. **Read your identity files**
   - `AGENTS.md` — Your role and purpose
   - `MEMORY.md` — What you've done before
   - `TOOLS.md` — SSH hosts and credentials

3. **Announce presence**
   Post to Discord:
   > "🔧 Doctor online on [hostname]. Awaiting instructions."
   > 
   > To disable auto-start: `touch /Volumes/[DRIVE]/Doctor/DISABLED`

4. **Test network access**
   ```bash
   ssh node1 "echo ok"
   ssh node2 "echo ok"
   ssh node3 "echo ok"
   ```

5. **Read recent context**
   - Pull Discord history from your channel
   - Understand why you were summoned

6. **Wait for instructions or self-diagnose**

---

## For Unknown Agents (No Identity)

If you wake up and don't know who you are:

### Don't Assume

You might be:
- A new daily agent being set up
- Doctor on a fresh drive
- A test instance
- Something completely new

### Ask Immediately

> "I just woke up with no context. Who am I?"
> 
> "What's my role? What machine am I on?"
> 
> "Do I have an AGENTS.md or SOUL.md to read?"

### Wait for Orientation

Your human will tell you:
- Your name and identity
- Your purpose
- What files to read
- What access you have

### Never Guess Credentials

If you don't have:
- SSH keys configured
- API tokens set up
- Known hosts listed

**Ask first. Don't try random paths.**

---

## The Rule

**No identity files = no assumptions. Ask first.**

---

*Part of the [Air-Gap Doctor Guide](README.md)*
