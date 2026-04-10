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
Blender is started directly from Claude — no second terminal needed.

---

## Step 1 — Check and fix dependencies

Run all checks in order. Fix each one before continuing.

### 1a. Python venv ⚠️ MANDATORY

Check:
```bash
test -f .venv/bin/blender-remote-cli || test -f .venv/Scripts/blender-remote-cli.exe
```

If missing → **create immediately, do not skip**:
```bash
uv sync
```

If `uv sync` fails → stop, report the error, do not continue. Everything else depends on the venv.

### 1b. Blender executable

Search in order:
1. `which blender` (Linux/macOS)
2. `ls "/c/Program Files/Blender Foundation/"*/blender.exe 2>/dev/null | sort -V | tail -1` (Windows Git Bash)

Store the result as `BLENDER_EXE`.

If not found → ask the user for the path. Do not continue until resolved.

### 1c. Blender addon

Check:
```bash
.venv/bin/blender-remote-cli list 2>/dev/null | grep -q blender_remote
```

If missing → install:
```bash
.venv/bin/blender-remote-cli init --blender-path "$BLENDER_EXE"
.venv/bin/blender-remote-cli install
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

### 1f. Shell aliases (optional convenience)

Check:
```bash
grep -q "blender-start" ~/.bashrc 2>/dev/null || grep -q "blender-start" ~/.bash_profile 2>/dev/null
```

If missing → append:
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

## Step 2 — Start Blender

Start Blender headless in the background directly from Claude:

```bash
cd <project-dir> \
  && source .venv/bin/activate \
  && fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null; sleep 1 \
  && nohup blender-remote-cli start --background --port 6688 > /tmp/blender-remote.log 2>&1 &
```

Wait ~3 seconds, then verify the connection using the MCP tool:

```
mcp: blender / check_connection_status
```

If the connection check fails:
1. Check the log: `tail /tmp/blender-remote.log`
2. Check if port is already in use: `fuser -k 6688/tcp` then retry
3. Re-run the start command

---

## Step 3 — Report status

After all steps complete, print a single short status line:

> Setup complete. Blender running on port 6688, MCP connected.

Or if a step failed:

> Setup failed at [step]. Error: [message].

---

## Stop / Restart Blender

**Stop:**
```bash
fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null
```

**Restart:** run Stop, then Step 2.

---

## Troubleshooting reference

### Port in use
```bash
fuser -k 6688/tcp
```

### CUDA not detected
```bash
nvidia-smi
.venv/bin/blender-remote-cli init --blender-path "$BLENDER_EXE"
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
.venv\Scripts\blender-remote-cli init --blender-path "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"
.venv\Scripts\blender-remote-cli install
```
