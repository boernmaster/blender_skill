# blender-remote plugin

Control Blender headlessly via Claude Code using the blender-remote MCP. Part of the `automized-rendering-workflow` project.

## Overview

This plugin bundles the blender-remote MCP server registration and four skills covering the full workflow: session management, scene/material setup, CAD file import, and Cycles/CUDA rendering.

## Components

### MCP Server
- **blender** — connects Claude Code to a headless Blender instance running on `localhost:6688` via blender-remote

### Skills

| Skill | Triggers |
|-------|---------|
| `session-setup` | "start blender", "stop blender", "check MCP", "blender not connected", port/CUDA errors |
| `scene-materials` | "set up scene", "add lighting", "assign materials", "metallic material", "studio lighting", "HDRI" |
| `cad-import` | "import STL/STP/OBJ", "load CAD assembly", "import from folder", "read BOM spreadsheet" |
| `rendering` | "render", "enable CUDA", "Cycles", "render animation", "output PNG", "make GIF" |

## Setup

### Prerequisites
- Blender installed on the machine
- `uv` package manager
- Project venv with dependencies: `uv sync`
- blender-remote addon installed in Blender: `blender-remote-cli install`

### First-time MCP registration
The `.mcp.json` registers the MCP server automatically when the plugin is installed. To register manually:
```bash
claude mcp add blender \
  -e BLENDER_HOST=localhost \
  -e BLENDER_PORT=6688 \
  -- uvx blender-remote --host localhost --port 6688
```

## Usage

Start a session before issuing any Blender commands:

```
# Terminal 1
blender-start

# Terminal 2
source .venv/bin/activate && claude
```

Then verify MCP is active with `/mcp` inside Claude Code.

Example prompts:
```
Import all STL files from /data/parts and assign metallic materials from bom.xlsx
Set up three-point studio lighting with a white shadow-catching floor
Render a 360° orbit animation and export as a GIF to /tmp/output.gif
```
