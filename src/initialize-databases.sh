#!/bin/bash

# Database Initialization Script
# Revolutionary AI Orchestration System - Phase 2

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
DATABASES_DIR="${CLAUDE_DIR}/databases"
LOG_FILE="${CLAUDE_DIR}/logs/database-init.log"

# Logging function
log_event() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "[${timestamp}] [DB-INIT] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Initialize all required databases
initialize_databases() {
    log_event "INFO" "Initializing Phase 2 database infrastructure"
    
    # Create databases directory
    mkdir -p "${DATABASES_DIR}"
    chmod 700 "${DATABASES_DIR}"
    
    # Initialize each database
    init_task_complexity_db
    init_agent_scoring_db
    init_compatibility_db
    init_agent_templates_db
    init_orchestration_history_db
    
    log_event "SUCCESS" "All databases initialized successfully"
}

# Initialize task complexity database
init_task_complexity_db() {
    local db_file="${DATABASES_DIR}/task-complexity.db"
    
    log_event "INFO" "Initializing task complexity database"
    
    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS complexity_scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    query_hash TEXT UNIQUE,
    complexity_score REAL NOT NULL,
    intent_keywords TEXT,
    technology_keywords TEXT,
    domain_keywords TEXT,
    word_count INTEGER,
    estimated_effort REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS complexity_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_type TEXT NOT NULL,
    pattern_text TEXT NOT NULL,
    weight REAL NOT NULL,
    category TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_complexity_query_hash ON complexity_scores(query_hash);
CREATE INDEX IF NOT EXISTS idx_complexity_patterns_type ON complexity_patterns(pattern_type);

-- Insert sample complexity patterns
INSERT OR IGNORE INTO complexity_patterns (pattern_type, pattern_text, weight, category) VALUES
('high', 'enterprise', 0.4, 'scale'),
('high', 'large-scale', 0.4, 'scale'),
('high', 'microservices', 0.4, 'architecture'),
('high', 'machine learning', 0.4, 'technology'),
('medium', 'api', 0.2, 'technology'),
('medium', 'database', 0.2, 'technology'),
('low', 'simple', 0.1, 'complexity'),
('low', 'basic', 0.1, 'complexity');
EOF
    
    log_event "SUCCESS" "Task complexity database initialized: $db_file"
}

# Initialize agent scoring database
init_agent_scoring_db() {
    local db_file="${DATABASES_DIR}/agent-scoring.db"
    
    log_event "INFO" "Initializing agent scoring database"
    
    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS agent_performance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_type TEXT NOT NULL,
    task_type TEXT NOT NULL,
    task_description TEXT,
    complexity_score REAL,
    completion_time REAL,
    quality_score REAL,
    success_rate REAL,
    collaboration_score REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_agent_vectors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_description TEXT NOT NULL,
    task_vector TEXT,
    agent_type TEXT NOT NULL,
    compatibility_score REAL,
    confidence_level REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ml_model_performance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_version TEXT,
    accuracy REAL,
    precision_score REAL,
    recall_score REAL,
    f1_score REAL,
    training_samples INTEGER,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_performance_type ON agent_performance(agent_type);
CREATE INDEX IF NOT EXISTS idx_task_vectors_agent ON task_agent_vectors(agent_type);

-- Insert sample agent performance data
INSERT OR IGNORE INTO agent_performance (agent_type, task_type, task_description, complexity_score, completion_time, quality_score, success_rate, collaboration_score) VALUES
('frontend-developer', 'ui-component', 'Create React dashboard component', 0.4, 4.5, 0.9, 0.95, 0.8),
('backend-developer', 'api-development', 'Build REST API endpoints', 0.5, 5.2, 0.9, 0.92, 0.85),
('security-specialist', 'authentication', 'Implement OAuth authentication', 0.7, 8.0, 0.95, 0.9, 0.7),
('devops-engineer', 'containerization', 'Setup Docker containers', 0.4, 3.8, 0.9, 0.95, 0.85);
EOF
    
    log_event "SUCCESS" "Agent scoring database initialized: $db_file"
}

# Initialize compatibility database
init_compatibility_db() {
    local db_file="${DATABASES_DIR}/compatibility.db"
    
    log_event "INFO" "Initializing compatibility database"
    
    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS agent_compatibility (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_type_1 TEXT NOT NULL,
    agent_type_2 TEXT NOT NULL,
    compatibility_score REAL NOT NULL,
    collaboration_quality REAL,
    communication_efficiency REAL,
    conflict_probability REAL,
    synergy_factor REAL,
    project_context TEXT,
    success_rate REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS team_performance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_composition TEXT NOT NULL,
    project_type TEXT,
    team_size INTEGER,
    performance_score REAL,
    delivery_time REAL,
    quality_metrics REAL,
    cost_efficiency REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compatibility_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_name TEXT UNIQUE NOT NULL,
    rule_type TEXT NOT NULL,
    condition_pattern TEXT,
    compatibility_modifier REAL,
    description TEXT,
    active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_compatibility_agents ON agent_compatibility(agent_type_1, agent_type_2);
CREATE INDEX IF NOT EXISTS idx_team_performance_size ON team_performance(team_size);

-- Insert sample compatibility data
INSERT OR IGNORE INTO agent_compatibility (agent_type_1, agent_type_2, compatibility_score, collaboration_quality, communication_efficiency, conflict_probability, synergy_factor, project_context, success_rate) VALUES
('frontend-developer', 'ui-designer', 0.9, 0.85, 0.9, 0.1, 0.8, 'web-development', 0.92),
('backend-developer', 'database-specialist', 0.85, 0.9, 0.85, 0.15, 0.75, 'api-development', 0.88),
('devops-engineer', 'security-specialist', 0.8, 0.8, 0.85, 0.2, 0.7, 'infrastructure', 0.85);
EOF
    
    log_event "SUCCESS" "Compatibility database initialized: $db_file"
}

# Initialize agent templates database
init_agent_templates_db() {
    local db_file="${DATABASES_DIR}/agent-templates.db"
    
    log_event "INFO" "Initializing agent templates database"
    
    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS template_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT NOT NULL,
    version TEXT NOT NULL,
    template_data TEXT NOT NULL,
    performance_metrics TEXT,
    creation_time REAL,
    success_rate REAL,
    resource_usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT 1,
    UNIQUE(template_name, version)
);

CREATE TABLE IF NOT EXISTS agent_instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instance_id TEXT UNIQUE NOT NULL,
    agent_type TEXT NOT NULL,
    template_version TEXT,
    project_name TEXT,
    creation_time REAL,
    status TEXT DEFAULT 'creating',
    workspace_path TEXT,
    session_name TEXT,
    pipe_path TEXT,
    performance_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS template_optimizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT NOT NULL,
    optimization_type TEXT NOT NULL,
    before_metrics TEXT,
    after_metrics TEXT,
    improvement_percentage REAL,
    optimization_description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_template_versions_name ON template_versions(template_name);
CREATE INDEX IF NOT EXISTS idx_agent_instances_type ON agent_instances(agent_type);
CREATE INDEX IF NOT EXISTS idx_instances_status ON agent_instances(status);
EOF
    
    log_event "SUCCESS" "Agent templates database initialized: $db_file"
}

# Initialize orchestration history database
init_orchestration_history_db() {
    local db_file="${DATABASES_DIR}/orchestration-history.db"
    
    log_event "INFO" "Initializing orchestration history database"
    
    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS orchestration_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    user_query TEXT NOT NULL,
    project_name TEXT,
    phase INTEGER DEFAULT 2,
    status TEXT DEFAULT 'running',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    total_duration REAL,
    success BOOLEAN
);

CREATE TABLE IF NOT EXISTS master_worker_executions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    worker_type TEXT NOT NULL,
    worker_id TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration REAL,
    status TEXT DEFAULT 'running',
    input_data TEXT,
    output_data TEXT,
    error_details TEXT,
    FOREIGN KEY (session_id) REFERENCES orchestration_sessions(session_id)
);

CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL,
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES orchestration_sessions(session_id)
);

CREATE INDEX IF NOT EXISTS idx_orchestration_sessions_status ON orchestration_sessions(status);
CREATE INDEX IF NOT EXISTS idx_worker_executions_session ON master_worker_executions(session_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_session ON performance_metrics(session_id);
EOF
    
    log_event "SUCCESS" "Orchestration history database initialized: $db_file"
}

# Verify database integrity
verify_databases() {
    log_event "INFO" "Verifying database integrity"
    
    local databases=(
        "task-complexity.db"
        "agent-scoring.db"
        "compatibility.db"
        "agent-templates.db"
        "orchestration-history.db"
    )
    
    local all_valid=true
    
    for db in "${databases[@]}"; do
        local db_file="${DATABASES_DIR}/${db}"
        
        if [[ -f "$db_file" ]]; then
            if sqlite3 "$db_file" "PRAGMA integrity_check;" | grep -q "ok"; then
                log_event "SUCCESS" "Database integrity verified: $db"
            else
                log_event "ERROR" "Database integrity check failed: $db"
                all_valid=false
            fi
        else
            log_event "ERROR" "Database file not found: $db"
            all_valid=false
        fi
    done
    
    if $all_valid; then
        log_event "SUCCESS" "All databases passed integrity checks"
        return 0
    else
        log_event "ERROR" "Database integrity verification failed"
        return 1
    fi
}

# Create database backup
backup_databases() {
    local backup_dir="${CLAUDE_DIR}/backups/databases/$(date +%Y%m%d_%H%M%S)"
    
    log_event "INFO" "Creating database backup: $backup_dir"
    
    mkdir -p "$backup_dir"
    cp -r "${DATABASES_DIR}"/* "$backup_dir/" 2>/dev/null || true
    
    log_event "SUCCESS" "Database backup created: $backup_dir"
}

# Main execution
main() {
    case "${1:-init}" in
        "init")
            initialize_databases
            verify_databases
            ;;
        "verify")
            verify_databases
            ;;
        "backup")
            backup_databases
            ;;
        *)
            echo "Database Initialization Script - Phase 2"
            echo "Usage: $0 {init|verify|backup}"
            echo ""
            echo "Commands:"
            echo "  init    - Initialize all Phase 2 databases"
            echo "  verify  - Verify database integrity"
            echo "  backup  - Create database backup"
            ;;
    esac
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"