#!/bin/bash
# Rebuild blender-remote.plugin zip for direct distribution.
# Not needed for marketplace updates — just push to GitHub.
set -e
cd "$(dirname "$0")/blender-remote"
zip -r ../blender-remote.plugin .claude-plugin .mcp.json skills README.md pyproject.toml
echo "blender-remote.plugin rebuilt"
