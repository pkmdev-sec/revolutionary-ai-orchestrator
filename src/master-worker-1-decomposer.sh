#!/bin/bash

# Master Worker 1 - Recursive Task Decomposition Engine
# Revolutionary AI Orchestration System - Phase 2 Implementation

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
DECOMPOSER_ID="${1:-$(date +%s)-$(openssl rand -hex 4)}"
PROJECT_NAME="${2:-default}"
SESSION_NAME="claude-master-decomposer-${DECOMPOSER_ID}"
WORKSPACE_DIR="${CLAUDE_DIR}/agents/master-decomposer-${DECOMPOSER_ID}/workspace"
PIPE_PATH="${CLAUDE_DIR}/pipes/pipe_master-decomposer-${DECOMPOSER_ID}"

# Configuration
MAX_DECOMPOSITION_LEVELS=5
COMPLEXITY_THRESHOLD=0.3
ECONOMIC_THRESHOLD=0.1
LOG_FILE="${CLAUDE_DIR}/logs/master-worker-1.log"

# Logging function
log_event() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "[${timestamp}] [MW1-${DECOMPOSER_ID}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Initialize Master Worker 1 environment
initialize_decomposer() {
    log_event "INFO" "Initializing Master Worker 1 - Recursive Task Decomposition Engine"
    
    # Create workspace with secure permissions
    mkdir -p "${WORKSPACE_DIR}"/{input,output,patterns,compliance,temp}
    chmod 700 "${WORKSPACE_DIR}"
    
    # Create communication pipe
    if [[ ! -p "$PIPE_PATH" ]]; then
        mkfifo "$PIPE_PATH"
        chmod 600 "$PIPE_PATH"
    fi
    
    # Create tmux session with multiple panes
    if ! tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
        tmux new-session -d -s "${SESSION_NAME}" -c "${WORKSPACE_DIR}"
        
        # Split into 5 panes for different components
        tmux split-window -t "${SESSION_NAME}" -v -p 80  # Analysis pane
        tmux split-window -t "${SESSION_NAME}" -h -p 75  # Compliance pane
        tmux split-window -t "${SESSION_NAME}" -v -p 66  # Patterns pane
        tmux split-window -t "${SESSION_NAME}" -h -p 50  # Monitor pane
        
        # Set up environment in each pane
        tmux send-keys -t "${SESSION_NAME}:0.0" "export MW1_ID='${DECOMPOSER_ID}'" Enter
        tmux send-keys -t "${SESSION_NAME}:0.0" "export WORKSPACE_DIR='${WORKSPACE_DIR}'" Enter
        tmux send-keys -t "${SESSION_NAME}:0.0" "echo 'Master Worker 1 - Main Decomposition Engine Ready'" Enter
        
        tmux send-keys -t "${SESSION_NAME}:0.1" "cd ${WORKSPACE_DIR} && python3 ${CLAUDE_DIR}/engines/complexity-scoring.py" Enter
        tmux send-keys -t "${SESSION_NAME}:0.2" "${CLAUDE_DIR}/scripts/compliance-auto-injector.sh ${DECOMPOSER_ID}" Enter
        tmux send-keys -t "${SESSION_NAME}:0.3" "echo 'Pattern Matching Engine Ready'" Enter
        tmux send-keys -t "${SESSION_NAME}:0.4" "${CLAUDE_DIR}/scripts/agent-monitor.sh master-decomposer-${DECOMPOSER_ID}" Enter
        
        # Focus on main pane
        tmux select-pane -t "${SESSION_NAME}:0.0"
    fi
    
    # Save session configuration
    cat > "${WORKSPACE_DIR}/session-config.json" << EOF
{
    "decomposer_id": "${DECOMPOSER_ID}",
    "project_name": "${PROJECT_NAME}",
    "session_name": "${SESSION_NAME}",
    "workspace_dir": "${WORKSPACE_DIR}",
    "pipe_path": "${PIPE_PATH}",
    "max_levels": ${MAX_DECOMPOSITION_LEVELS},
    "complexity_threshold": ${COMPLEXITY_THRESHOLD},
    "economic_threshold": ${ECONOMIC_THRESHOLD},
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "active"
}
EOF
    
    log_event "SUCCESS" "Master Worker 1 initialized successfully"
}

# Analyze user query and extract intent
analyze_query() {
    local query="$1"
    local analysis_file="${WORKSPACE_DIR}/input/query-analysis.json"
    
    log_event "INFO" "Analyzing query: ${query}"
    
    # Use Python engine for natural language analysis
    python3 - << EOF
import json
import re
import sys
from datetime import datetime

query = """$query"""
analysis = {
    "original_query": query,
    "analyzed_at": datetime.utcnow().isoformat() + "Z",
    "intent_extraction": {},
    "complexity_indicators": {},
    "requirements": {},
    "estimated_complexity": 0.0
}

# Intent extraction patterns
intent_patterns = {
    "create": r"(build|create|develop|make|implement|generate)",
    "optimize": r"(optimize|improve|enhance|speed up|faster|better)",
    "security": r"(secure|security|authentication|authorization|encrypt|compliance)",
    "analyze": r"(analyze|review|audit|check|examine|inspect)",
    "fix": r"(fix|debug|resolve|troubleshoot|repair)",
    "test": r"(test|verify|validate|qa|quality)",
    "deploy": r"(deploy|release|publish|launch|production)"
}

for intent, pattern in intent_patterns.items():
    if re.search(pattern, query.lower()):
        analysis["intent_extraction"][intent] = True

# Complexity indicators
complexity_indicators = [
    ("high", r"(enterprise|large-scale|complex|comprehensive|advanced)"),
    ("medium", r"(moderate|standard|typical|normal)"),
    ("low", r"(simple|basic|quick|small|minor)")
]

for level, pattern in complexity_indicators:
    if re.search(pattern, query.lower()):
        analysis["complexity_indicators"][level] = True

# Technology detection
tech_patterns = {
    "frontend": r"(react|vue|angular|frontend|ui|interface|dashboard)",
    "backend": r"(api|backend|server|database|microservice)",
    "database": r"(database|sql|nosql|postgresql|mysql|mongodb)",
    "cloud": r"(aws|azure|gcp|cloud|kubernetes|docker)",
    "security": r"(auth|oauth|jwt|encryption|ssl|https)"
}

analysis["technologies"] = {}
for tech, pattern in tech_patterns.items():
    if re.search(pattern, query.lower()):
        analysis["technologies"][tech] = True

# Estimate overall complexity (0.0-1.0)
complexity_score = 0.0
if analysis["complexity_indicators"].get("high"):
    complexity_score += 0.4
elif analysis["complexity_indicators"].get("medium"):
    complexity_score += 0.2
else:
    complexity_score += 0.1

complexity_score += len(analysis["technologies"]) * 0.1
complexity_score += len(analysis["intent_extraction"]) * 0.05

analysis["estimated_complexity"] = min(complexity_score, 1.0)

# Save analysis
with open("$analysis_file", "w") as f:
    json.dump(analysis, f, indent=2)

print(f"Query analysis complete. Complexity: {analysis['estimated_complexity']:.2f}")
EOF
    
    local complexity=$(jq -r '.estimated_complexity' "$analysis_file")
    log_event "INFO" "Query complexity estimated at: ${complexity}"
    echo "$analysis_file"
}

# Recursive task decomposition engine
decompose_task() {
    local query="$1"
    local level="${2:-1}"
    local parent_task="${3:-root}"
    local decomposition_file="${WORKSPACE_DIR}/output/decomposition-level-${level}.json"
    
    log_event "INFO" "Decomposing task at level ${level}: ${query}"
    
    # Check termination conditions
    if [[ $level -gt $MAX_DECOMPOSITION_LEVELS ]]; then
        log_event "WARN" "Maximum decomposition levels reached (${MAX_DECOMPOSITION_LEVELS})"
        return 0
    fi
    
    # Get complexity score
    local analysis_file=$(analyze_query "$query")
    local complexity=$(jq -r '.estimated_complexity' "$analysis_file")
    
    # Check complexity threshold
    if (( $(echo "$complexity < $COMPLEXITY_THRESHOLD" | bc -l) )); then
        log_event "INFO" "Task complexity below threshold (${complexity} < ${COMPLEXITY_THRESHOLD}), stopping decomposition"
        return 0
    fi
    
    # Decompose using Python engine
    python3 - << EOF
import json
import re
from datetime import datetime

query = """$query"""
level = $level
parent_task = """$parent_task"""
analysis_file = """$analysis_file"""

# Load previous analysis
with open(analysis_file, 'r') as f:
    analysis = json.load(f)

decomposition = {
    "query": query,
    "level": level,
    "parent_task": parent_task,
    "decomposed_at": datetime.utcnow().isoformat() + "Z",
    "subtasks": [],
    "agents_required": [],
    "compliance_requirements": [],
    "estimated_effort": 0
}

# Task decomposition patterns based on intent
if "create" in analysis.get("intent_extraction", {}):
    if "frontend" in analysis.get("technologies", {}):
        decomposition["subtasks"].extend([
            {"name": "ui_design", "description": "Design user interface and components", "complexity": 0.4},
            {"name": "component_development", "description": "Develop React/Vue components", "complexity": 0.6},
            {"name": "state_management", "description": "Implement state management", "complexity": 0.5},
            {"name": "routing", "description": "Setup application routing", "complexity": 0.3}
        ])
        decomposition["agents_required"].extend(["ui-designer", "frontend-developer", "state-specialist"])
    
    if "backend" in analysis.get("technologies", {}):
        decomposition["subtasks"].extend([
            {"name": "api_design", "description": "Design REST/GraphQL API", "complexity": 0.5},
            {"name": "database_schema", "description": "Design database schema", "complexity": 0.4},
            {"name": "business_logic", "description": "Implement business logic", "complexity": 0.7},
            {"name": "api_implementation", "description": "Implement API endpoints", "complexity": 0.6}
        ])
        decomposition["agents_required"].extend(["api-architect", "database-designer", "backend-developer"])

if "security" in analysis.get("intent_extraction", {}):
    decomposition["subtasks"].extend([
        {"name": "authentication", "description": "Implement user authentication", "complexity": 0.6},
        {"name": "authorization", "description": "Setup role-based access control", "complexity": 0.5},
        {"name": "data_encryption", "description": "Implement data encryption", "complexity": 0.7},
        {"name": "security_audit", "description": "Conduct security audit", "complexity": 0.4}
    ])
    decomposition["agents_required"].extend(["security-specialist", "auth-specialist", "compliance-officer"])

if "optimize" in analysis.get("intent_extraction", {}):
    decomposition["subtasks"].extend([
        {"name": "performance_analysis", "description": "Analyze current performance", "complexity": 0.4},
        {"name": "bottleneck_identification", "description": "Identify performance bottlenecks", "complexity": 0.5},
        {"name": "optimization_implementation", "description": "Implement optimizations", "complexity": 0.6},
        {"name": "performance_validation", "description": "Validate performance improvements", "complexity": 0.3}
    ])
    decomposition["agents_required"].extend(["performance-specialist", "optimization-engineer"])

# Add compliance requirements based on detected technologies
if "security" in analysis.get("technologies", {}):
    decomposition["compliance_requirements"].extend(["SOC2", "GDPR", "security-audit"])
if "database" in analysis.get("technologies", {}):
    decomposition["compliance_requirements"].extend(["data-protection", "backup-strategy"])

# Calculate total estimated effort
total_effort = sum(task.get("complexity", 0.5) for task in decomposition["subtasks"])
decomposition["estimated_effort"] = total_effort

# Save decomposition
with open("$decomposition_file", "w") as f:
    json.dump(decomposition, f, indent=2)

print(f"Decomposed into {len(decomposition['subtasks'])} subtasks requiring {len(set(decomposition['agents_required']))} agent types")
EOF
    
    # Check if further decomposition is needed
    local subtask_count=$(jq '.subtasks | length' "$decomposition_file")
    if [[ $subtask_count -gt 0 ]]; then
        # Recursively decompose complex subtasks
        jq -r '.subtasks[] | select(.complexity > 0.5) | .name + "|" + .description' "$decomposition_file" | while IFS='|' read -r name description; do
            if [[ -n "$name" && -n "$description" ]]; then
                decompose_task "$description" $((level + 1)) "$name"
            fi
        done
    fi
    
    echo "$decomposition_file"
}

# Generate final decomposition report
generate_decomposition_report() {
    local query="$1"
    local report_file="${WORKSPACE_DIR}/output/final-decomposition-report.json"
    
    log_event "INFO" "Generating final decomposition report"
    
    # Collect all decomposition files
    find "${WORKSPACE_DIR}/output" -name "decomposition-level-*.json" -type f | sort | while read -r file; do
        echo "Processing decomposition file: $file"
        cat "$file"
    done | jq -s '.' > "${WORKSPACE_DIR}/temp/all-decompositions.json"
    
    # Generate comprehensive report
    python3 - << EOF
import json
from datetime import datetime
from collections import defaultdict

query = """$query"""

# Load all decompositions
with open("${WORKSPACE_DIR}/temp/all-decompositions.json", 'r') as f:
    decompositions = json.load(f)

report = {
    "original_query": query,
    "generated_at": datetime.utcnow().isoformat() + "Z",
    "decomposition_summary": {
        "total_levels": len(decompositions),
        "total_subtasks": 0,
        "unique_agents_required": set(),
        "compliance_requirements": set(),
        "total_estimated_effort": 0
    },
    "task_hierarchy": {},
    "agent_assignments": defaultdict(list),
    "compliance_matrix": {},
    "execution_plan": []
}

# Process all decompositions
for decomp in decompositions:
    level = decomp.get("level", 1)
    report["decomposition_summary"]["total_subtasks"] += len(decomp.get("subtasks", []))
    report["decomposition_summary"]["unique_agents_required"].update(decomp.get("agents_required", []))
    report["decomposition_summary"]["compliance_requirements"].update(decomp.get("compliance_requirements", []))
    report["decomposition_summary"]["total_estimated_effort"] += decomp.get("estimated_effort", 0)
    
    # Build task hierarchy
    if level not in report["task_hierarchy"]:
        report["task_hierarchy"][level] = []
    report["task_hierarchy"][level].append({
        "query": decomp.get("query"),
        "parent": decomp.get("parent_task"),
        "subtasks": decomp.get("subtasks", [])
    })
    
    # Build agent assignments
    for agent in decomp.get("agents_required", []):
        report["agent_assignments"][agent].extend([
            task["name"] for task in decomp.get("subtasks", [])
        ])

# Convert sets to lists for JSON serialization
report["decomposition_summary"]["unique_agents_required"] = list(report["decomposition_summary"]["unique_agents_required"])
report["decomposition_summary"]["compliance_requirements"] = list(report["decomposition_summary"]["compliance_requirements"])
report["agent_assignments"] = dict(report["agent_assignments"])

# Generate execution plan
execution_plan = []
for level in sorted(report["task_hierarchy"].keys()):
    for task_group in report["task_hierarchy"][level]:
        for subtask in task_group.get("subtasks", []):
            execution_plan.append({
                "level": level,
                "task": subtask["name"],
                "description": subtask["description"],
                "complexity": subtask.get("complexity", 0.5),
                "estimated_duration": subtask.get("complexity", 0.5) * 2,  # hours
                "dependencies": []
            })

report["execution_plan"] = execution_plan

# Save final report
with open("$report_file", "w") as f:
    json.dump(report, f, indent=2)

print(f"Final report generated with {report['decomposition_summary']['total_subtasks']} subtasks across {report['decomposition_summary']['total_levels']} levels")
print(f"Requires {len(report['decomposition_summary']['unique_agents_required'])} unique agent types")
print(f"Total estimated effort: {report['decomposition_summary']['total_estimated_effort']:.2f} complexity units")
EOF
    
    log_event "SUCCESS" "Decomposition report generated: $report_file"
    echo "$report_file"
}

# Send decomposition to Master Worker 2
send_to_agent_assignment() {
    local report_file="$1"
    local message=$(jq -c . "$report_file")
    
    log_event "INFO" "Sending decomposition to Master Worker 2 for agent assignment"
    
    # Create message for MW2
    local mw2_message=$(jq -n \
        --arg from "master-decomposer-${DECOMPOSER_ID}" \
        --arg to "master-agent-matcher" \
        --arg type "task_decomposition" \
        --argjson payload "$message" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            from: $from,
            to: $to,
            type: $type,
            payload: $payload,
            timestamp: $timestamp
        }')
    
    # Send via secure message handler
    echo "$mw2_message" | "${CLAUDE_DIR}/scripts/secure-message-handler.sh" send "master-decomposer-${DECOMPOSER_ID}" "master-agent-matcher" "task_decomposition" -
    
    log_event "SUCCESS" "Decomposition sent to Master Worker 2"
}

# Main execution function
main() {
    case "${1:-help}" in
        "init")
            initialize_decomposer
            ;;
        "decompose")
            if [[ -z "${2:-}" ]]; then
                echo "Error: Query required for decomposition"
                exit 1
            fi
            
            initialize_decomposer
            
            log_event "INFO" "Starting recursive decomposition for query: $2"
            decompose_task "$2"
            
            report_file=$(generate_decomposition_report "$2")
            send_to_agent_assignment "$report_file"
            
            echo "Decomposition complete. Report: $report_file"
            ;;
        "status")
            if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
                echo "Master Worker 1 is active (session: ${SESSION_NAME})"
                echo "Workspace: ${WORKSPACE_DIR}"
                echo "Pipe: ${PIPE_PATH}"
            else
                echo "Master Worker 1 is not running"
            fi
            ;;
        "connect")
            if command -v sesh >/dev/null 2>&1; then
                sesh connect "${SESSION_NAME}"
            else
                tmux attach-session -t "${SESSION_NAME}"
            fi
            ;;
        *)
            echo "Master Worker 1 - Recursive Task Decomposition Engine"
            echo "Usage: $0 {init|decompose|status|connect}"
            echo ""
            echo "Commands:"
            echo "  init                    - Initialize Master Worker 1"
            echo "  decompose <query>       - Decompose user query recursively"
            echo "  status                  - Check Master Worker 1 status"
            echo "  connect                 - Connect to Master Worker 1 tmux session"
            ;;
    esac
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"