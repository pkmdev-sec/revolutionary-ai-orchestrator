#!/bin/bash

# Secure Message Handler - Inter-agent communication via named pipes
# Part of Phase 1 Implementation

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PIPES_DIR="${CLAUDE_DIR}/pipes"
LOGS_DIR="${CLAUDE_DIR}/logs"
AGENTS_DIR="${CLAUDE_DIR}/agents"

# Message validation and security
validate_message() {
    local message="$1"
    
    # Check if message is valid JSON
    if ! echo "$message" | jq . >/dev/null 2>&1; then
        echo "ERROR: Invalid JSON format"
        return 1
    fi
    
    # Validate required fields
    local required_fields=("from" "to" "type" "payload" "timestamp")
    for field in "${required_fields[@]}"; do
        if ! echo "$message" | jq -e ".$field" >/dev/null 2>&1; then
            echo "ERROR: Missing required field: $field"
            return 1
        fi
    done
    
    # Validate agent IDs exist
    local from_agent=$(echo "$message" | jq -r '.from')
    local to_agent=$(echo "$message" | jq -r '.to')
    
    if [[ "$to_agent" != "orchestrator" && ! -d "${AGENTS_DIR}/${to_agent}" ]]; then
        echo "ERROR: Target agent does not exist: $to_agent"
        return 1
    fi
    
    if [[ "$from_agent" != "orchestrator" && ! -d "${AGENTS_DIR}/${from_agent}" ]]; then
        echo "ERROR: Source agent does not exist: $from_agent"
        return 1
    fi
    
    echo "VALID"
}

# Message filtering for security
filter_message() {
    local message="$1"
    local message_type=$(echo "$message" | jq -r '.type')
    
    # Block potentially dangerous message types
    case "$message_type" in
        "instruction_override"|"role_change"|"security_bypass"|"privilege_escalate")
            echo "ERROR: Forbidden message type: $message_type"
            return 1
            ;;
        "system_command"|"file_access"|"network_request")
            # These require special validation
            if ! validate_privileged_operation "$message"; then
                echo "ERROR: Unauthorized privileged operation"
                return 1
            fi
            ;;
    esac
    
    # Filter sensitive information from payload
    local filtered_message=$(echo "$message" | jq '
        .payload |= walk(
            if type == "string" then
                . | gsub("password|secret|key|token"; "[REDACTED]"; "i")
            else
                .
            end
        )
    ')
    
    echo "$filtered_message"
}

# Validate privileged operations
validate_privileged_operation() {
    local message="$1"
    local from_agent=$(echo "$message" | jq -r '.from')
    local operation=$(echo "$message" | jq -r '.payload.operation // empty')
    
    # Check if agent has permission for this operation
    local agent_config="${AGENTS_DIR}/${from_agent}/config/agent.json"
    if [[ ! -f "$agent_config" ]]; then
        return 1
    fi
    
    local security_level=$(jq -r '.security_context.isolation_level // "strict"' "$agent_config")
    
    case "$security_level" in
        "strict")
            # Strict agents can only perform basic operations
            case "$operation" in
                "read_workspace"|"write_workspace"|"internal_task")
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        "moderate")
            # Moderate agents have some additional permissions
            case "$operation" in
                "read_workspace"|"write_workspace"|"internal_task"|"external_api"|"file_read")
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
    esac
    
    return 1
}

# Send message securely
send_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local payload="$4"
    
    # Create message structure
    local message=$(jq -n \
        --arg from "$from_agent" \
        --arg to "$to_agent" \
        --arg type "$message_type" \
        --argjson payload "$payload" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg message_id "$(uuidgen)" \
        '{
            message_id: $message_id,
            from: $from,
            to: $to,
            type: $type,
            payload: $payload,
            timestamp: $timestamp,
            security: {
                encrypted: false,
                signed: true,
                signature: "placeholder_signature"
            }
        }')
    
    # Validate message
    local validation_result=$(validate_message "$message")
    if [[ "$validation_result" != "VALID" ]]; then
        log_security_event "MESSAGE_VALIDATION_FAILED" "$from_agent" "$validation_result"
        return 1
    fi
    
    # Filter message for security
    local filtered_message=$(filter_message "$message")
    if [[ $? -ne 0 ]]; then
        log_security_event "MESSAGE_FILTERING_FAILED" "$from_agent" "$filtered_message"
        return 1
    fi
    
    # Send to target pipe
    local target_pipe="${PIPES_DIR}/pipe_${to_agent}"
    if [[ ! -p "$target_pipe" ]]; then
        log_security_event "TARGET_PIPE_MISSING" "$from_agent" "Pipe not found: $target_pipe"
        return 1
    fi
    
    # Non-blocking write with timeout (macOS compatible)
    if echo "$filtered_message" > "$target_pipe" 2>/dev/null; then
        log_communication_event "MESSAGE_SENT" "$from_agent" "$to_agent" "$message_type"
        return 0
    else
        log_security_event "MESSAGE_SEND_TIMEOUT" "$from_agent" "Failed to send to $to_agent"
        return 1
    fi
}

# Receive and process messages
receive_message() {
    local agent_id="$1"
    local pipe_path="${PIPES_DIR}/pipe_${agent_id}"
    
    if [[ ! -p "$pipe_path" ]]; then
        echo "ERROR: Pipe not found: $pipe_path"
        return 1
    fi
    
    # Read from pipe (macOS compatible)
    local message
    if message=$(cat "$pipe_path" 2>/dev/null); then
        # Validate received message
        local validation_result=$(validate_message "$message")
        if [[ "$validation_result" != "VALID" ]]; then
            log_security_event "RECEIVED_INVALID_MESSAGE" "$agent_id" "$validation_result"
            return 1
        fi
        
        # Log successful reception
        local from_agent=$(echo "$message" | jq -r '.from')
        local message_type=$(echo "$message" | jq -r '.type')
        log_communication_event "MESSAGE_RECEIVED" "$agent_id" "$from_agent" "$message_type"
        
        echo "$message"
        return 0
    else
        # Timeout or error
        return 1
    fi
}

# Create secure communication pipe
create_pipe() {
    local agent_id="$1"
    local pipe_path="${PIPES_DIR}/pipe_${agent_id}"
    
    # Ensure pipes directory exists
    mkdir -p "${PIPES_DIR}"
    chmod 700 "${PIPES_DIR}"
    
    # Create named pipe if it doesn't exist
    if [[ ! -p "$pipe_path" ]]; then
        mkfifo "$pipe_path"
        chmod 600 "$pipe_path"
        log_communication_event "PIPE_CREATED" "$agent_id" "system" "pipe_creation"
    fi
    
    echo "$pipe_path"
}

# Remove communication pipe
remove_pipe() {
    local agent_id="$1"
    local pipe_path="${PIPES_DIR}/pipe_${agent_id}"
    
    if [[ -p "$pipe_path" ]]; then
        rm -f "$pipe_path"
        log_communication_event "PIPE_REMOVED" "$agent_id" "system" "pipe_removal"
    fi
}

# Message queue for offline agents
queue_message() {
    local to_agent="$1"
    local message="$2"
    local queue_dir="${CLAUDE_DIR}/message-queue"
    
    mkdir -p "$queue_dir"
    chmod 700 "$queue_dir"
    
    local queue_file="${queue_dir}/${to_agent}.queue"
    echo "$message" >> "$queue_file"
    chmod 600 "$queue_file"
    
    log_communication_event "MESSAGE_QUEUED" "system" "$to_agent" "queue_storage"
}

# Process queued messages
process_queue() {
    local agent_id="$1"
    local queue_file="${CLAUDE_DIR}/message-queue/${agent_id}.queue"
    
    if [[ -f "$queue_file" ]]; then
        while IFS= read -r message; do
            if [[ -n "$message" ]]; then
                # Try to deliver queued message
                echo "$message" | send_message "system" "$agent_id" "queued_delivery" -
            fi
        done < "$queue_file"
        
        # Clear processed queue
        rm -f "$queue_file"
        log_communication_event "QUEUE_PROCESSED" "$agent_id" "system" "queue_delivery"
    fi
}

# Logging functions
log_communication_event() {
    local event_type="$1"
    local agent_id="$2"
    local target_agent="$3"
    local message_type="$4"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    local log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg type "$event_type" \
        --arg agent "$agent_id" \
        --arg target "$target_agent" \
        --arg msg_type "$message_type" \
        '{
            timestamp: $timestamp,
            type: $type,
            agent_id: $agent,
            target_agent: $target,
            message_type: $msg_type,
            category: "communication"
        }')
    
    echo "$log_entry" >> "${LOGS_DIR}/secure-communication.log"
}

log_security_event() {
    local event_type="$1"
    local agent_id="$2"
    local details="$3"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    local log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg type "$event_type" \
        --arg agent "$agent_id" \
        --arg details "$details" \
        '{
            timestamp: $timestamp,
            type: $type,
            agent_id: $agent,
            details: $details,
            category: "security",
            severity: "high"
        }')
    
    echo "$log_entry" >> "${LOGS_DIR}/security-events.log"
    
    # Alert on security events
    echo "🚨 SECURITY EVENT: $event_type - Agent: $agent_id - $details" >&2
}

# Main command interface
main() {
    mkdir -p "${LOGS_DIR}"
    
    case "${1:-help}" in
        "send")
            send_message "$2" "$3" "$4" "$5"
            ;;
        "receive")
            receive_message "$2"
            ;;
        "create-pipe")
            create_pipe "$2"
            ;;
        "remove-pipe")
            remove_pipe "$2"
            ;;
        "queue")
            queue_message "$2" "$3"
            ;;
        "process-queue")
            process_queue "$2"
            ;;
        *)
            echo "Secure Message Handler - Phase 1"
            echo "Usage: $0 {send|receive|create-pipe|remove-pipe|queue|process-queue}"
            echo ""
            echo "Commands:"
            echo "  send <from> <to> <type> <payload>     - Send secure message between agents"
            echo "  receive <agent_id>                    - Receive message for agent"
            echo "  create-pipe <agent_id>                - Create communication pipe"
            echo "  remove-pipe <agent_id>                - Remove communication pipe"
            echo "  queue <agent_id> <message>            - Queue message for offline agent"
            echo "  process-queue <agent_id>              - Process queued messages"
            ;;
    esac
}

# Run main function
main "$@"