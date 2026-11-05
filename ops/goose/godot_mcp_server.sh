#!/bin/bash
# Shared Godot Editor MCP server for the PPIO project.
# One long-lived godot-editor-mcp in HTTP mode; any Godot editor instance
# (desktop or headless) connects its addon out to the bridge on :9080.
# MCP clients (goose `godot` extension) talk to http://127.0.0.1:9006/mcp.
#
# Usage: ops/goose/godot_mcp_server.sh [start|stop|status]
# Requires: godot-editor-mcp on PATH (uv tool install godot-editor-mcp==2026.10.20.1)
set -u
HTTP_PORT="${GODOT_MCP_HTTP_PORT:-9006}"
ACTION="${1:-start}"

is_up() { curl -s -o /dev/null -m 2 "http://127.0.0.1:${HTTP_PORT}/mcp"; }

case "$ACTION" in
  status)
    if is_up; then echo "godot-mcp: UP (http://127.0.0.1:${HTTP_PORT}/mcp)"; else echo "godot-mcp: DOWN"; fi
    ;;
  stop)
    pkill -f "godot-editor-mcp" 2>/dev/null && echo "godot-mcp: stopped" || echo "godot-mcp: was not running"
    ;;
  start|restart)
    if [ "$ACTION" = "restart" ]; then pkill -f "godot-editor-mcp" 2>/dev/null; sleep 1; fi
    if is_up; then echo "godot-mcp: already UP (http://127.0.0.1:${HTTP_PORT}/mcp)"; exit 0; fi
    command -v godot-editor-mcp >/dev/null || { echo "ERROR: godot-editor-mcp not on PATH"; exit 1; }
    mkdir -p /tmp/ppio
    GODOT_MCP_TRANSPORT=http GODOT_MCP_HTTP_HOST=127.0.0.1 GODOT_MCP_HTTP_PORT="$HTTP_PORT" \
      setsid godot-editor-mcp > /tmp/ppio/godot_mcp_server.log 2>&1 < /dev/null &
    sleep 3
    if is_up; then
      echo "godot-mcp: UP (http://127.0.0.1:${HTTP_PORT}/mcp, bridge :9080, log /tmp/ppio/godot_mcp_server.log)"
      echo "open a Godot editor on this project to attach the addon (auto-reconnects)"
    else
      echo "ERROR: server did not come up; see /tmp/ppio/godot_mcp_server.log"; exit 1
    fi
    ;;
  *) echo "usage: $0 [start|stop|restart|status]"; exit 2 ;;
esac
