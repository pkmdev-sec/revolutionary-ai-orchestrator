#!/bin/bash

# Compliance Auto-Injector
# Part of Master Worker 1 - Recursive Task Decomposition
# Revolutionary AI Orchestration System - Phase 2

set -euo pipefail

DECOMPOSER_ID="${1:-default}"
CLAUDE_DIR="${HOME}/.claude"
WORKSPACE_DIR="${CLAUDE_DIR}/agents/master-decomposer-${DECOMPOSER_ID}/workspace"
COMPLIANCE_TEMPLATES_DIR="${CLAUDE_DIR}/templates/compliance"
LOG_FILE="${CLAUDE_DIR}/logs/compliance-injector.log"

# Logging function
log_event() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "[${timestamp}] [COMPLIANCE-${DECOMPOSER_ID}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Initialize compliance templates
init_compliance_templates() {
    log_event "INFO" "Initializing compliance templates"
    
    mkdir -p "${COMPLIANCE_TEMPLATES_DIR}"
    
    # SOC2 Compliance Template
    cat > "${COMPLIANCE_TEMPLATES_DIR}/soc2-requirements.json" << 'EOF'
{
    "soc2_type_ii": {
        "description": "SOC 2 Type II Security Controls",
        "requirements": {
            "security": [
                "Access control and user management",
                "Network security and firewalls",
                "Data encryption at rest and in transit",
                "Vulnerability management and patches",
                "Incident response procedures",
                "Security monitoring and logging"
            ],
            "availability": [
                "System monitoring and alerting",
                "Backup and disaster recovery",
                "Change management procedures",
                "Capacity planning and scaling",
                "Performance monitoring"
            ],
            "processing_integrity": [
                "Data validation and error handling",
                "System processing controls",
                "Automated testing and quality assurance",
                "Transaction logging and audit trails"
            ],
            "confidentiality": [
                "Data classification and handling",
                "Access controls and permissions",
                "Data retention and disposal",
                "Employee confidentiality agreements"
            ],
            "privacy": [
                "Privacy policy and consent management",
                "Data subject rights and requests",
                "Third-party data sharing agreements",
                "Privacy impact assessments"
            ]
        },
        "implementation_tasks": [
            "Implement access control matrix",
            "Setup encryption for sensitive data",
            "Create incident response playbook",
            "Establish backup and recovery procedures",
            "Deploy monitoring and alerting systems",
            "Document security policies and procedures"
        ]
    }
}
EOF

    # GDPR Compliance Template
    cat > "${COMPLIANCE_TEMPLATES_DIR}/gdpr-requirements.json" << 'EOF'
{
    "gdpr": {
        "description": "General Data Protection Regulation Compliance",
        "requirements": {
            "lawful_basis": [
                "Document lawful basis for data processing",
                "Obtain and manage user consent",
                "Implement consent withdrawal mechanisms",
                "Maintain consent records and audit trails"
            ],
            "data_subject_rights": [
                "Right to access personal data",
                "Right to rectification of inaccurate data",
                "Right to erasure (right to be forgotten)",
                "Right to data portability",
                "Right to restrict processing",
                "Right to object to processing"
            ],
            "data_protection": [
                "Data minimization principles",
                "Purpose limitation and use restrictions",
                "Data accuracy and updates",
                "Storage limitation and retention",
                "Data security measures",
                "Accountability and governance"
            ],
            "privacy_by_design": [
                "Privacy impact assessments",
                "Data protection by design and default",
                "Privacy-preserving technologies",
                "Regular compliance monitoring"
            ]
        },
        "implementation_tasks": [
            "Implement consent management system",
            "Create data subject request handling",
            "Setup data retention and deletion",
            "Develop privacy policy and notices",
            "Implement data minimization controls",
            "Establish privacy governance framework"
        ]
    }
}
EOF

    # HIPAA Compliance Template
    cat > "${COMPLIANCE_TEMPLATES_DIR}/hipaa-requirements.json" << 'EOF'
{
    "hipaa": {
        "description": "Health Insurance Portability and Accountability Act",
        "requirements": {
            "administrative_safeguards": [
                "Security officer designation",
                "Workforce training and access management",
                "Information system activity review",
                "Contingency plan and disaster recovery",
                "Business associate agreements"
            ],
            "physical_safeguards": [
                "Facility access controls",
                "Workstation use restrictions",
                "Device and media controls",
                "Equipment disposal procedures"
            ],
            "technical_safeguards": [
                "Access control and unique user identification",
                "Automatic logoff and encryption",
                "Audit controls and logging",
                "Integrity controls for PHI",
                "Transmission security"
            ]
        },
        "implementation_tasks": [
            "Implement role-based access control",
            "Setup audit logging for PHI access",
            "Encrypt PHI at rest and in transit",
            "Create business associate agreements",
            "Develop workforce training program",
            "Establish incident response procedures"
        ]
    }
}
EOF

    # PCI-DSS Compliance Template
    cat > "${COMPLIANCE_TEMPLATES_DIR}/pci-dss-requirements.json" << 'EOF'
{
    "pci_dss": {
        "description": "Payment Card Industry Data Security Standard",
        "requirements": {
            "build_maintain_secure_network": [
                "Install and maintain firewall configuration",
                "Do not use vendor-supplied defaults for security",
                "Network segmentation and access controls"
            ],
            "protect_cardholder_data": [
                "Protect stored cardholder data",
                "Encrypt transmission of cardholder data",
                "Use strong cryptography and security protocols"
            ],
            "maintain_vulnerability_program": [
                "Protect systems against malware",
                "Develop and maintain secure systems",
                "Regular security testing and vulnerability scanning"
            ],
            "implement_access_controls": [
                "Restrict access to cardholder data by business need",
                "Assign unique ID to each person with computer access",
                "Restrict physical access to cardholder data"
            ],
            "monitor_test_networks": [
                "Track and monitor all access to network resources",
                "Regularly test security systems and processes"
            ],
            "maintain_information_security": [
                "Maintain policy that addresses information security",
                "Regular security awareness training"
            ]
        },
        "implementation_tasks": [
            "Implement card data encryption",
            "Setup network segmentation",
            "Deploy intrusion detection systems",
            "Create access control policies",
            "Establish vulnerability scanning",
            "Develop security policies and training"
        ]
    }
}
EOF

    log_event "SUCCESS" "Compliance templates initialized"
}

# Detect compliance requirements from query analysis
detect_compliance_requirements() {
    local analysis_file="$1"
    local compliance_file="${WORKSPACE_DIR}/compliance/detected-requirements.json"
    
    log_event "INFO" "Detecting compliance requirements from analysis"
    
    mkdir -p "${WORKSPACE_DIR}/compliance"
    
    python3 - << EOF
import json
import re
from pathlib import Path

analysis_file = "$analysis_file"
compliance_dir = Path("$COMPLIANCE_TEMPLATES_DIR")

# Load analysis data
with open(analysis_file, 'r') as f:
    analysis = json.load(f)

query = analysis.get('original_query', '').lower()
technologies = analysis.get('technologies', {})
intent_extraction = analysis.get('intent_extraction', {})

detected_requirements = {
    "detected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "query": analysis.get('original_query', ''),
    "compliance_frameworks": [],
    "specific_requirements": {},
    "implementation_tasks": [],
    "risk_assessment": {}
}

# Detection patterns
compliance_patterns = {
    "soc2": [
        r"enterprise", r"security", r"audit", r"compliance", r"governance",
        r"monitoring", r"access control", r"encryption", r"backup"
    ],
    "gdpr": [
        r"privacy", r"personal data", r"user data", r"consent", r"european",
        r"data protection", r"user rights", r"data subject"
    ],
    "hipaa": [
        r"healthcare", r"medical", r"patient", r"health", r"phi",
        r"protected health information", r"medical records"
    ],
    "pci_dss": [
        r"payment", r"credit card", r"transaction", r"financial", r"card data",
        r"payment processing", r"ecommerce"
    ]
}

# Detect compliance frameworks
for framework, patterns in compliance_patterns.items():
    for pattern in patterns:
        if re.search(pattern, query):
            if framework not in detected_requirements["compliance_frameworks"]:
                detected_requirements["compliance_frameworks"].append(framework)
            break

# Technology-based compliance requirements
if "database" in technologies:
    if "soc2" not in detected_requirements["compliance_frameworks"]:
        detected_requirements["compliance_frameworks"].append("soc2")

if "security" in technologies or "authentication" in intent_extraction:
    if "soc2" not in detected_requirements["compliance_frameworks"]:
        detected_requirements["compliance_frameworks"].append("soc2")

if "api" in technologies:
    if "soc2" not in detected_requirements["compliance_frameworks"]:
        detected_requirements["compliance_frameworks"].append("soc2")

# Load specific requirements for detected frameworks
for framework in detected_requirements["compliance_frameworks"]:
    template_file = compliance_dir / f"{framework.replace('_', '-')}-requirements.json"
    if template_file.exists():
        with open(template_file, 'r') as f:
            template_data = json.load(f)
        
        framework_key = list(template_data.keys())[0]
        detected_requirements["specific_requirements"][framework] = template_data[framework_key]
        detected_requirements["implementation_tasks"].extend(
            template_data[framework_key].get("implementation_tasks", [])
        )

# Risk assessment based on detected requirements
risk_level = "low"
if len(detected_requirements["compliance_frameworks"]) >= 3:
    risk_level = "high"
elif len(detected_requirements["compliance_frameworks"]) >= 2:
    risk_level = "medium"

detected_requirements["risk_assessment"] = {
    "overall_risk": risk_level,
    "compliance_complexity": len(detected_requirements["compliance_frameworks"]),
    "implementation_effort": len(detected_requirements["implementation_tasks"]),
    "frameworks_count": len(detected_requirements["compliance_frameworks"])
}

# Save detected requirements
with open("$compliance_file", 'w') as f:
    json.dump(detected_requirements, f, indent=2)

print(f"Detected {len(detected_requirements['compliance_frameworks'])} compliance frameworks")
print(f"Frameworks: {', '.join(detected_requirements['compliance_frameworks'])}")
print(f"Risk level: {risk_level}")
print(f"Implementation tasks: {len(detected_requirements['implementation_tasks'])}")
EOF
    
    log_event "SUCCESS" "Compliance requirements detected: $compliance_file"
    echo "$compliance_file"
}

# Inject compliance requirements into decomposition
inject_compliance_requirements() {
    local decomposition_file="$1"
    local compliance_file="$2"
    local enhanced_file="${WORKSPACE_DIR}/output/enhanced-decomposition.json"
    
    log_event "INFO" "Injecting compliance requirements into decomposition"
    
    python3 - << EOF
import json

# Load decomposition and compliance data
with open("$decomposition_file", 'r') as f:
    decomposition = json.load(f)

with open("$compliance_file", 'r') as f:
    compliance = json.load(f)

# Enhance decomposition with compliance
enhanced_decomposition = decomposition.copy()
enhanced_decomposition["compliance_enhanced"] = True
enhanced_decomposition["compliance_frameworks"] = compliance.get("compliance_frameworks", [])
enhanced_decomposition["compliance_risk"] = compliance.get("risk_assessment", {})

# Add compliance tasks to subtasks
compliance_tasks = []
for task in compliance.get("implementation_tasks", []):
    compliance_tasks.append({
        "name": task.lower().replace(" ", "_"),
        "description": task,
        "complexity": 0.4,  # Compliance tasks are moderately complex
        "type": "compliance",
        "framework": "multi"
    })

# Merge with existing subtasks
if "subtasks" not in enhanced_decomposition:
    enhanced_decomposition["subtasks"] = []

enhanced_decomposition["subtasks"].extend(compliance_tasks)

# Add compliance-specific agents
compliance_agents = ["compliance-officer", "security-specialist", "audit-specialist"]
if "agents_required" not in enhanced_decomposition:
    enhanced_decomposition["agents_required"] = []

enhanced_decomposition["agents_required"].extend(compliance_agents)

# Update effort estimation
compliance_effort = len(compliance_tasks) * 0.4
original_effort = enhanced_decomposition.get("estimated_effort", 0)
enhanced_decomposition["estimated_effort"] = original_effort + compliance_effort

# Add compliance validation requirements
enhanced_decomposition["compliance_validation"] = {
    "required_audits": len(compliance.get("compliance_frameworks", [])),
    "validation_tasks": [
        "Security penetration testing",
        "Compliance gap analysis",
        "Audit trail verification",
        "Policy and procedure review",
        "Training and awareness validation"
    ],
    "certification_requirements": compliance.get("compliance_frameworks", [])
}

# Save enhanced decomposition
with open("$enhanced_file", 'w') as f:
    json.dump(enhanced_decomposition, f, indent=2)

print(f"Enhanced decomposition with {len(compliance_tasks)} compliance tasks")
print(f"Total effort increased by {compliance_effort:.2f} units")
EOF
    
    log_event "SUCCESS" "Compliance requirements injected: $enhanced_file"
    echo "$enhanced_file"
}

# Monitor for compliance injection requests
monitor_compliance_requests() {
    log_event "INFO" "Starting compliance auto-injector monitoring"
    
    local input_dir="${WORKSPACE_DIR}/input"
    local output_dir="${WORKSPACE_DIR}/output"
    local compliance_dir="${WORKSPACE_DIR}/compliance"
    
    mkdir -p "$input_dir" "$output_dir" "$compliance_dir"
    
    echo "Compliance Auto-Injector monitoring workspace: ${WORKSPACE_DIR}"
    echo "Waiting for analysis files to inject compliance requirements..."
    
    local processed_files=()
    
    while true; do
        # Look for new query analysis files
        for analysis_file in "$input_dir"/query-analysis.json; do
            if [[ -f "$analysis_file" ]]; then
                local file_hash=$(sha256sum "$analysis_file" | cut -d' ' -f1)
                
                # Check if already processed
                if [[ ! " ${processed_files[@]} " =~ " ${file_hash} " ]]; then
                    echo "Processing new analysis file for compliance injection"
                    
                    # Detect compliance requirements
                    compliance_file=$(detect_compliance_requirements "$analysis_file")
                    
                    # Look for corresponding decomposition files
                    for decomp_file in "$output_dir"/decomposition-level-*.json; do
                        if [[ -f "$decomp_file" ]]; then
                            echo "Injecting compliance into: $decomp_file"
                            inject_compliance_requirements "$decomp_file" "$compliance_file"
                        fi
                    done
                    
                    processed_files+=("$file_hash")
                    echo "Compliance injection complete for analysis: $analysis_file"
                fi
            fi
        done
        
        sleep 3  # Check every 3 seconds
    done
}

# Main execution
main() {
    case "${1:-monitor}" in
        "init")
            init_compliance_templates
            ;;
        "detect")
            if [[ -z "${2:-}" ]]; then
                echo "Error: Analysis file required"
                exit 1
            fi
            detect_compliance_requirements "$2"
            ;;
        "inject")
            if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                echo "Error: Decomposition file and compliance file required"
                exit 1
            fi
            inject_compliance_requirements "$2" "$3"
            ;;
        "monitor")
            init_compliance_templates
            monitor_compliance_requests
            ;;
        *)
            echo "Compliance Auto-Injector"
            echo "Usage: $0 {init|detect|inject|monitor}"
            echo ""
            echo "Commands:"
            echo "  init                                   - Initialize compliance templates"
            echo "  detect <analysis_file>                 - Detect compliance requirements"
            echo "  inject <decomp_file> <compliance_file> - Inject compliance into decomposition"
            echo "  monitor                                - Monitor workspace for injection requests"
            ;;
    esac
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"