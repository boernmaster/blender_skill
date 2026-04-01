# blender-remote — Claude Code Plugin

Control Blender headlessly with natural language via Claude Code and the blender-remote MCP.

---

## Requirements

- Linux machine with NVIDIA GPU and CUDA drivers
- Blender installed
- `uv` package manager
- Claude Code CLI

---

## Installation

### 1. Install the plugin

```bash
claude plugin marketplace add boernmaster/blender_skill
claude plugin install blender-remote@blender_skill
```

### 2. Install Python dependencies

```bash
uv sync
```

### 3. Install the Blender addon

```bash
blender-remote-cli init --blender-path $(which blender)
blender-remote-cli install
```

### 4. Enable CUDA permanently

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
    except Exception as e:
        print(f"CUDA setup failed: {e}")

import bpy.app.timers
bpy.app.timers.register(enable_cuda, first_interval=1.0)
EOF
```

### 5. Add convenience aliases

Add to `~/.bashrc` (replace `<project-dir>` with your actual path):

```bash
alias blender-start='cd <project-dir> && source .venv/bin/activate && fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null; sleep 1 && blender-remote-cli start --background --port 6688'
alias blender-stop='fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null'
alias blender-restart='blender-stop && sleep 1 && blender-start'
```

```bash
source ~/.bashrc
```

---

## Starting a Session

Two terminals are required. Both must stay running.

**Terminal 1 — start Blender:**
```bash
blender-start
```

**Terminal 2 — start Claude Code:**
```bash
source .venv/bin/activate
claude
```

Verify the MCP connection inside Claude Code:
```
/mcp
```

`blender` must appear as an active server before issuing any commands.

---

## Skills

The plugin provides four skills that load automatically when relevant:

| Skill | Use when you want to... |
|-------|------------------------|
| `session-setup` | Start/stop/restart Blender, fix MCP or CUDA issues |
| `scene-materials` | Set up lighting, assign metallic materials, add HDRI |
| `cad-import` | Import STL/OBJ files, read Excel BOM, batch import |
| `rendering` | Configure Cycles/CUDA, render frames, export GIF |

---

## Example Prompts

```
Import all STL files from /data/parts and assign materials from bom.xlsx
```

```
Set up three-point studio lighting with a white shadow-catching floor
```

```
Render a 360° orbit animation and save as /tmp/output.gif
```

```
Enable CUDA and render the current scene to /tmp/render.png at 1920x1080
```

---

## Troubleshooting

**Port in use**
```bash
fuser -k 6688/tcp
```

**CUDA not detected**
```bash
nvidia-smi
blender-remote-cli init --blender-path $(which blender)
```

**`blender` not listed in `/mcp`** — restart Blender in Terminal 1, then check again.

**Addon install fails**
```bash
blender-remote-cli install --force
```
