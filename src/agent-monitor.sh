#!/bin/bash

# Agent Monitor - Continuous health monitoring for isolated agents
# Part of Phase 1 Implementation

set -euo pipefail

AGENT_ID="$1"
CLAUDE_DIR="${HOME}/.claude"
AGENTS_DIR="${CLAUDE_DIR}/agents"
LOGS_DIR="${CLAUDE_DIR}/logs"
SESSION_MANAGER="${CLAUDE_DIR}/scripts/claude-session-manager.sh"

# Configuration
HEARTBEAT_INTERVAL=30
HEALTH_CHECK_INTERVAL=60
MAX_MEMORY_MB=1024
MAX_CPU_PERCENT=80

log_monitor() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "[${timestamp}] [${level}] [${AGENT_ID}] ${message}" >> "${LOGS_DIR}/agent-monitor.log"
    echo "[${level}] ${message}"
}

# Send heartbeat
send_heartbeat() {
    "${SESSION_MANAGER}" save-state "${AGENT_ID}" "$(jq -n \
        --arg timestamp "$(date +%s)" \
        --arg status "active" \
        '{
            last_heartbeat: ($timestamp | tonumber),
            status: $status,
            monitoring: true
        }')"
    
    echo "$(date +%s)" > "${CLAUDE_DIR}/state/${AGENT_ID}.heartbeat"
}

# Monitor resource usage
check_resources() {
    local session_name="claude-${AGENT_ID}"
    
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        log_monitor "ERROR" "Session ${session_name} not found"
        return 1
    fi
    
    # Get tmux session PID
    local session_pid=$(tmux list-sessions -f "#{session_name}: ${session_name}" -F "#{session_pid}" 2>/dev/null || echo "")
    
    if [[ -n "$session_pid" ]]; then
        # Check memory usage
        local memory_kb=$(ps -o rss= -p "$session_pid" 2>/dev/null || echo "0")
        local memory_mb=$((memory_kb / 1024))
        
        # Check CPU usage
        local cpu_percent=$(ps -o %cpu= -p "$session_pid" 2>/dev/null | tr -d ' ' || echo "0")
        
        # Log resource usage
        log_monitor "INFO" "Resources: Memory=${memory_mb}MB, CPU=${cpu_percent}%"
        
        # Check thresholds
        if [[ $memory_mb -gt $MAX_MEMORY_MB ]]; then
            log_monitor "WARNING" "High memory usage: ${memory_mb}MB (max: ${MAX_MEMORY_MB}MB)"
        fi
        
        if (( $(echo "$cpu_percent > $MAX_CPU_PERCENT" | bc -l) )); then
            log_monitor "WARNING" "High CPU usage: ${cpu_percent}% (max: ${MAX_CPU_PERCENT}%)"
        fi
    fi
}

# Check agent responsiveness
check_responsiveness() {
    local agent_dir="${AGENTS_DIR}/${AGENT_ID}"
    local pipe_path="${CLAUDE_DIR}/pipes/pipe_${AGENT_ID}"
    
    if [[ ! -p "$pipe_path" ]]; then
        log_monitor "ERROR" "Communication pipe not found: ${pipe_path}"
        return 1
    fi
    
    # Test pipe responsiveness (non-blocking)
    if ! timeout 5 echo "ping" > "$pipe_path" 2>/dev/null; then
        log_monitor "WARNING" "Agent communication pipe unresponsive"
        return 1
    fi
    
    return 0
}

# Main monitoring loop
monitor_loop() {
    log_monitor "INFO" "Starting agent monitoring for ${AGENT_ID}"
    
    local last_heartbeat=0
    local last_health_check=0
    
    while true; do
        local current_time=$(date +%s)
        
        # Send heartbeat
        if [[ $((current_time - last_heartbeat)) -ge $HEARTBEAT_INTERVAL ]]; then
            send_heartbeat
            last_heartbeat=$current_time
        fi
        
        # Health check
        if [[ $((current_time - last_health_check)) -ge $HEALTH_CHECK_INTERVAL ]]; then
            check_resources
            check_responsiveness
            last_health_check=$current_time
        fi
        
        # Sleep for 10 seconds before next iteration
        sleep 10
    done
}

# Cleanup on exit
cleanup() {
    log_monitor "INFO" "Agent monitor shutting down"
    "${SESSION_MANAGER}" save-state "${AGENT_ID}" "$(jq -n \
        --arg timestamp "$(date +%s)" \
        --arg status "monitor_stopped" \
        '{
            last_heartbeat: ($timestamp | tonumber),
            status: $status,
            monitoring: false
        }')"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Ensure required directories exist
mkdir -p "${LOGS_DIR}"

# Start monitoring
log_monitor "INFO" "Agent monitor initialized for ${AGENT_ID}"
monitor_loop