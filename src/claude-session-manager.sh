#!/bin/bash

# Claude Session Manager - Phase 1 Implementation
# Provides agent isolation, session management, and secure communication

set -euo pipefail

# Configuration
CLAUDE_DIR="${HOME}/.claude"
SESSIONS_DIR="${CLAUDE_DIR}/sessions"
AGENTS_DIR="${CLAUDE_DIR}/agents"
PIPES_DIR="${CLAUDE_DIR}/pipes"
STATE_DIR="${CLAUDE_DIR}/state"
LOGS_DIR="${CLAUDE_DIR}/logs"

# Ensure required directories exist
init_directories() {
    mkdir -p "${SESSIONS_DIR}" "${AGENTS_DIR}" "${PIPES_DIR}" "${STATE_DIR}" "${LOGS_DIR}"
    chmod 700 "${CLAUDE_DIR}" "${SESSIONS_DIR}" "${AGENTS_DIR}" "${PIPES_DIR}" "${STATE_DIR}"
}

# Generate secure agent ID
generate_agent_id() {
    local agent_type="$1"
    local project_name="$2"
    echo "${project_name}-${agent_type}-$(date +%s)-$(openssl rand -hex 4)"
}

# Create isolated agent session
spawn_agent_session() {
    local agent_type="$1"
    local project_name="${2:-default}"
    local agent_config="${3:-}"
    
    local agent_id=$(generate_agent_id "$agent_type" "$project_name")
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    local session_name="claude-${agent_id}"
    
    echo "🚀 Spawning agent session: ${agent_id}"
    
    # Create isolated agent directory
    mkdir -p "${agent_dir}"/{config,context,logs,state,workspace}
    chmod 700 "${agent_dir}"
    
    # Create agent configuration
    cat > "${agent_dir}/config/agent.json" << EOF
{
    "agent_id": "${agent_id}",
    "agent_type": "${agent_type}",
    "project_name": "${project_name}",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "initializing",
    "isolation_level": "strict",
    "communication_channels": ["pipe_${agent_id}"],
    "security_context": {
        "sandbox_enabled": true,
        "context_isolation": true,
        "instruction_immutable": true
    }
}
EOF

    # Create communication pipe
    local pipe_path="${PIPES_DIR}/pipe_${agent_id}"
    mkfifo "${pipe_path}"
    chmod 600 "${pipe_path}"
    
    # Create tmux session with proper isolation
    tmux new-session -d -s "${session_name}" -c "${agent_dir}/workspace"
    
    # Set environment variables for agent isolation
    tmux send-keys -t "${session_name}" "export AGENT_ID='${agent_id}'" Enter
    tmux send-keys -t "${session_name}" "export AGENT_TYPE='${agent_type}'" Enter
    tmux send-keys -t "${session_name}" "export PROJECT_NAME='${project_name}'" Enter
    tmux send-keys -t "${session_name}" "export AGENT_DIR='${agent_dir}'" Enter
    tmux send-keys -t "${session_name}" "export PIPE_PATH='${pipe_path}'" Enter
    tmux send-keys -t "${session_name}" "export CLAUDE_ISOLATION_MODE='strict'" Enter
    
    # Start agent monitoring in background pane
    tmux split-window -t "${session_name}" -v -p 20
    tmux send-keys -t "${session_name}:0.1" "${CLAUDE_DIR}/scripts/agent-monitor.sh ${agent_id}" Enter
    
    # Focus on main agent pane
    tmux select-pane -t "${session_name}:0.0"
    
    # Update agent status
    update_agent_status "${agent_id}" "active"
    
    # Log session creation
    log_event "SESSION_CREATED" "${agent_id}" "Agent session spawned successfully"
    
    echo "✅ Agent session created: ${session_name}"
    echo "📁 Agent directory: ${agent_dir}"
    echo "📡 Communication pipe: ${pipe_path}"
    
    echo "${agent_id}"
}

# Monitor agent health
monitor_agent_health() {
    local agent_id="$1"
    local session_name="claude-${agent_id}"
    
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        local status=$(get_agent_status "${agent_id}")
        local last_heartbeat=$(get_last_heartbeat "${agent_id}")
        local current_time=$(date +%s)
        
        if [[ -n "$last_heartbeat" ]]; then
            local time_diff=$((current_time - last_heartbeat))
            if [[ $time_diff -gt 300 ]]; then  # 5 minutes
                log_event "HEALTH_WARNING" "${agent_id}" "No heartbeat for ${time_diff} seconds"
                return 1
            fi
        fi
        
        echo "healthy"
    else
        log_event "HEALTH_ERROR" "${agent_id}" "Session not found"
        echo "session_missing"
    fi
}

# Secure message routing between agents
message_router() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local payload="$4"
    
    local to_pipe="${PIPES_DIR}/pipe_${to_agent}"
    
    if [[ ! -p "$to_pipe" ]]; then
        log_event "MESSAGE_ERROR" "${from_agent}" "Target pipe not found: ${to_agent}"
        return 1
    fi
    
    # Create secure message structure
    local message=$(jq -n \
        --arg from "$from_agent" \
        --arg to "$to_agent" \
        --arg type "$message_type" \
        --arg payload "$payload" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            from: $from,
            to: $to,
            type: $type,
            payload: $payload,
            timestamp: $timestamp,
            signature: "secure_hash_placeholder"
        }')
    
    # Send message through pipe (non-blocking)
    echo "$message" > "$to_pipe" &
    
    log_event "MESSAGE_SENT" "${from_agent}" "Message sent to ${to_agent}: ${message_type}"
}

# Session recovery for failed agents
session_recovery() {
    local agent_id="$1"
    local session_name="claude-${agent_id}"
    
    echo "🔄 Attempting recovery for agent: ${agent_id}"
    
    # Check if session exists
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        echo "⚠️  Session exists but agent unresponsive, attempting restart"
        tmux kill-session -t "${session_name}"
    fi
    
    # Load agent configuration
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    if [[ ! -f "${agent_dir}/config/agent.json" ]]; then
        log_event "RECOVERY_ERROR" "${agent_id}" "Agent configuration not found"
        return 1
    fi
    
    local agent_type=$(jq -r '.agent_type' "${agent_dir}/config/agent.json")
    local project_name=$(jq -r '.project_name' "${agent_dir}/config/agent.json")
    
    # Restore session state
    restore_agent_state "${agent_id}"
    
    # Recreate session
    tmux new-session -d -s "${session_name}" -c "${agent_dir}/workspace"
    
    # Restore environment
    tmux send-keys -t "${session_name}" "export AGENT_ID='${agent_id}'" Enter
    tmux send-keys -t "${session_name}" "export AGENT_TYPE='${agent_type}'" Enter
    tmux send-keys -t "${session_name}" "export PROJECT_NAME='${project_name}'" Enter
    tmux send-keys -t "${session_name}" "export AGENT_DIR='${agent_dir}'" Enter
    
    # Update status
    update_agent_status "${agent_id}" "recovered"
    
    log_event "RECOVERY_SUCCESS" "${agent_id}" "Agent session recovered successfully"
    echo "✅ Agent recovered: ${agent_id}"
}

# Agent state management
save_agent_state() {
    local agent_id="$1"
    local state_data="$2"
    local state_file="${STATE_DIR}/${agent_id}.json"
    
    echo "$state_data" > "$state_file"
    chmod 600 "$state_file"
}

restore_agent_state() {
    local agent_id="$1"
    local state_file="${STATE_DIR}/${agent_id}.json"
    
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    else
        echo "{}"
    fi
}

# Status management
update_agent_status() {
    local agent_id="$1"
    local status="$2"
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    
    if [[ -f "${agent_dir}/config/agent.json" ]]; then
        jq --arg status "$status" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '.status = $status | .last_updated = $timestamp' \
            "${agent_dir}/config/agent.json" > "${agent_dir}/config/agent.json.tmp"
        mv "${agent_dir}/config/agent.json.tmp" "${agent_dir}/config/agent.json"
    fi
}

get_agent_status() {
    local agent_id="$1"
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    
    if [[ -f "${agent_dir}/config/agent.json" ]]; then
        jq -r '.status' "${agent_dir}/config/agent.json"
    else
        echo "unknown"
    fi
}

# Heartbeat management
update_heartbeat() {
    local agent_id="$1"
    echo "$(date +%s)" > "${STATE_DIR}/${agent_id}.heartbeat"
}

get_last_heartbeat() {
    local agent_id="$1"
    local heartbeat_file="${STATE_DIR}/${agent_id}.heartbeat"
    
    if [[ -f "$heartbeat_file" ]]; then
        cat "$heartbeat_file"
    fi
}

# Logging
log_event() {
    local event_type="$1"
    local agent_id="$2"
    local message="$3"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    local log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg type "$event_type" \
        --arg agent "$agent_id" \
        --arg message "$message" \
        '{
            timestamp: $timestamp,
            type: $type,
            agent_id: $agent,
            message: $message
        }')
    
    echo "$log_entry" >> "${LOGS_DIR}/session-manager.log"
}

# List active agents
list_agents() {
    echo "🤖 Active Claude Agents:"
    echo "========================"
    
    for agent_dir in "${AGENTS_DIR}"/*; do
        if [[ -d "$agent_dir" && -f "${agent_dir}/config/agent.json" ]]; then
            local agent_id=$(basename "$agent_dir")
            local agent_type=$(jq -r '.agent_type' "${agent_dir}/config/agent.json")
            local project_name=$(jq -r '.project_name' "${agent_dir}/config/agent.json")
            local status=$(jq -r '.status' "${agent_dir}/config/agent.json")
            local session_name="claude-${agent_id}"
            
            if tmux has-session -t "${session_name}" 2>/dev/null; then
                echo "🟢 ${agent_id}"
                echo "   Type: ${agent_type}"
                echo "   Project: ${project_name}"
                echo "   Status: ${status}"
                echo "   Session: ${session_name}"
            else
                echo "🔴 ${agent_id}"
                echo "   Type: ${agent_type}"
                echo "   Project: ${project_name}"
                echo "   Status: ${status} (session missing)"
            fi
            echo ""
        fi
    done
}

# Cleanup terminated sessions
cleanup_sessions() {
    echo "🧹 Cleaning up terminated sessions..."
    
    for agent_dir in "${AGENTS_DIR}"/*; do
        if [[ -d "$agent_dir" ]]; then
            local agent_id=$(basename "$agent_dir")
            local session_name="claude-${agent_id}"
            
            if ! tmux has-session -t "${session_name}" 2>/dev/null; then
                local status=$(get_agent_status "${agent_id}")
                if [[ "$status" != "terminated" ]]; then
                    update_agent_status "${agent_id}" "terminated"
                    log_event "SESSION_TERMINATED" "${agent_id}" "Session no longer exists"
                fi
            fi
        fi
    done
}

# Main command interface
main() {
    init_directories
    
    case "${1:-help}" in
        "spawn")
            spawn_agent_session "$2" "${3:-default}" "${4:-}"
            ;;
        "monitor")
            monitor_agent_health "$2"
            ;;
        "message")
            message_router "$2" "$3" "$4" "$5"
            ;;
        "recover")
            session_recovery "$2"
            ;;
        "list")
            list_agents
            ;;
        "cleanup")
            cleanup_sessions
            ;;
        "save-state")
            save_agent_state "$2" "$3"
            ;;
        "restore-state")
            restore_agent_state "$2"
            ;;
        *)
            echo "Claude Session Manager - Phase 1"
            echo "Usage: $0 {spawn|monitor|message|recover|list|cleanup|save-state|restore-state}"
            echo ""
            echo "Commands:"
            echo "  spawn <agent_type> [project_name] [config]  - Create new isolated agent session"
            echo "  monitor <agent_id>                          - Check agent health"
            echo "  message <from> <to> <type> <payload>        - Send secure message between agents"
            echo "  recover <agent_id>                          - Recover failed agent session"
            echo "  list                                        - List all active agents"
            echo "  cleanup                                     - Clean up terminated sessions"
            echo "  save-state <agent_id> <state_json>          - Save agent state"
            echo "  restore-state <agent_id>                    - Restore agent state"
            ;;
    esac
}

# Run main function with all arguments
main "$@"