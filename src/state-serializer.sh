#!/bin/bash

# State Serializer - Agent state persistence and recovery
# Part of Phase 1 Implementation

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
STATE_DIR="${CLAUDE_DIR}/state"
AGENTS_DIR="${CLAUDE_DIR}/agents"
LOGS_DIR="${CLAUDE_DIR}/logs"

# Serialize agent state
serialize_agent_state() {
    local agent_id="$1"
    local additional_data="${2:-"{}"}"
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    
    if [[ ! -d "$agent_dir" ]]; then
        echo "ERROR: Agent directory not found: $agent_dir"
        return 1
    fi
    
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local session_name="claude-${agent_id}"
    
    # Collect agent configuration
    local agent_config="{}"
    if [[ -f "${agent_dir}/config/agent.json" ]]; then
        agent_config=$(cat "${agent_dir}/config/agent.json")
    fi
    
    # Collect session information
    local session_info="{}"
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        local session_created=$(tmux list-sessions -f "#{session_name}: ${session_name}" -F "#{session_created}" 2>/dev/null || echo "0")
        local session_activity=$(tmux list-sessions -f "#{session_name}: ${session_name}" -F "#{session_activity}" 2>/dev/null || echo "0")
        local window_count=$(tmux list-windows -t "${session_name}" -F "#{window_index}" 2>/dev/null | wc -l || echo "0")
        
        session_info=$(jq -n \
            --arg created "$session_created" \
            --arg activity "$session_activity" \
            --arg windows "$window_count" \
            --arg status "active" \
            '{
                created: $created,
                last_activity: $activity,
                window_count: ($windows | tonumber),
                status: $status
            }')
    else
        session_info=$(jq -n '{status: "inactive"}')
    fi
    
    # Collect workspace state
    local workspace_state="{}"
    if [[ -d "${agent_dir}/workspace" ]]; then
        local file_count=$(find "${agent_dir}/workspace" -type f 2>/dev/null | wc -l || echo "0")
        local dir_size=$(du -sk "${agent_dir}/workspace" 2>/dev/null | cut -f1 || echo "0")
        
        workspace_state=$(jq -n \
            --arg files "$file_count" \
            --arg size_kb "$dir_size" \
            '{
                file_count: ($files | tonumber),
                size_kb: ($size_kb | tonumber),
                last_modified: "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
            }')
    fi
    
    # Collect performance metrics
    local performance_metrics="{}"
    local heartbeat_file="${STATE_DIR}/${agent_id}.heartbeat"
    if [[ -f "$heartbeat_file" ]]; then
        local last_heartbeat=$(cat "$heartbeat_file")
        local current_time=$(date +%s)
        local heartbeat_age=$((current_time - last_heartbeat))
        
        performance_metrics=$(jq -n \
            --arg last_heartbeat "$last_heartbeat" \
            --arg heartbeat_age "$heartbeat_age" \
            --arg current_time "$current_time" \
            '{
                last_heartbeat: ($last_heartbeat | tonumber),
                heartbeat_age_seconds: ($heartbeat_age | tonumber),
                timestamp: ($current_time | tonumber)
            }')
    fi
    
    # Create comprehensive state snapshot
    local state_snapshot=$(jq -n \
        --arg agent_id "$agent_id" \
        --arg timestamp "$timestamp" \
        --argjson agent_config "$agent_config" \
        --argjson session_info "$session_info" \
        --argjson workspace_state "$workspace_state" \
        --argjson performance_metrics "$performance_metrics" \
        --argjson additional_data "$additional_data" \
        '{
            agent_id: $agent_id,
            snapshot_timestamp: $timestamp,
            version: "1.0",
            agent_configuration: $agent_config,
            session_information: $session_info,
            workspace_state: $workspace_state,
            performance_metrics: $performance_metrics,
            additional_data: $additional_data,
            serialization_metadata: {
                method: "full_snapshot",
                compression: false,
                encryption: false
            }
        }')
    
    # Save state snapshot
    local state_file="${STATE_DIR}/${agent_id}.state.json"
    echo "$state_snapshot" > "$state_file"
    chmod 600 "$state_file"
    
    # Create backup with timestamp
    local backup_file="${STATE_DIR}/backups/${agent_id}.state.$(date +%s).json"
    mkdir -p "${STATE_DIR}/backups"
    chmod 700 "${STATE_DIR}/backups"
    cp "$state_file" "$backup_file"
    
    # Log serialization
    log_state_event "STATE_SERIALIZED" "$agent_id" "State snapshot created successfully"
    
    echo "$state_file"
}

# Deserialize and restore agent state
deserialize_agent_state() {
    local agent_id="$1"
    local state_file="${STATE_DIR}/${agent_id}.state.json"
    
    if [[ ! -f "$state_file" ]]; then
        echo "ERROR: State file not found: $state_file"
        return 1
    fi
    
    # Validate state file format
    if ! jq . "$state_file" >/dev/null 2>&1; then
        echo "ERROR: Invalid state file format"
        return 1
    fi
    
    # Extract state components
    local agent_config=$(jq '.agent_configuration' "$state_file")
    local workspace_state=$(jq '.workspace_state' "$state_file")
    local session_info=$(jq '.session_information' "$state_file")
    local additional_data=$(jq '.additional_data' "$state_file")
    
    # Restore agent configuration
    local agent_dir="${AGENTS_DIR}/${agent_id}"
    if [[ ! -d "$agent_dir" ]]; then
        mkdir -p "${agent_dir}"/{config,context,logs,state,workspace}
        chmod 700 "$agent_dir"
    fi
    
    echo "$agent_config" > "${agent_dir}/config/agent.json"
    chmod 600 "${agent_dir}/config/agent.json"
    
    # Update agent status to restored
    local updated_config=$(echo "$agent_config" | jq \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.status = "restored" | .last_updated = $timestamp | .restored_from_state = true')
    
    echo "$updated_config" > "${agent_dir}/config/agent.json"
    
    # Log restoration
    log_state_event "STATE_RESTORED" "$agent_id" "Agent state restored from snapshot"
    
    echo "$state_file"
}

# Create incremental state checkpoint
create_checkpoint() {
    local agent_id="$1"
    local checkpoint_type="${2:-auto}"
    local checkpoint_data="${3:-"{}"}"
    
    local timestamp="$(date +%s)"
    local checkpoint_dir="${STATE_DIR}/checkpoints/${agent_id}"
    
    mkdir -p "$checkpoint_dir"
    chmod 700 "$checkpoint_dir"
    
    # Create lightweight checkpoint
    local checkpoint
    if [[ "$checkpoint_data" == "{}" ]]; then
        checkpoint=$(jq -n \
            --arg agent_id "$agent_id" \
            --arg timestamp "$timestamp" \
            --arg type "$checkpoint_type" \
            '{
                agent_id: $agent_id,
                checkpoint_timestamp: ($timestamp | tonumber),
                checkpoint_type: $type,
                data: {},
                version: "1.0"
            }')
    else
        checkpoint=$(jq -n \
            --arg agent_id "$agent_id" \
            --arg timestamp "$timestamp" \
            --arg type "$checkpoint_type" \
            --arg data_str "$checkpoint_data" \
            '{
                agent_id: $agent_id,
                checkpoint_timestamp: ($timestamp | tonumber),
                checkpoint_type: $type,
                data: ($data_str | fromjson),
                version: "1.0"
            }')
    fi
    
    local checkpoint_file="${checkpoint_dir}/checkpoint.${timestamp}.json"
    echo "$checkpoint" > "$checkpoint_file"
    chmod 600 "$checkpoint_file"
    
    # Maintain only last 10 checkpoints
    cleanup_old_checkpoints "$agent_id" 10
    
    log_state_event "CHECKPOINT_CREATED" "$agent_id" "Checkpoint created: $checkpoint_type"
    
    echo "$checkpoint_file"
}

# Restore from checkpoint
restore_from_checkpoint() {
    local agent_id="$1"
    local checkpoint_timestamp="${2:-latest}"
    local checkpoint_dir="${STATE_DIR}/checkpoints/${agent_id}"
    
    if [[ ! -d "$checkpoint_dir" ]]; then
        echo "ERROR: No checkpoints found for agent: $agent_id"
        return 1
    fi
    
    local checkpoint_file
    if [[ "$checkpoint_timestamp" == "latest" ]]; then
        checkpoint_file=$(ls -t "${checkpoint_dir}"/checkpoint.*.json 2>/dev/null | head -1)
    else
        checkpoint_file="${checkpoint_dir}/checkpoint.${checkpoint_timestamp}.json"
    fi
    
    if [[ ! -f "$checkpoint_file" ]]; then
        echo "ERROR: Checkpoint file not found: $checkpoint_file"
        return 1
    fi
    
    # Validate and extract checkpoint data
    if ! jq . "$checkpoint_file" >/dev/null 2>&1; then
        echo "ERROR: Invalid checkpoint file format"
        return 1
    fi
    
    local checkpoint_data=$(jq '.data' "$checkpoint_file")
    local checkpoint_type=$(jq -r '.checkpoint_type' "$checkpoint_file")
    
    log_state_event "CHECKPOINT_RESTORED" "$agent_id" "Restored from checkpoint: $checkpoint_type"
    
    echo "$checkpoint_data"
}

# Cleanup old state files and checkpoints
cleanup_old_checkpoints() {
    local agent_id="$1"
    local keep_count="${2:-10}"
    local checkpoint_dir="${STATE_DIR}/checkpoints/${agent_id}"
    
    if [[ -d "$checkpoint_dir" ]]; then
        # Keep only the most recent checkpoints
        ls -t "${checkpoint_dir}"/checkpoint.*.json 2>/dev/null | tail -n +$((keep_count + 1)) | xargs -r rm -f
    fi
}

cleanup_old_backups() {
    local agent_id="$1"
    local keep_days="${2:-7}"
    local backup_dir="${STATE_DIR}/backups"
    
    if [[ -d "$backup_dir" ]]; then
        # Remove backups older than specified days
        find "$backup_dir" -name "${agent_id}.state.*.json" -mtime +$keep_days -delete 2>/dev/null || true
    fi
}

# Export agent state for migration
export_agent_state() {
    local agent_id="$1"
    local export_file="${2:-${STATE_DIR}/${agent_id}.export.json}"
    
    # Create comprehensive export including all state data
    local full_state=$(serialize_agent_state "$agent_id" '{"export": true}')
    
    if [[ -f "$full_state" ]]; then
        # Add export metadata
        local export_data=$(jq \
            --arg export_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg export_version "1.0" \
            '. + {
                export_metadata: {
                    export_timestamp: $export_timestamp,
                    export_version: $export_version,
                    exported_by: "state-serializer",
                    export_type: "full_migration"
                }
            }' "$full_state")
        
        echo "$export_data" > "$export_file"
        chmod 600 "$export_file"
        
        log_state_event "STATE_EXPORTED" "$agent_id" "State exported to: $export_file"
        echo "$export_file"
    else
        echo "ERROR: Failed to serialize state for export"
        return 1
    fi
}

# Import agent state from migration
import_agent_state() {
    local agent_id="$1"
    local import_file="$2"
    
    if [[ ! -f "$import_file" ]]; then
        echo "ERROR: Import file not found: $import_file"
        return 1
    fi
    
    # Validate import file
    if ! jq . "$import_file" >/dev/null 2>&1; then
        echo "ERROR: Invalid import file format"
        return 1
    fi
    
    # Check if it's a valid export
    local export_metadata=$(jq '.export_metadata // {}' "$import_file")
    if [[ "$export_metadata" == "{}" ]]; then
        echo "WARNING: Import file may not be a valid export"
    fi
    
    # Copy import file to state directory
    local state_file="${STATE_DIR}/${agent_id}.state.json"
    cp "$import_file" "$state_file"
    chmod 600 "$state_file"
    
    # Restore from imported state
    deserialize_agent_state "$agent_id"
    
    log_state_event "STATE_IMPORTED" "$agent_id" "State imported from: $import_file"
    echo "State imported successfully"
}

# Logging
log_state_event() {
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
            message: $message,
            category: "state_management"
        }')
    
    echo "$log_entry" >> "${LOGS_DIR}/state-serializer.log"
}

# Main command interface
main() {
    mkdir -p "${STATE_DIR}" "${LOGS_DIR}"
    chmod 700 "${STATE_DIR}"
    
    case "${1:-help}" in
        "serialize")
            serialize_agent_state "$2" "${3:-{}}"
            ;;
        "deserialize")
            deserialize_agent_state "$2"
            ;;
        "checkpoint")
            create_checkpoint "$2" "${3:-auto}" "${4:-{}}"
            ;;
        "restore-checkpoint")
            restore_from_checkpoint "$2" "${3:-latest}"
            ;;
        "export")
            export_agent_state "$2" "$3"
            ;;
        "import")
            import_agent_state "$2" "$3"
            ;;
        "cleanup-checkpoints")
            cleanup_old_checkpoints "$2" "${3:-10}"
            ;;
        "cleanup-backups")
            cleanup_old_backups "$2" "${3:-7}"
            ;;
        *)
            echo "State Serializer - Phase 1"
            echo "Usage: $0 {serialize|deserialize|checkpoint|restore-checkpoint|export|import|cleanup-checkpoints|cleanup-backups}"
            echo ""
            echo "Commands:"
            echo "  serialize <agent_id> [additional_data]           - Serialize agent state"
            echo "  deserialize <agent_id>                           - Restore agent from state"
            echo "  checkpoint <agent_id> [type] [data]              - Create state checkpoint"
            echo "  restore-checkpoint <agent_id> [timestamp]        - Restore from checkpoint"
            echo "  export <agent_id> [export_file]                  - Export state for migration"
            echo "  import <agent_id> <import_file>                  - Import state from file"
            echo "  cleanup-checkpoints <agent_id> [keep_count]      - Clean old checkpoints"
            echo "  cleanup-backups <agent_id> [keep_days]           - Clean old backups"
            ;;
    esac
}

# Run main function
main "$@"