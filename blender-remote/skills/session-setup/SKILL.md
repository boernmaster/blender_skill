---
name: session-setup
description: >
  This skill should be used when the user asks to start Blender, stop Blender,
  restart Blender, check the MCP connection, set up a Blender session, or
  troubleshoot "blender not connected", "MCP not found", "port in use", or
  "CUDA not detected" errors.
---

# Blender Remote Session Setup

## Automatic Setup Check (SessionStart hook)

Every time Claude Code starts, the plugin's `SessionStart` hook checks whether the `blender` MCP server is registered:

- **MCP found** — nothing to do, session proceeds normally.
- **MCP not found** — the hook automatically:
  1. Runs `uv sync` to install all dependencies (`blender-remote`, `openpyxl`, `bpy`, …)
  2. Registers the `blender` MCP server via `claude mcp add`
  3. Prints a message: `[blender-remote] MCP registered. Start Blender with: blender-start`

This means first-time setup is fully automatic — no manual `uv sync` or `claude mcp add` needed.

## Manual Setup (if auto-setup fails)

```bash
cd <plugin-dir>
uv sync
claude mcp add blender \
  -e BLENDER_HOST=localhost \
  -e BLENDER_PORT=6688 \
  -- uvx blender-remote --host localhost --port 6688
```

## Starting a Session

Two terminals are required on the same machine. Both must stay running — if Blender Remote stops, the MCP connection is lost.

**Terminal 1 — start Blender headless:**
```bash
blender-start
# Equivalent long form:
cd <project-dir> && source .venv/bin/activate \
  && fuser -k 6688/tcp 2>/dev/null \
  ; pkill -f blender 2>/dev/null \
  ; sleep 1 \
  && blender-remote-cli start --background --port 6688
```

**Terminal 2 — start Claude Code:**
```bash
source .venv/bin/activate
claude
```

Inside Claude Code, verify MCP tools are loaded:
```
/mcp
```
`blender` must appear as an active server before issuing any Blender commands.

## Convenience Aliases

If the aliases are not yet set up, add them to `~/.bashrc` (replace `<project-dir>` with the actual path):

```bash
alias blender-start='cd <project-dir> && source .venv/bin/activate && fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null; sleep 1 && blender-remote-cli start --background --port 6688'
alias blender-stop='fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null'
alias blender-restart='blender-stop && sleep 1 && blender-start'
```

Then reload: `source ~/.bashrc`

## Stopping and Restarting

```bash
blender-stop      # kill Blender and free port 6688
blender-restart   # stop then start in one command
```

## Project Structure — Scripts and CLAUDE.md

### Save generated scripts locally

Every Python script executed via the MCP should also be saved to a local `scripts/` folder so it can be inspected, reused, and version-controlled. Create the folder once:

```bash
mkdir -p scripts
```

Name scripts descriptively, e.g.:
- `scripts/import_battery_pack.py`
- `scripts/setup_studio_lighting.py`
- `scripts/render_orbit_animation.py`

When asked to execute a Blender script, always write it to `scripts/<name>.py` first, then send it to Blender via the MCP tool.

### Maintain a CLAUDE.md

Create or update a `CLAUDE.md` in the project root to document project-specific paths and settings. Claude Code reads this file at session start, so it is the right place for persistent context.

Minimal template — adapt paths to your setup:

```markdown
# Blender Remote — Project Context

## Environment
- Blender port: 6688
- Project dir: /path/to/project
- Scripts dir: /path/to/project/scripts
- Data dir: /path/to/project/data

## Data Files
- CAD assembly: data/<filename>.stp  (convert to GLTF before import)
- BOM spreadsheet: data/<filename>.xlsx

## Custom Settings
- Render output: /tmp/renders/
- Default resolution: 1920x1080
- Default samples: 128
```

Update `CLAUDE.md` whenever new data files are added or project paths change.

## Troubleshooting

### Port already in use
```bash
fuser -k 6688/tcp
# or identify the process first:
ss -tulpn | grep 6688
kill <PID>
```

### CUDA not detected
Check that NVIDIA drivers are working:
```bash
nvidia-smi
```

Verify Blender detects the GPU:
```bash
blender --background --python-expr "
import bpy
cprefs = bpy.context.preferences.addons['cycles'].preferences
cprefs.get_devices()
for d in cprefs.devices:
    print(d.name, d.type, d.use)
"
```

CUDA is enabled persistently via a startup script at:
`~/.config/blender/<version>/scripts/startup/enable_cuda.py`

If the file is missing, recreate it:
```bash
BLENDER_VERSION=$(blender --version | head -1 | awk '{print $2}' | cut -d. -f1,2)
mkdir -p ~/.config/blender/$BLENDER_VERSION/scripts/startup

cat > ~/.config/blender/$BLENDER_VERSION/scripts/startup/enable_cuda.py << 'EOF'
import bpy

def enable_cuda():
    try:
        cprefs = bpy.context.preferences.addons['cycles'].preferences
        cprefs.compute_device_type = 'CUDA'
        cprefs.get_devices()
        for device in cprefs.devices:
            device.use = (device.type == 'CUDA')
        bpy.context.scene.cycles.device = 'GPU'
        bpy.context.scene.render.engine = 'CYCLES'
        bpy.ops.wm.save_userpref()
        print("CUDA enabled:", [d.name for d in cprefs.devices if d.use])
    except Exception as e:
        print(f"CUDA setup failed: {e}")

import bpy.app.timers
bpy.app.timers.register(enable_cuda, first_interval=1.0)
EOF
```

### `requests` module missing (addon install error)
Run in Blender's Python console (Scripting workspace):
```python
import subprocess, sys
subprocess.call([sys.executable, '-m', 'pip', 'install', 'requests'])
```

### `blender-remote-cli init` fails (no auto-detect)
```bash
blender-remote-cli init --blender-path $(which blender)
```

### Re-register MCP server
```bash
claude mcp remove blender
claude mcp add blender \
  -e BLENDER_HOST=localhost \
  -e BLENDER_PORT=6688 \
  -- uvx blender-remote --host localhost --port 6688
claude mcp list
```
