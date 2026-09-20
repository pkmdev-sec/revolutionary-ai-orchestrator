#!/bin/bash

# Master Worker 2 - Intelligent Agent Assignment Matrix
# Revolutionary AI Orchestration System - Phase 2 Implementation

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
MATCHER_ID="${1:-$(date +%s)-$(openssl rand -hex 4)}"
PROJECT_NAME="${2:-default}"
SESSION_NAME="claude-master-matcher-${MATCHER_ID}"
WORKSPACE_DIR="${CLAUDE_DIR}/agents/master-matcher-${MATCHER_ID}/workspace"
PIPE_PATH="${CLAUDE_DIR}/pipes/pipe_master-matcher-${MATCHER_ID}"

# Configuration
ASSIGNMENT_ACCURACY_TARGET=0.95
ML_CONFIDENCE_THRESHOLD=0.8
AGENT_POOL_SIZE=50
LOG_FILE="${CLAUDE_DIR}/logs/master-worker-2.log"

# Logging function
log_event() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "[${timestamp}] [MW2-${MATCHER_ID}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Initialize Master Worker 2 environment
initialize_agent_matcher() {
    log_event "INFO" "Initializing Master Worker 2 - Intelligent Agent Assignment Matrix"
    
    # Create workspace with secure permissions
    mkdir -p "${WORKSPACE_DIR}"/{input,output,models,assignments,compatibility,temp}
    chmod 700 "${WORKSPACE_DIR}"
    
    # Create communication pipe
    if [[ ! -p "$PIPE_PATH" ]]; then
        mkfifo "$PIPE_PATH"
        chmod 600 "$PIPE_PATH"
    fi
    
    # Create tmux session with multiple panes
    if ! tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
        tmux new-session -d -s "${SESSION_NAME}" -c "${WORKSPACE_DIR}"
        
        # Split into 6 panes for different components
        tmux split-window -t "${SESSION_NAME}" -v -p 83  # ML Scoring pane
        tmux split-window -t "${SESSION_NAME}" -h -p 80  # Compatibility pane
        tmux split-window -t "${SESSION_NAME}" -v -p 75  # Assignment pane
        tmux split-window -t "${SESSION_NAME}" -h -p 66  # Optimization pane
        tmux split-window -t "${SESSION_NAME}" -v -p 50  # Monitor pane
        
        # Set up environment in each pane
        tmux send-keys -t "${SESSION_NAME}:0.0" "export MW2_ID='${MATCHER_ID}'" Enter
        tmux send-keys -t "${SESSION_NAME}:0.0" "export WORKSPACE_DIR='${WORKSPACE_DIR}'" Enter
        tmux send-keys -t "${SESSION_NAME}:0.0" "echo 'Master Worker 2 - Agent Assignment Matrix Ready'" Enter
        
        tmux send-keys -t "${SESSION_NAME}:0.1" "cd ${WORKSPACE_DIR} && python3 ${CLAUDE_DIR}/engines/ml-agent-scorer.py ${WORKSPACE_DIR}" Enter
        tmux send-keys -t "${SESSION_NAME}:0.2" "cd ${WORKSPACE_DIR} && python3 ${CLAUDE_DIR}/engines/compatibility-engine.py ${WORKSPACE_DIR}" Enter
        tmux send-keys -t "${SESSION_NAME}:0.3" "${CLAUDE_DIR}/scripts/assignment-optimizer.sh ${MATCHER_ID}" Enter
        tmux send-keys -t "${SESSION_NAME}:0.4" "${CLAUDE_DIR}/scripts/ml-performance-optimizer.sh ${MATCHER_ID}" Enter
        tmux send-keys -t "${SESSION_NAME}:0.5" "${CLAUDE_DIR}/scripts/agent-monitor.sh master-matcher-${MATCHER_ID}" Enter
        
        # Focus on main pane
        tmux select-pane -t "${SESSION_NAME}:0.0"
    fi
    
    # Save session configuration
    cat > "${WORKSPACE_DIR}/session-config.json" << EOF
{
    "matcher_id": "${MATCHER_ID}",
    "project_name": "${PROJECT_NAME}",
    "session_name": "${SESSION_NAME}",
    "workspace_dir": "${WORKSPACE_DIR}",
    "pipe_path": "${PIPE_PATH}",
    "accuracy_target": ${ASSIGNMENT_ACCURACY_TARGET},
    "ml_threshold": ${ML_CONFIDENCE_THRESHOLD},
    "agent_pool_size": ${AGENT_POOL_SIZE},
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "active"
}
EOF
    
    log_event "SUCCESS" "Master Worker 2 initialized successfully"
}

# Build agent capability matrix from available agents
build_agent_capability_matrix() {
    local matrix_file="${WORKSPACE_DIR}/models/agent-capability-matrix.json"
    
    log_event "INFO" "Building agent capability matrix"
    
    python3 - << EOF
import json
from datetime import datetime

# Define comprehensive agent types and their capabilities
agent_matrix = {
    "generated_at": datetime.utcnow().isoformat() + "Z",
    "version": "2.0",
    "agents": {
        "frontend-developer": {
            "capabilities": ["react", "vue", "angular", "typescript", "javascript", "css", "html", "ui-design"],
            "technology_stack": ["frontend", "web", "spa", "pwa"],
            "complexity_range": [0.2, 0.8],
            "specialization_score": 0.9,
            "collaboration_score": 0.8,
            "speed_multiplier": 1.2,
            "cost_factor": 1.0
        },
        "backend-developer": {
            "capabilities": ["api", "database", "microservices", "rest", "graphql", "node.js", "python", "java"],
            "technology_stack": ["backend", "server", "api", "database"],
            "complexity_range": [0.3, 0.9],
            "specialization_score": 0.85,
            "collaboration_score": 0.9,
            "speed_multiplier": 1.0,
            "cost_factor": 1.1
        },
        "fullstack-developer": {
            "capabilities": ["frontend", "backend", "database", "api", "react", "node.js", "typescript"],
            "technology_stack": ["fullstack", "web", "api", "database"],
            "complexity_range": [0.4, 0.8],
            "specialization_score": 0.7,
            "collaboration_score": 0.95,
            "speed_multiplier": 0.9,
            "cost_factor": 1.3
        },
        "security-specialist": {
            "capabilities": ["authentication", "authorization", "encryption", "audit", "compliance", "security"],
            "technology_stack": ["security", "auth", "compliance"],
            "complexity_range": [0.5, 1.0],
            "specialization_score": 0.95,
            "collaboration_score": 0.7,
            "speed_multiplier": 0.8,
            "cost_factor": 1.5
        },
        "devops-engineer": {
            "capabilities": ["docker", "kubernetes", "ci/cd", "infrastructure", "monitoring", "deployment"],
            "technology_stack": ["cloud", "infrastructure", "containers"],
            "complexity_range": [0.4, 0.9],
            "specialization_score": 0.9,
            "collaboration_score": 0.8,
            "speed_multiplier": 1.1,
            "cost_factor": 1.2
        },
        "database-specialist": {
            "capabilities": ["postgresql", "mysql", "mongodb", "schema-design", "optimization", "migration"],
            "technology_stack": ["database", "data", "sql", "nosql"],
            "complexity_range": [0.3, 0.8],
            "specialization_score": 0.9,
            "collaboration_score": 0.75,
            "speed_multiplier": 1.0,
            "cost_factor": 1.1
        },
        "ui-designer": {
            "capabilities": ["ui-design", "ux", "prototyping", "wireframes", "user-research"],
            "technology_stack": ["design", "ui", "ux"],
            "complexity_range": [0.2, 0.6],
            "specialization_score": 0.85,
            "collaboration_score": 0.9,
            "speed_multiplier": 1.3,
            "cost_factor": 0.9
        },
        "api-architect": {
            "capabilities": ["api-design", "rest", "graphql", "microservices", "architecture"],
            "technology_stack": ["api", "architecture", "backend"],
            "complexity_range": [0.5, 0.9],
            "specialization_score": 0.9,
            "collaboration_score": 0.8,
            "speed_multiplier": 0.9,
            "cost_factor": 1.3
        },
        "performance-specialist": {
            "capabilities": ["optimization", "performance", "scaling", "caching", "profiling"],
            "technology_stack": ["performance", "optimization"],
            "complexity_range": [0.4, 0.8],
            "specialization_score": 0.85,
            "collaboration_score": 0.7,
            "speed_multiplier": 0.8,
            "cost_factor": 1.4
        },
        "compliance-officer": {
            "capabilities": ["compliance", "audit", "gdpr", "hipaa", "soc2", "documentation"],
            "technology_stack": ["compliance", "audit", "governance"],
            "complexity_range": [0.3, 0.7],
            "specialization_score": 0.9,
            "collaboration_score": 0.8,
            "speed_multiplier": 0.9,
            "cost_factor": 1.2
        },
        "data-scientist": {
            "capabilities": ["machine-learning", "ai", "data-analysis", "python", "tensorflow", "pytorch"],
            "technology_stack": ["ml", "ai", "data", "python"],
            "complexity_range": [0.6, 1.0],
            "specialization_score": 0.95,
            "collaboration_score": 0.6,
            "speed_multiplier": 0.7,
            "cost_factor": 1.8
        },
        "qa-specialist": {
            "capabilities": ["testing", "automation", "quality-assurance", "test-planning"],
            "technology_stack": ["testing", "qa", "automation"],
            "complexity_range": [0.2, 0.6],
            "specialization_score": 0.8,
            "collaboration_score": 0.9,
            "speed_multiplier": 1.1,
            "cost_factor": 0.8
        }
    },
    "compatibility_matrix": {
        "high_compatibility": [
            ["frontend-developer", "ui-designer"],
            ["backend-developer", "database-specialist"],
            ["devops-engineer", "security-specialist"],
            ["api-architect", "backend-developer"],
            ["performance-specialist", "backend-developer"],
            ["compliance-officer", "security-specialist"]
        ],
        "medium_compatibility": [
            ["fullstack-developer", "ui-designer"],
            ["frontend-developer", "backend-developer"],
            ["data-scientist", "backend-developer"],
            ["qa-specialist", "frontend-developer"],
            ["qa-specialist", "backend-developer"]
        ],
        "low_compatibility": [
            ["ui-designer", "database-specialist"],
            ["data-scientist", "ui-designer"],
            ["compliance-officer", "ui-designer"]
        ]
    }
}

# Save agent capability matrix
with open("$matrix_file", "w") as f:
    json.dump(agent_matrix, f, indent=2)

print(f"Agent capability matrix built with {len(agent_matrix['agents'])} agent types")
print(f"High compatibility pairs: {len(agent_matrix['compatibility_matrix']['high_compatibility'])}")
EOF
    
    log_event "SUCCESS" "Agent capability matrix built: $matrix_file"
    echo "$matrix_file"
}

# Analyze task requirements and match to agents
analyze_task_agent_compatibility() {
    local decomposition_file="$1"
    local compatibility_file="${WORKSPACE_DIR}/assignments/task-agent-compatibility.json"
    
    log_event "INFO" "Analyzing task-agent compatibility"
    
    python3 - << EOF
import json
import re
from datetime import datetime

# Load decomposition and agent matrix
with open("$decomposition_file", "r") as f:
    decomposition = json.load(f)

matrix_file = "${WORKSPACE_DIR}/models/agent-capability-matrix.json"
with open(matrix_file, "r") as f:
    agent_matrix = json.load(f)

compatibility_analysis = {
    "analyzed_at": datetime.utcnow().isoformat() + "Z",
    "decomposition_source": "$decomposition_file",
    "task_assignments": [],
    "agent_utilization": {},
    "compatibility_scores": {},
    "optimization_suggestions": []
}

# Extract tasks from decomposition
tasks = []
if "execution_plan" in decomposition:
    tasks = decomposition["execution_plan"]
elif "subtasks" in decomposition:
    tasks = decomposition["subtasks"]

# Analyze each task for agent compatibility
for task in tasks:
    task_name = task.get("name", "unknown")
    task_description = task.get("description", "").lower()
    task_complexity = task.get("complexity", 0.5)
    
    # Calculate compatibility scores for each agent type
    agent_scores = {}
    
    for agent_type, agent_info in agent_matrix["agents"].items():
        compatibility_score = 0.0
        
        # Check capability match
        capability_matches = 0
        for capability in agent_info["capabilities"]:
            if capability.lower() in task_description:
                capability_matches += 1
                compatibility_score += 0.2
        
        # Check technology stack alignment
        tech_matches = 0
        for tech in agent_info["technology_stack"]:
            if tech.lower() in task_description:
                tech_matches += 1
                compatibility_score += 0.15
        
        # Check complexity range fit
        complexity_min, complexity_max = agent_info["complexity_range"]
        if complexity_min <= task_complexity <= complexity_max:
            complexity_fit = 1.0 - abs(task_complexity - (complexity_min + complexity_max) / 2) / (complexity_max - complexity_min)
            compatibility_score += complexity_fit * 0.3
        
        # Apply specialization bonus
        if capability_matches > 0:
            compatibility_score *= agent_info["specialization_score"]
        
        # Calculate final score (0.0 - 1.0)
        agent_scores[agent_type] = min(compatibility_score, 1.0)
    
    # Find best matching agents (top 3)
    sorted_agents = sorted(agent_scores.items(), key=lambda x: x[1], reverse=True)
    best_matches = sorted_agents[:3]
    
    task_assignment = {
        "task_name": task_name,
        "task_description": task.get("description", ""),
        "task_complexity": task_complexity,
        "recommended_agents": [
            {
                "agent_type": agent_type,
                "compatibility_score": score,
                "confidence": "high" if score >= 0.8 else "medium" if score >= 0.5 else "low"
            }
            for agent_type, score in best_matches if score > 0.3
        ],
        "assignment_rationale": f"Based on {len([s for s in agent_scores.values() if s > 0.3])} compatible agents",
        "estimated_effort": task_complexity * agent_matrix["agents"][best_matches[0][0]]["speed_multiplier"] if best_matches else task_complexity
    }
    
    compatibility_analysis["task_assignments"].append(task_assignment)
    
    # Track agent utilization
    if best_matches:
        best_agent = best_matches[0][0]
        if best_agent not in compatibility_analysis["agent_utilization"]:
            compatibility_analysis["agent_utilization"][best_agent] = 0
        compatibility_analysis["agent_utilization"][best_agent] += 1

# Calculate overall compatibility scores
total_tasks = len(tasks)
high_confidence_assignments = sum(1 for ta in compatibility_analysis["task_assignments"] 
                                if ta["recommended_agents"] and ta["recommended_agents"][0]["confidence"] == "high")

compatibility_analysis["compatibility_scores"] = {
    "overall_accuracy": high_confidence_assignments / total_tasks if total_tasks > 0 else 0,
    "high_confidence_ratio": high_confidence_assignments / total_tasks if total_tasks > 0 else 0,
    "agent_diversity": len(compatibility_analysis["agent_utilization"]),
    "average_task_coverage": sum(len(ta["recommended_agents"]) for ta in compatibility_analysis["task_assignments"]) / total_tasks if total_tasks > 0 else 0
}

# Generate optimization suggestions
if compatibility_analysis["compatibility_scores"]["overall_accuracy"] < 0.9:
    compatibility_analysis["optimization_suggestions"].append("Consider task decomposition refinement for better agent matching")

if compatibility_analysis["compatibility_scores"]["agent_diversity"] < 3:
    compatibility_analysis["optimization_suggestions"].append("Increase agent type diversity for better specialization")

# Save compatibility analysis
with open("$compatibility_file", "w") as f:
    json.dump(compatibility_analysis, f, indent=2)

print(f"Compatibility analysis complete: {compatibility_analysis['compatibility_scores']['overall_accuracy']:.2f} accuracy")
print(f"High confidence assignments: {high_confidence_assignments}/{total_tasks}")
print(f"Agent types utilized: {compatibility_analysis['compatibility_scores']['agent_diversity']}")
EOF
    
    log_event "SUCCESS" "Task-agent compatibility analyzed: $compatibility_file"
    echo "$compatibility_file"
}

# Generate optimal agent assignments
generate_optimal_assignments() {
    local compatibility_file="$1"
    local assignments_file="${WORKSPACE_DIR}/output/optimal-agent-assignments.json"
    
    log_event "INFO" "Generating optimal agent assignments"
    
    python3 - << EOF
import json
from datetime import datetime
from collections import defaultdict

# Load compatibility analysis
with open("$compatibility_file", "r") as f:
    compatibility = json.load(f)

# Load agent matrix for cost and collaboration data
matrix_file = "${WORKSPACE_DIR}/models/agent-capability-matrix.json"
with open(matrix_file, "r") as f:
    agent_matrix = json.load(f)

assignments = {
    "generated_at": datetime.utcnow().isoformat() + "Z",
    "optimization_strategy": "cost_performance_balanced",
    "agent_assignments": {},
    "team_composition": {},
    "execution_schedule": [],
    "resource_allocation": {},
    "performance_metrics": {}
}

# Track agent workload and assignments
agent_workload = defaultdict(list)
agent_effort = defaultdict(float)
total_cost = 0.0

# Assign tasks to optimal agents
for task_assignment in compatibility["task_assignments"]:
    task_name = task_assignment["task_name"]
    recommended_agents = task_assignment["recommended_agents"]
    estimated_effort = task_assignment["estimated_effort"]
    
    if not recommended_agents:
        continue
    
    # Select best agent considering workload balance
    best_agent = None
    best_score = -1
    
    for agent_rec in recommended_agents[:2]:  # Consider top 2 candidates
        agent_type = agent_rec["agent_type"]
        compatibility_score = agent_rec["compatibility_score"]
        
        # Calculate workload penalty
        current_workload = len(agent_workload[agent_type])
        workload_penalty = current_workload * 0.1  # 10% penalty per existing task
        
        # Calculate collaboration bonus
        collaboration_bonus = 0.0
        for existing_agent in agent_workload.keys():
            if agent_type != existing_agent:
                # Check compatibility matrix
                for high_compat in agent_matrix["compatibility_matrix"]["high_compatibility"]:
                    if (agent_type in high_compat and existing_agent in high_compat):
                        collaboration_bonus += 0.1
        
        # Calculate final assignment score
        assignment_score = compatibility_score - workload_penalty + collaboration_bonus
        
        if assignment_score > best_score:
            best_score = assignment_score
            best_agent = agent_type
    
    if best_agent:
        # Assign task to best agent
        agent_workload[best_agent].append(task_name)
        agent_effort[best_agent] += estimated_effort
        total_cost += estimated_effort * agent_matrix["agents"][best_agent]["cost_factor"]
        
        assignments["agent_assignments"][task_name] = {
            "assigned_agent": best_agent,
            "compatibility_score": best_score,
            "estimated_effort": estimated_effort,
            "assignment_reason": "optimal_balance",
            "dependencies": []
        }

# Build team composition
assignments["team_composition"] = {
    agent_type: {
        "tasks_assigned": len(tasks),
        "total_effort": round(agent_effort[agent_type], 2),
        "utilization_ratio": round(agent_effort[agent_type] / max(agent_effort.values()) if agent_effort.values() else 0, 2),
        "specialization": agent_matrix["agents"][agent_type]["specialization_score"],
        "cost_factor": agent_matrix["agents"][agent_type]["cost_factor"]
    }
    for agent_type, tasks in agent_workload.items()
}

# Generate execution schedule
execution_schedule = []
for level in range(1, 6):  # Up to 5 levels
    level_tasks = []
    for task_name, assignment in assignments["agent_assignments"].items():
        # Simple scheduling: assign based on agent availability
        level_tasks.append({
            "task": task_name,
            "agent": assignment["assigned_agent"],
            "estimated_duration": assignment["estimated_effort"] * 2,  # Convert to hours
            "level": level
        })
    
    if level_tasks:
        execution_schedule.extend(level_tasks[:3])  # Max 3 tasks per level

assignments["execution_schedule"] = execution_schedule

# Calculate performance metrics
total_tasks = len(assignments["agent_assignments"])
unique_agents = len(assignments["team_composition"])
avg_compatibility = sum(a["compatibility_score"] for a in assignments["agent_assignments"].values()) / total_tasks if total_tasks > 0 else 0

assignments["performance_metrics"] = {
    "total_tasks": total_tasks,
    "unique_agents_required": unique_agents,
    "average_compatibility": round(avg_compatibility, 3),
    "estimated_total_cost": round(total_cost, 2),
    "team_efficiency": round(1.0 / max(1, unique_agents - 2), 2),  # Fewer agents = higher efficiency
    "workload_balance": round(1.0 - (max(agent_effort.values()) - min(agent_effort.values())) / max(agent_effort.values()) if agent_effort.values() else 1.0, 2)
}

# Resource allocation
assignments["resource_allocation"] = {
    "agent_hours": dict(agent_effort),
    "total_estimated_hours": sum(agent_effort.values()),
    "cost_breakdown": {
        agent_type: round(effort * agent_matrix["agents"][agent_type]["cost_factor"], 2)
        for agent_type, effort in agent_effort.items()
    }
}

# Save optimal assignments
with open("$assignments_file", "w") as f:
    json.dump(assignments, f, indent=2)

print(f"Optimal assignments generated for {total_tasks} tasks across {unique_agents} agents")
print(f"Average compatibility score: {avg_compatibility:.3f}")
print(f"Team efficiency: {assignments['performance_metrics']['team_efficiency']:.2f}")
EOF
    
    log_event "SUCCESS" "Optimal agent assignments generated: $assignments_file"
    echo "$assignments_file"
}

# Send assignments to Master Worker 3
send_to_agent_creation() {
    local assignments_file="$1"
    local message=$(jq -c . "$assignments_file")
    
    log_event "INFO" "Sending assignments to Master Worker 3 for agent creation"
    
    # Create message for MW3
    local mw3_message=$(jq -n \
        --arg from "master-matcher-${MATCHER_ID}" \
        --arg to "master-agent-factory" \
        --arg type "agent_assignments" \
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
    echo "$mw3_message" | "${CLAUDE_DIR}/scripts/secure-message-handler.sh" send "master-matcher-${MATCHER_ID}" "master-agent-factory" "agent_assignments" -
    
    log_event "SUCCESS" "Assignments sent to Master Worker 3"
}

# Main execution function
main() {
    case "${1:-help}" in
        "init")
            initialize_agent_matcher
            build_agent_capability_matrix
            ;;
        "assign")
            if [[ -z "${2:-}" ]]; then
                echo "Error: Decomposition file required for assignment"
                exit 1
            fi
            
            initialize_agent_matcher
            matrix_file=$(build_agent_capability_matrix)
            compatibility_file=$(analyze_task_agent_compatibility "$2")
            assignments_file=$(generate_optimal_assignments "$compatibility_file")
            send_to_agent_creation "$assignments_file"
            
            echo "Agent assignment complete. Assignments: $assignments_file"
            ;;
        "status")
            if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
                echo "Master Worker 2 is active (session: ${SESSION_NAME})"
                echo "Workspace: ${WORKSPACE_DIR}"
                echo "Pipe: ${PIPE_PATH}"
            else
                echo "Master Worker 2 is not running"
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
            echo "Master Worker 2 - Intelligent Agent Assignment Matrix"
            echo "Usage: $0 {init|assign|status|connect}"
            echo ""
            echo "Commands:"
            echo "  init                      - Initialize Master Worker 2"
            echo "  assign <decomp_file>      - Generate optimal agent assignments"
            echo "  status                    - Check Master Worker 2 status"
            echo "  connect                   - Connect to Master Worker 2 tmux session"
            ;;
    esac
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"