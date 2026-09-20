#!/bin/bash
# Edge Node edge-us_west_1-003 Startup Script
export EDGE_NODE_ID="edge-us_west_1-003"
export EDGE_REGION="US_WEST_1"
export EDGE_LOCATION="California"
export CLAUDE_DIR="/.claude"

# Start edge node services
echo "🚀 Starting Edge Node edge-us_west_1-003"
echo "📍 Region: US_WEST_1 (California)"
echo "🔧 Capacity: 64 cores, 256000MB RAM"

# Initialize edge node monitoring
while true; do
    echo "📊 Edge Node edge-us_west_1-003 - Status: Active"
    echo "⚡ Latency: <5ms | Bandwidth: 10000Mbps"
    sleep 30
done
