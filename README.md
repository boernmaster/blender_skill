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

### 2. Install the Blender addon

The first time Claude Code starts after installing the plugin, the `SessionStart` hook runs automatically and handles:
- Python dependency installation (`uv sync`)
- MCP server registration
- `blender-start` / `blender-stop` / `blender-restart` aliases in `~/.bashrc`
- CUDA startup script creation

The only manual step is installing the addon into Blender once:

```bash
source ~/.bashrc   # load the new aliases
blender-remote-cli install
```

---

## Starting a Session

Two terminals are required. Both must stay running.

**Terminal 1 — start Blender (from the project directory):**
```bash
cd /path/to/project
blender-start
```

**Terminal 2 — start Claude Code:**
```bash
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
Render a 360° orbit animation and save as output/animation.gif
```

```
Enable CUDA and render the current scene to output/render.png at 1920x1080
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
