---
description: "Real-time monitoring of Revolutionary AI Orchestration System with live tmux sessions and agent activity"
allowed-tools: ["bash"]
---

# 🔍 Quantum System Real-Time Monitor

Monitoring live system activity, tmux sessions, and agent spawning...

```bash
echo "🌌 Revolutionary AI Orchestration System - Live Monitor"
echo "========================================================"
echo ""

# Check current time
echo "⏰ Monitor Time: $(date '+%H:%M:%S %Y-%m-%d')"
echo ""

# Live tmux sessions monitoring
echo "🛡️ ACTIVE TMUX SESSIONS:"
tmux list-sessions 2>/dev/null | grep claude | while read session; do
    session_name=$(echo "$session" | cut -d: -f1)
    echo "  ✅ $session_name"
    
    # Count windows in session
    window_count=$(tmux list-windows -t "$session_name" 2>/dev/null | wc -l)
    echo "     📊 Windows: $window_count"
    
    # Check if session is busy (has recent activity)
    last_activity=$(tmux display-message -t "$session_name" -p '#{session_activity}' 2>/dev/null || echo "0")
    if [ "$last_activity" != "0" ]; then
        echo "     🔥 Status: ACTIVE"
    else
        echo "     💤 Status: Idle"
    fi
    echo ""
done

# Count total active sessions
total_sessions=$(tmux list-sessions 2>/dev/null | grep claude | wc -l)
echo "📈 Total Claude Sessions: $total_sessions"
echo ""

# Check quantum database activity
echo "💾 QUANTUM DATABASE ACTIVITY:"
if [ -f ~/.claude/databases/quantum-status.db ]; then
    echo "  ✅ Status Database: Active"
    session_count=$(sqlite3 ~/.claude/databases/quantum-status.db "SELECT COUNT(*) FROM quantum_sessions WHERE status = 'active'" 2>/dev/null || echo "0")
    echo "     📊 Active Sessions: $session_count"
else
    echo "  ❌ Status Database: Not found"
fi

if [ -f ~/.claude/databases/quantum-query-log.db ]; then
    echo "  ✅ Query Log Database: Active"
    recent_queries=$(sqlite3 ~/.claude/databases/quantum-query-log.db "SELECT COUNT(*) FROM query_processing_log WHERE datetime(timestamp) > datetime('now', '-1 hour')" 2>/dev/null || echo "0")
    echo "     📊 Recent Queries (1h): $recent_queries"
else
    echo "  ❌ Query Log Database: Not found"
fi
echo ""

# Check system resource usage
echo "💻 SYSTEM RESOURCE USAGE:"
echo "  🧠 Memory Usage:"
ps aux | grep -E "(python.*quantum|tmux)" | grep -v grep | awk '{print "     🔹 " $11 ": " $4 "% memory, " $3 "% CPU"}'

echo ""
echo "  📊 Disk Usage (Claude Directory):"
if [ -d ~/.claude ]; then
    disk_usage=$(du -sh ~/.claude 2>/dev/null | cut -f1)
    echo "     💾 ~/.claude: $disk_usage"
else
    echo "     ❌ ~/.claude: Not found"
fi
echo ""

# Check engine files status
echo "🚀 ENGINE FILES STATUS:"
engine_count=0
if [ -d ~/.claude/engines ]; then
    for engine in ~/.claude/engines/*.py; do
        if [ -f "$engine" ]; then
            engine_name=$(basename "$engine" .py)
            file_size=$(ls -lh "$engine" | awk '{print $5}')
            echo "  ✅ $engine_name: $file_size"
            engine_count=$((engine_count + 1))
        fi
    done
fi
echo "📈 Total Engines: $engine_count"
echo ""

# Check for recent process activity
echo "🔄 RECENT PROCESS ACTIVITY:"
recent_processes=$(ps aux | grep -E "python.*quantum" | grep -v grep | wc -l)
echo "  🤖 Active Quantum Processes: $recent_processes"

# Check network connections (if any engines are using network)
active_connections=$(netstat -an 2>/dev/null | grep LISTEN | wc -l)
echo "  🌐 Network Listeners: $active_connections"
echo ""

# Live monitoring summary
echo "🌟 LIVE SYSTEM SUMMARY:"
echo "  📊 Tmux Sessions: $total_sessions active"
echo "  🤖 Engine Files: $engine_count available"
echo "  💾 Databases: $(ls ~/.claude/databases/*.db 2>/dev/null | wc -l) active"
echo "  🔄 Active Processes: $recent_processes running"
echo ""

echo "🔄 Monitoring complete - Use 'watch -n 5 /quantum-monitor' for live updates"
```

---

**Live System Monitoring** - See real-time tmux sessions, agent activity, and system resource usage