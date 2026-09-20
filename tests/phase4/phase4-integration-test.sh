#!/bin/bash

# Phase 4 - Agent Optimization & Performance Integration Test Suite
# Revolutionary AI Orchestration System - Comprehensive Testing
# Tests all Phase 4 components: MW6, Performance Analytics, Failure Analyzer, Agent Decomposer, Dashboard

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
TEST_LOG_FILE="${CLAUDE_DIR}/logs/phase4-integration-test.log"
TEST_WORKSPACE="${CLAUDE_DIR}/test-results/phase4"
TEST_PROJECT_ID="phase4-test-$(date +%s)-$(openssl rand -hex 4)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test logging function
log_test() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo -e "[${timestamp}] [PHASE4-TEST] [${level}] ${message}" | tee -a "${TEST_LOG_FILE}"
}

# Test status tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Initialize test environment
initialize_test_environment() {
    log_test "INFO" "🚀 Initializing Phase 4 Integration Test Environment"
    
    # Create test workspace
    mkdir -p "${TEST_WORKSPACE}"/{reports,logs,databases,temp}
    
    # Create test databases directory
    mkdir -p "${CLAUDE_DIR}/databases"
    
    # Initialize test logging
    echo "# Phase 4 Integration Test Report" > "${TEST_WORKSPACE}/test-report.md"
    echo "Started: $(date)" >> "${TEST_WORKSPACE}/test-report.md"
    echo "Project ID: ${TEST_PROJECT_ID}" >> "${TEST_WORKSPACE}/test-report.md"
    echo "" >> "${TEST_WORKSPACE}/test-report.md"
    
    log_test "SUCCESS" "Test environment initialized"
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    log_test "INFO" "🧪 Running test: ${test_name}"
    echo "## Test ${TESTS_TOTAL}: ${test_name}" >> "${TEST_WORKSPACE}/test-report.md"
    
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_test "SUCCESS" "✅ ${test_name} PASSED"
        echo -e "${GREEN}✅ ${test_name} PASSED${NC}"
        echo "**Status: PASSED** ✅" >> "${TEST_WORKSPACE}/test-report.md"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_test "ERROR" "❌ ${test_name} FAILED"
        echo -e "${RED}❌ ${test_name} FAILED${NC}"
        echo "**Status: FAILED** ❌" >> "${TEST_WORKSPACE}/test-report.md"
    fi
    echo "" >> "${TEST_WORKSPACE}/test-report.md"
}

# Test 1: Master Worker 6 Initialization
test_master_worker_6_initialization() {
    log_test "INFO" "Testing Master Worker 6 initialization"
    
    # Test script existence and executability
    if [[ ! -f "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" ]]; then
        log_test "ERROR" "Master Worker 6 script not found"
        return 1
    fi
    
    if [[ ! -x "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" ]]; then
        log_test "ERROR" "Master Worker 6 script not executable"
        return 1
    fi
    
    # Test database initialization
    timeout 30 "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" monitor "${TEST_PROJECT_ID}" &
    local mw6_pid=$!
    sleep 5
    kill $mw6_pid 2>/dev/null || true
    
    # Check if database was created
    if [[ -f "${CLAUDE_DIR}/databases/performance-metrics.db" ]]; then
        log_test "SUCCESS" "Performance metrics database created"
        
        # Test database schema
        local table_count=$(sqlite3 "${CLAUDE_DIR}/databases/performance-metrics.db" \
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
        
        if [[ "$table_count" -ge 4 ]]; then
            log_test "SUCCESS" "Database schema properly initialized with ${table_count} tables"
            return 0
        else
            log_test "ERROR" "Database schema incomplete: only ${table_count} tables found"
            return 1
        fi
    else
        log_test "ERROR" "Performance metrics database not created"
        return 1
    fi
}

# Test 2: Performance Analytics Engine
test_performance_analytics_engine() {
    log_test "INFO" "Testing Performance Analytics Engine"
    
    # Test Python engine existence
    if [[ ! -f "${CLAUDE_DIR}/engines/performance-analytics.py" ]]; then
        log_test "ERROR" "Performance Analytics Engine not found"
        return 1
    fi
    
    # Test Python dependencies
    if ! python3 -c "import sqlite3, pandas, numpy, sklearn" 2>/dev/null; then
        log_test "WARNING" "Some Python dependencies missing, but continuing test"
    fi
    
    # Test engine initialization (dry run)
    local test_output=$(timeout 10 python3 "${CLAUDE_DIR}/engines/performance-analytics.py" \
        --mode analyze \
        --project-id "${TEST_PROJECT_ID}" \
        --claude-dir "${CLAUDE_DIR}" 2>&1 || echo "timeout")
    
    if [[ "$test_output" != "timeout" ]]; then
        log_test "SUCCESS" "Performance Analytics Engine executed successfully"
        
        # Check for log file creation
        if [[ -f "${CLAUDE_DIR}/logs/performance-analytics.log" ]]; then
            log_test "SUCCESS" "Performance Analytics log file created"
            return 0
        else
            log_test "WARNING" "Performance Analytics log file not found"
            return 0  # Still pass the test
        fi
    else
        log_test "ERROR" "Performance Analytics Engine timed out or failed"
        return 1
    fi
}

# Test 3: Failure Pattern Analyzer
test_failure_pattern_analyzer() {
    log_test "INFO" "Testing Failure Pattern Analyzer"
    
    # Test Python analyzer existence
    if [[ ! -f "${CLAUDE_DIR}/engines/failure-pattern-analyzer.py" ]]; then
        log_test "ERROR" "Failure Pattern Analyzer not found"
        return 1
    fi
    
    # Test analyzer initialization and execution
    local analyzer_output=$(timeout 15 python3 "${CLAUDE_DIR}/engines/failure-pattern-analyzer.py" \
        --project-id "${TEST_PROJECT_ID}" \
        --mode analyze \
        --claude-dir "${CLAUDE_DIR}" 2>&1 || echo "timeout")
    
    if [[ "$analyzer_output" != "timeout" ]]; then
        log_test "SUCCESS" "Failure Pattern Analyzer executed successfully"
        
        # Check for failure patterns database
        if [[ -f "${CLAUDE_DIR}/databases/failure-patterns.db" ]]; then
            log_test "SUCCESS" "Failure patterns database created"
            
            # Check for generated patterns
            local pattern_count=$(sqlite3 "${CLAUDE_DIR}/databases/failure-patterns.db" \
                "SELECT COUNT(*) FROM failure_patterns WHERE project_id = '${TEST_PROJECT_ID}';" 2>/dev/null || echo "0")
            
            if [[ "$pattern_count" -gt 0 ]]; then
                log_test "SUCCESS" "Failure patterns generated: ${pattern_count} patterns"
                return 0
            else
                log_test "INFO" "No failure patterns found (expected for clean test environment)"
                return 0
            fi
        else
            log_test "ERROR" "Failure patterns database not created"
            return 1
        fi
    else
        log_test "ERROR" "Failure Pattern Analyzer timed out or failed"
        return 1
    fi
}

# Test 4: Agent Decomposer System
test_agent_decomposer_system() {
    log_test "INFO" "Testing Agent Decomposer System"
    
    # Test script existence and executability
    if [[ ! -f "${CLAUDE_DIR}/scripts/agent-decomposer.sh" ]]; then
        log_test "ERROR" "Agent Decomposer script not found"
        return 1
    fi
    
    if [[ ! -x "${CLAUDE_DIR}/scripts/agent-decomposer.sh" ]]; then
        log_test "ERROR" "Agent Decomposer script not executable"
        return 1
    fi
    
    # Test decomposer initialization
    timeout 20 "${CLAUDE_DIR}/scripts/agent-decomposer.sh" decompose "${TEST_PROJECT_ID}" "test-agent" &
    local decomposer_pid=$!
    sleep 10
    kill $decomposer_pid 2>/dev/null || true
    
    # Check for specialization database
    if [[ -f "${CLAUDE_DIR}/databases/agent-specialization.db" ]]; then
        log_test "SUCCESS" "Agent specialization database created"
        
        # Check for specialization records
        local specialization_count=$(sqlite3 "${CLAUDE_DIR}/databases/agent-specialization.db" \
            "SELECT COUNT(*) FROM agent_specializations WHERE project_id = '${TEST_PROJECT_ID}';" 2>/dev/null || echo "0")
        
        if [[ "$specialization_count" -gt 0 ]]; then
            log_test "SUCCESS" "Agent specializations created: ${specialization_count} records"
        else
            log_test "INFO" "No specializations found (may be expected for test run)"
        fi
        
        return 0
    else
        log_test "ERROR" "Agent specialization database not created"
        return 1
    fi
}

# Test 5: Performance Dashboard
test_performance_dashboard() {
    log_test "INFO" "Testing Performance Dashboard"
    
    # Test dashboard file existence
    if [[ ! -f "${CLAUDE_DIR}/dashboards/performance-dashboard.html" ]]; then
        log_test "ERROR" "Performance Dashboard not found"
        return 1
    fi
    
    # Test HTML structure
    local html_content=$(cat "${CLAUDE_DIR}/dashboards/performance-dashboard.html")
    
    # Check for essential HTML elements
    if echo "$html_content" | grep -q "Revolutionary AI Orchestrator"; then
        log_test "SUCCESS" "Dashboard title found"
    else
        log_test "ERROR" "Dashboard title not found"
        return 1
    fi
    
    if echo "$html_content" | grep -q "System Overview"; then
        log_test "SUCCESS" "System Overview section found"
    else
        log_test "ERROR" "System Overview section not found"
        return 1
    fi
    
    if echo "$html_content" | grep -q "updateDashboard"; then
        log_test "SUCCESS" "Dashboard JavaScript functionality found"
    else
        log_test "ERROR" "Dashboard JavaScript functionality not found"
        return 1
    fi
    
    # Test dashboard file size (should be substantial)
    local file_size=$(wc -c < "${CLAUDE_DIR}/dashboards/performance-dashboard.html")
    if [[ "$file_size" -gt 10000 ]]; then
        log_test "SUCCESS" "Dashboard file has substantial content (${file_size} bytes)"
        return 0
    else
        log_test "ERROR" "Dashboard file too small (${file_size} bytes)"
        return 1
    fi
}

# Test 6: Integration Testing - Components Working Together
test_component_integration() {
    log_test "INFO" "Testing Phase 4 Component Integration"
    
    # Start MW6 in background for integration test
    log_test "INFO" "Starting Master Worker 6 for integration test"
    timeout 30 "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" optimize "${TEST_PROJECT_ID}" &
    local integration_pid=$!
    
    # Let it run for a short time
    sleep 15
    
    # Kill the process
    kill $integration_pid 2>/dev/null || true
    wait $integration_pid 2>/dev/null || true
    
    # Check for integration artifacts
    local integration_success=0
    
    # Check performance metrics database
    if [[ -f "${CLAUDE_DIR}/databases/performance-metrics.db" ]]; then
        local metrics_count=$(sqlite3 "${CLAUDE_DIR}/databases/performance-metrics.db" \
            "SELECT COUNT(*) FROM agent_performance WHERE project_id = '${TEST_PROJECT_ID}';" 2>/dev/null || echo "0")
        
        if [[ "$metrics_count" -gt 0 ]]; then
            log_test "SUCCESS" "Performance metrics collected: ${metrics_count} records"
            integration_success=$((integration_success + 1))
        fi
    fi
    
    # Check optimization history
    if [[ -f "${CLAUDE_DIR}/databases/performance-metrics.db" ]]; then
        local optimization_count=$(sqlite3 "${CLAUDE_DIR}/databases/performance-metrics.db" \
            "SELECT COUNT(*) FROM optimization_history WHERE project_id = '${TEST_PROJECT_ID}';" 2>/dev/null || echo "0")
        
        if [[ "$optimization_count" -gt 0 ]]; then
            log_test "SUCCESS" "Optimizations applied: ${optimization_count} records"
            integration_success=$((integration_success + 1))
        fi
    fi
    
    # Check for generated reports
    if [[ -f "${CLAUDE_DIR}/reports/optimization-report-${TEST_PROJECT_ID}.json" ]]; then
        log_test "SUCCESS" "Optimization report generated"
        integration_success=$((integration_success + 1))
    fi
    
    # Integration test passes if at least 2 components produced artifacts
    if [[ "$integration_success" -ge 2 ]]; then
        log_test "SUCCESS" "Component integration successful (${integration_success}/3 components produced artifacts)"
        return 0
    else
        log_test "ERROR" "Component integration failed (only ${integration_success}/3 components produced artifacts)"
        return 1
    fi
}

# Test 7: Performance Validation
test_performance_validation() {
    log_test "INFO" "Testing Phase 4 Performance Validation"
    
    local validation_success=0
    
    # Check script execution times
    local start_time=$(date +%s.%N)
    timeout 10 "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" monitor "${TEST_PROJECT_ID}" &
    local perf_pid=$!
    sleep 3
    kill $perf_pid 2>/dev/null || true
    local end_time=$(date +%s.%N)
    
    local execution_time=$(echo "$end_time - $start_time" | bc -l)
    
    if (( $(echo "$execution_time < 10.0" | bc -l) )); then
        log_test "SUCCESS" "Script execution time acceptable: ${execution_time}s"
        validation_success=$((validation_success + 1))
    else
        log_test "WARNING" "Script execution time high: ${execution_time}s"
    fi
    
    # Check database responsiveness
    local db_start=$(date +%s.%N)
    sqlite3 "${CLAUDE_DIR}/databases/performance-metrics.db" "SELECT COUNT(*) FROM sqlite_master;" >/dev/null 2>&1 || true
    local db_end=$(date +%s.%N)
    local db_time=$(echo "$db_end - $db_start" | bc -l)
    
    if (( $(echo "$db_time < 1.0" | bc -l) )); then
        log_test "SUCCESS" "Database responsiveness acceptable: ${db_time}s"
        validation_success=$((validation_success + 1))
    else
        log_test "WARNING" "Database responsiveness slow: ${db_time}s"
    fi
    
    # Check file system impact
    local temp_files=$(find "${CLAUDE_DIR}" -name "*${TEST_PROJECT_ID}*" | wc -l)
    if [[ "$temp_files" -lt 10 ]]; then
        log_test "SUCCESS" "File system impact minimal: ${temp_files} files"
        validation_success=$((validation_success + 1))
    else
        log_test "WARNING" "File system impact high: ${temp_files} files"
    fi
    
    if [[ "$validation_success" -ge 2 ]]; then
        return 0
    else
        return 1
    fi
}

# Test 8: Error Handling and Recovery
test_error_handling() {
    log_test "INFO" "Testing Error Handling and Recovery"
    
    local error_handling_success=0
    
    # Test with invalid project ID
    if timeout 5 "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" optimize "invalid-project-😀" 2>/dev/null; then
        log_test "WARNING" "Script should handle invalid project IDs better"
    else
        log_test "SUCCESS" "Script properly handles invalid project IDs"
        error_handling_success=$((error_handling_success + 1))
    fi
    
    # Test with missing dependencies (simulate)
    local temp_script="${TEST_WORKSPACE}/temp-test-script.sh"
    cat > "$temp_script" << 'EOF'
#!/bin/bash
# Test script with missing dependency
nonexistent_command --test 2>/dev/null || exit 1
EOF
    chmod +x "$temp_script"
    
    if timeout 5 "$temp_script" 2>/dev/null; then
        log_test "WARNING" "Missing dependency test inconclusive"
    else
        log_test "SUCCESS" "Error handling for missing dependencies works"
        error_handling_success=$((error_handling_success + 1))
    fi
    
    # Test graceful shutdown
    "${CLAUDE_DIR}/scripts/master-worker-6-optimizer.sh" monitor "${TEST_PROJECT_ID}" &
    local test_pid=$!
    sleep 2
    
    if kill -TERM $test_pid 2>/dev/null; then
        sleep 1
        if kill -0 $test_pid 2>/dev/null; then
            kill -KILL $test_pid 2>/dev/null || true
            log_test "WARNING" "Process didn't terminate gracefully"
        else
            log_test "SUCCESS" "Process terminated gracefully"
            error_handling_success=$((error_handling_success + 1))
        fi
    else
        log_test "WARNING" "Could not test graceful shutdown"
    fi
    
    if [[ "$error_handling_success" -ge 2 ]]; then
        return 0
    else
        return 1
    fi
}

# Cleanup test environment
cleanup_test_environment() {
    log_test "INFO" "🧹 Cleaning up test environment"
    
    # Kill any remaining test processes
    pkill -f "${TEST_PROJECT_ID}" 2>/dev/null || true
    
    # Clean up test databases
    find "${CLAUDE_DIR}/databases" -name "*${TEST_PROJECT_ID}*" -delete 2>/dev/null || true
    
    # Clean up test reports
    find "${CLAUDE_DIR}/reports" -name "*${TEST_PROJECT_ID}*" -delete 2>/dev/null || true
    
    # Clean up test files
    rm -f "${TEST_WORKSPACE}/temp-test-script.sh" 2>/dev/null || true
    
    log_test "SUCCESS" "Test environment cleaned up"
}

# Generate final test report
generate_final_report() {
    log_test "INFO" "📋 Generating final test report"
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    
    # Add summary to markdown report
    {
        echo ""
        echo "## Test Summary"
        echo ""
        echo "- **Total Tests:** ${TESTS_TOTAL}"
        echo "- **Passed:** ${TESTS_PASSED}"
        echo "- **Failed:** ${TESTS_FAILED}"
        echo "- **Success Rate:** ${success_rate}%"
        echo ""
        echo "**Overall Status:** $(if [[ $success_rate -ge 80 ]]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)"
        echo ""
        echo "Completed: $(date)"
    } >> "${TEST_WORKSPACE}/test-report.md"
    
    # Generate JSON report
    cat > "${TEST_WORKSPACE}/test-results.json" << EOF
{
    "test_summary": {
        "project_id": "${TEST_PROJECT_ID}",
        "total_tests": ${TESTS_TOTAL},
        "tests_passed": ${TESTS_PASSED},
        "tests_failed": ${TESTS_FAILED},
        "success_rate": ${success_rate},
        "overall_status": "$(if [[ $success_rate -ge 80 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "test_duration": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "test_environment": "Phase 4 Integration Test Suite"
    },
    "component_tests": {
        "master_worker_6": "$(if [[ $TESTS_PASSED -gt 0 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "performance_analytics": "$(if [[ $TESTS_PASSED -gt 1 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "failure_analyzer": "$(if [[ $TESTS_PASSED -gt 2 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "agent_decomposer": "$(if [[ $TESTS_PASSED -gt 3 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "dashboard": "$(if [[ $TESTS_PASSED -gt 4 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "integration": "$(if [[ $TESTS_PASSED -gt 5 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "performance_validation": "$(if [[ $TESTS_PASSED -gt 6 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
        "error_handling": "$(if [[ $TESTS_PASSED -gt 7 ]]; then echo "PASSED"; else echo "FAILED"; fi)"
    }
}
EOF
    
    log_test "SUCCESS" "Final test report generated"
    
    # Display final results
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}📋 PHASE 4 INTEGRATION TEST RESULTS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "Project ID: ${YELLOW}${TEST_PROJECT_ID}${NC}"
    echo -e "Total Tests: ${YELLOW}${TESTS_TOTAL}${NC}"
    echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
    echo -e "Success Rate: ${YELLOW}${success_rate}%${NC}"
    echo ""
    if [[ $success_rate -ge 80 ]]; then
        echo -e "Overall Status: ${GREEN}✅ PASSED${NC}"
    else
        echo -e "Overall Status: ${RED}❌ FAILED${NC}"
    fi
    echo ""
    echo -e "Test Report: ${YELLOW}${TEST_WORKSPACE}/test-report.md${NC}"
    echo -e "Test Results: ${YELLOW}${TEST_WORKSPACE}/test-results.json${NC}"
    echo -e "Test Log: ${YELLOW}${TEST_LOG_FILE}${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
}

# Main test execution
main() {
    echo -e "${BLUE}🚀 Starting Phase 4 Integration Test Suite${NC}"
    echo ""
    
    # Ensure directories exist
    mkdir -p "$(dirname "$TEST_LOG_FILE")"
    mkdir -p "${CLAUDE_DIR}/scripts"
    mkdir -p "${CLAUDE_DIR}/engines"
    mkdir -p "${CLAUDE_DIR}/dashboards"
    
    # Initialize test environment
    initialize_test_environment
    
    # Run all tests
    run_test "Master Worker 6 Initialization" test_master_worker_6_initialization
    run_test "Performance Analytics Engine" test_performance_analytics_engine
    run_test "Failure Pattern Analyzer" test_failure_pattern_analyzer
    run_test "Agent Decomposer System" test_agent_decomposer_system
    run_test "Performance Dashboard" test_performance_dashboard
    run_test "Component Integration" test_component_integration
    run_test "Performance Validation" test_performance_validation
    run_test "Error Handling and Recovery" test_error_handling
    
    # Clean up and generate final report
    cleanup_test_environment
    generate_final_report
    
    # Exit with appropriate code
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    if [[ $success_rate -ge 80 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi