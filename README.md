# Blender Remote MCP Setup with Claude Code

This guide covers setting up `blender-remote` on a remote Linux machine, connecting it to Claude Code via MCP, enabling CUDA permanently, and starting a session.

---

## Prerequisites

- Linux machine with NVIDIA GPU and CUDA drivers installed
- `uv` package manager
- Claude Code CLI
- Blender installed

---

## 1. Install uv (remote machine)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

---

## 2. Install Claude Code (remote machine)

```bash
curl -fsSL https://claude.ai/install.sh | bash
source ~/.bashrc
claude --version
```

---

## 3. Set up the Python project with uv

Clone this repository and let `uv` install all dependencies from `pyproject.toml`:

```bash
git clone https://dapt-gitlab.avl.com/kalteneb/blender.git
cd blender
uv sync
```

This installs `blender-remote`, `bpy`, `openpyxl`, and all transitive
dependencies into a local `.venv`. Activate the environment:

```bash
source .venv/bin/activate
```

To add new packages later:

```bash
uv add <package-name>
```

---

## 4. Find your Blender executable (remote machine)

```bash
which blender
# Common locations:
# /usr/bin/blender              (apt/dnf)
# /snap/bin/blender             (snap)
# ~/blender-4.x/blender         (manual)
# /opt/blender/blender          (custom install)
```

---

## 5. Initialize and install the addon (remote machine)

```bash
# Point blender-remote at your Blender installation
blender-remote-cli init --blender-path $(which blender)

# Install the bld_remote_mcp addon into Blender
blender-remote-cli install
```

If `install` fails, do it manually:

```bash
BLENDER_VERSION=$(blender --version | head -1 | awk '{print $2}' | cut -d. -f1,2)

blender-remote-cli export --content=addon -o ~/bld_addon

cp -r ~/bld_addon/bld_remote_mcp \
  ~/.config/blender/$BLENDER_VERSION/scripts/addons/

blender --background --python-expr "
import bpy, addon_utils
addon_utils.enable('bld_remote_mcp', default_set=True)
bpy.ops.wm.save_userpref()
"
```

---

## 6. Enable CUDA permanently (remote machine)

Create a Blender startup script so CUDA is always active:

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

---

## 7. Install the Claude Code plugin (remote machine)

This repository is a Claude Code marketplace. Install the `blender-remote` plugin directly from GitHub — it registers the MCP server and loads all skills automatically:

```bash
claude plugin marketplace add boernmaster/blender_skill
claude plugin install blender-remote@blender_skill
```

The plugin bundles:
- **MCP server** — registers `blender` on `localhost:6688` automatically
- **session-setup skill** — start/stop/restart Blender, troubleshoot MCP/CUDA issues
- **scene-materials skill** — lighting, metallic material archetypes, HDRI backgrounds
- **cad-import skill** — STL batch import, STP conversion workflow, Excel BOM integration
- **rendering skill** — Cycles/CUDA config, animation rendering, GIF export

> **Manual MCP registration** (if not using the plugin):
> ```bash
> claude mcp add blender \
>   -e BLENDER_HOST=localhost \
>   -e BLENDER_PORT=6688 \
>   -- uvx blender-remote --host localhost --port 6688
> claude mcp list
> ```

---

## 8. Start Blender and Claude Code (two terminals on the same machine)

Blender Remote and Claude Code must run simultaneously on the **same
machine** in **two separate terminals**. Blender Remote hosts the MCP
server that Claude Code connects to via localhost.

**Terminal 1 — Start Blender headless:**

```bash
cd <project-directory>
source .venv/bin/activate

# Kill any leftover processes first
fuser -k 6688/tcp 2>/dev/null
pkill -f blender 2>/dev/null
sleep 1

# Start Blender in background mode
blender-remote-cli start --background --port 6688
```

Add convenience aliases to `~/.bashrc`:

```bash
# Replace <project-directory> with your actual project path
cat >> ~/.bashrc << 'EOF'
alias blender-start='cd <project-directory> && source .venv/bin/activate && fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null; sleep 1 && blender-remote-cli start --background --port 6688'
alias blender-stop='fuser -k 6688/tcp 2>/dev/null; pkill -f blender 2>/dev/null'
alias blender-restart='blender-stop && sleep 1 && blender-start'
EOF
source ~/.bashrc
```

Then use:

```bash
blender-start    # Start Blender headless
blender-stop     # Stop Blender and free port
blender-restart  # Stop and restart Blender
```

**Terminal 2 — Start Claude Code:**

```bash
cd <project-directory>
source .venv/bin/activate
claude
```

Inside Claude Code, verify the MCP tools are loaded:

```
/mcp
```

You should see `blender` listed as an active MCP server with its tools
available. Both processes must stay running — if Blender Remote stops,
Claude Code loses the MCP connection.

You can now control Blender with natural language:

```
Create a low poly mountain scene with a lake
Add a sunset HDRI from Poly Haven
Set up Cycles rendering with CUDA and render to /tmp/output.png
```

### Example: Jet Engine Assembly from STL Files

```
Import all STL files from the files/ folder into Blender and read the
Excel BOM spreadsheet to identify each part. Assign realistic, fully
opaque metallic materials based on part category — titanium for
compressor blades and spools, nickel superalloy for the hot section,
stainless steel for casings, carbon composite for the fan, copper alloy
for combustion components, and chrome for the spinner. No parts should
be transparent or translucent.

Set up a professional studio scene: three-point area lighting with a
key, fill, and rim light, plus a soft overhead. Use a clean white
background with a ground plane that catches shadows from the assembly.
Enable ambient occlusion and screen-space reflections for realistic
metallic shading.

Animate an epic cinematic camera flight — a smooth 360-degree orbit
around the jet engine with gentle elevation changes. Render all frames
and combine them into a looping animated GIF. Save the Blender file.
```

---

## Troubleshooting

### Port already in use
```bash
fuser -k 6688/tcp
# or find and kill the process manually:
ss -tulpn | grep 6688
kill <PID>
```

### CUDA not detected
```bash
# Verify NVIDIA drivers are working
nvidia-smi

# Test CUDA detection in Blender
blender --background --python-expr "
import bpy
cprefs = bpy.context.preferences.addons['cycles'].preferences
cprefs.get_devices()
for d in cprefs.devices:
    print(d.name, d.type, d.use)
"
```

### requests module missing (addon install error)
```bash
# Run inside Blender's Python console (Scripting workspace)
import subprocess, sys
subprocess.call([sys.executable, '-m', 'pip', 'install', 'requests'])
```

### blender-remote-cli init fails on Linux (no auto-detect)
```bash
# Specify the path explicitly
blender-remote-cli init --blender-path $(which blender)
```

---

## Quick Reference

| Task | Command |
|---|---|
| Install plugin from GitHub | `claude plugin marketplace add boernmaster/blender_skill` |
| Install blender-remote plugin | `claude plugin install blender-remote@blender_skill` |
| Install dependencies | `uv sync` |
| Add a package | `uv add <package>` |
| Activate venv | `source .venv/bin/activate` |
| Start Blender headless | `blender-remote-cli start --background` |
| Start Blender | `blender-start` (alias) |
| Stop Blender | `blender-stop` (alias) |
| Restart Blender | `blender-restart` (alias) |
| Check port usage | `ss -tulpn \| grep 6688` |
| Kill port | `fuser -k 6688/tcp` |
| List MCP servers | `claude mcp list` |
| Remove MCP server | `claude mcp remove blender` |
| Start Claude Code | `claude` |
| Check MCP in session | `/mcp` |

