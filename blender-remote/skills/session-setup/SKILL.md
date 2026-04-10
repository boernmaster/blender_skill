---
name: session-setup
description: >
  This skill should be used when the user asks to start Blender, stop Blender,
  restart Blender, check the MCP connection, set up a Blender session, or
  troubleshoot "blender not connected", "MCP not found", "port in use", or
  "CUDA not detected" errors.
---

# Blender Remote Session Setup

## Behavior when this skill is loaded

**Do not ask for confirmation. Run all checks and fix everything that is missing.**
Announce in one line what you are about to do, then execute immediately.

---

## Step 1 — Check and fix dependencies

Run these checks in order. Fix each one that fails before continuing.

### 1a. Python venv

Check: `.venv/` exists in the project root and `blender-remote-cli` is available.

```bash
test -f .venv/bin/blender-remote-cli || test -f .venv/Scripts/blender-remote-cli.exe
```

If missing → install:
```bash
uv sync
```

### 1b. Blender executable

Search in order:
1. `which blender` (Linux/macOS)
2. `ls "/c/Program Files/Blender Foundation/"*/blender.exe 2>/dev/null | sort -V | tail -1` (Windows Git Bash)

Save the result as `BLENDER_EXE`.

If not found → tell the user and ask for the path. Do not continue until resolved.

### 1c. Blender addon

Check:
```bash
blender-remote-cli list 2>/dev/null | grep -q blender_remote
```

If missing → install:
```bash
blender-remote-cli init --blender-path "$BLENDER_EXE"
blender-remote-cli install
```

### 1d. Blender MCP server

Check:
```bash
claude mcp list 2>/dev/null | grep -q blender
```

If missing → register:
```bash
claude mcp add blender \
  -e BLENDER_HOST=localhost \
  -e BLENDER_PORT=6688 \
  -- uvx blender-remote --host localhost --port 6688
```

### 1e. Project folders

Create any missing directories:
```bash
mkdir -p scripts output/frames work
```

### 1f. Shell aliases

Check if `blender-start` alias exists:
```bash
grep -q "blender-start" ~/.bashrc 2>/dev/null || grep -q "blender-start" ~/.bash_profile 2>/dev/null
```

If missing → append to `~/.bashrc` (replace `PROJECT_DIR` with `pwd`):
```bash
PROJECT_DIR=$(pwd)
cat >> ~/.bashrc << EOF

# blender-remote aliases
alias blender-start='cd $PROJECT_DIR && source .venv/bin/activate && fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null; sleep 1 && blender-remote-cli start --background --port 6688'
alias blender-stop='fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null'
alias blender-restart='blender-stop && sleep 1 && blender-start'
EOF
source ~/.bashrc
```

---

## Step 2 — Start Blender (if requested)

If the user asked to start Blender, run:
```bash
blender-start
```

Then verify the MCP connection is live:
```bash
claude mcp list
```

---

## Step 3 — Report status

After all steps complete, print a single short status line, e.g.:

> Setup complete. Blender MCP ready. Run `blender-start` in a terminal to start Blender.

Or if Blender was started:

> Blender running on port 6688. MCP connected.

---

## Troubleshooting reference

### Port in use
```bash
fuser -k 6688/tcp
```

### CUDA not detected
```bash
nvidia-smi
blender-remote-cli init --blender-path "$BLENDER_EXE"
```

### Re-register MCP
```bash
claude mcp remove blender
claude mcp add blender \
  -e BLENDER_HOST=localhost \
  -e BLENDER_PORT=6688 \
  -- uvx blender-remote --host localhost --port 6688
```

### Windows — Blender not in PATH (PowerShell)
```powershell
blender-remote-cli init --blender-path "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"
blender-remote-cli install
```
