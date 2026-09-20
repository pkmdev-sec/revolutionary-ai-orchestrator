#!/usr/bin/env python3

"""
Performance Analytics Engine
Revolutionary AI Orchestration System - Phase 4
ML-based real-time agent performance monitoring and analysis
"""

import sqlite3
import argparse
import time
import json
import psutil
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
import logging
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import pandas as pd

class PerformanceAnalytics:
    def __init__(self, claude_dir, project_id):
        self.claude_dir = Path(claude_dir)
        self.project_id = project_id
        self.database_path = self.claude_dir / "databases" / "performance-metrics.db"
        self.log_path = self.claude_dir / "logs" / "performance-analytics.log"
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='[%(asctime)s] [PERFORMANCE-ANALYTICS] [%(levelname)s] %(message)s',
            handlers=[
                logging.FileHandler(self.log_path),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Initialize ML models
        self.performance_scaler = StandardScaler()
        self.performance_clusterer = KMeans(n_clusters=3, random_state=42)
        
        # Performance thresholds
        self.thresholds = {
            'memory_warning': 500 * 1024 * 1024,  # 500MB
            'memory_critical': 1024 * 1024 * 1024,  # 1GB
            'cpu_warning': 70.0,  # 70%
            'cpu_critical': 90.0,  # 90%
            'response_time_warning': 5.0,  # 5 seconds
            'response_time_critical': 10.0  # 10 seconds
        }
        
        self.logger.info("Performance Analytics Engine initialized")

    def start_real_time_monitoring(self):
        """Start continuous real-time monitoring of all agent sessions"""
        self.logger.info("Starting real-time performance monitoring")
        
        monitoring_session_id = self.create_monitoring_session()
        metrics_collected = 0
        
        try:
            while True:
                # Monitor all active tmux sessions
                active_sessions = self.get_active_agent_sessions()
                
                for session in active_sessions:
                    metrics = self.collect_session_metrics(session)
                    if metrics:
                        self.store_performance_metrics(metrics)
                        self.analyze_real_time_performance(metrics)
                        metrics_collected += 1
                
                # Update monitoring session
                self.update_monitoring_session(monitoring_session_id, metrics_collected)
                
                # ML-based performance analysis every 10 cycles
                if metrics_collected % 10 == 0:
                    self.perform_ml_analysis()
                
                time.sleep(2)  # 2-second monitoring interval
                
        except KeyboardInterrupt:
            self.logger.info("Real-time monitoring stopped")
            self.close_monitoring_session(monitoring_session_id, metrics_collected)

    def get_active_agent_sessions(self):
        """Get all active Claude agent tmux sessions"""
        try:
            result = subprocess.run(['tmux', 'list-sessions'], 
                                  capture_output=True, text=True, check=False)
            
            if result.returncode == 0:
                sessions = []
                for line in result.stdout.strip().split('\n'):
                    if line and ('claude-agent' in line or 'claude-mcp' in line or 'claude-master' in line):
                        session_name = line.split(':')[0]
                        sessions.append(session_name)
                return sessions
            return []
        except Exception as e:
            self.logger.error(f"Error getting active sessions: {e}")
            return []

    def collect_session_metrics(self, session_name):
        """Collect comprehensive metrics for a tmux session"""
        try:
            # Get session pane information
            result = subprocess.run(['tmux', 'list-panes', '-t', session_name, '-F', '#{pane_pid}'],
                                  capture_output=True, text=True, check=False)
            
            if result.returncode != 0:
                return None
            
            pane_pids = [pid.strip() for pid in result.stdout.strip().split('\n') if pid.strip()]
            
            if not pane_pids:
                return None
            
            # Collect process metrics
            total_memory = 0
            total_cpu = 0
            process_count = 0
            
            for pid_str in pane_pids:
                try:
                    pid = int(pid_str)
                    if psutil.pid_exists(pid):
                        process = psutil.Process(pid)
                        
                        # Get memory and CPU usage
                        memory_info = process.memory_info()
                        cpu_percent = process.cpu_percent(interval=0.1)
                        
                        total_memory += memory_info.rss
                        total_cpu += cpu_percent
                        process_count += 1
                        
                except (ValueError, psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            # Calculate averages
            avg_cpu = total_cpu / max(process_count, 1)
            
            # Get session window count
            window_result = subprocess.run(['tmux', 'list-windows', '-t', session_name],
                                         capture_output=True, text=True, check=False)
            window_count = len(window_result.stdout.strip().split('\n')) if window_result.returncode == 0 else 1
            
            # Simulate response time (in real implementation, this would be actual measurement)
            response_time = np.random.normal(2.0, 0.5)  # Simulated response time
            response_time = max(0.1, response_time)
            
            metrics = {
                'session_name': session_name,
                'timestamp': datetime.utcnow().isoformat(),
                'memory_usage': total_memory,
                'cpu_usage': avg_cpu,
                'process_count': process_count,
                'window_count': window_count,
                'response_time': response_time,
                'performance_score': self.calculate_performance_score(total_memory, avg_cpu, response_time)
            }
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Error collecting metrics for session {session_name}: {e}")
            return None

    def calculate_performance_score(self, memory_usage, cpu_usage, response_time):
        """Calculate overall performance score (0-10 scale)"""
        # Memory score (lower usage = higher score)
        memory_score = max(0, 10 - (memory_usage / (100 * 1024 * 1024)))  # Score decreases as memory increases
        
        # CPU score (lower usage = higher score)
        cpu_score = max(0, 10 - (cpu_usage / 10))
        
        # Response time score (lower time = higher score)
        response_score = max(0, 10 - response_time)
        
        # Weighted average
        overall_score = (memory_score * 0.4 + cpu_score * 0.4 + response_score * 0.2)
        return min(10, max(0, overall_score))

    def store_performance_metrics(self, metrics):
        """Store metrics in SQLite database"""
        try:
            conn = sqlite3.connect(self.database_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO agent_performance 
                (project_id, agent_id, session_id, metric_type, metric_value, timestamp,
                 resource_usage, success_rate, execution_time, memory_usage, cpu_usage)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                self.project_id,
                metrics['session_name'],
                metrics['session_name'],
                'real_time_monitoring',
                metrics['performance_score'],
                metrics['timestamp'],
                json.dumps({
                    'process_count': metrics['process_count'],
                    'window_count': metrics['window_count']
                }),
                metrics['performance_score'] / 10,  # Convert to 0-1 scale
                metrics['response_time'],
                metrics['memory_usage'],
                metrics['cpu_usage']
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error storing metrics: {e}")

    def analyze_real_time_performance(self, metrics):
        """Analyze performance metrics in real-time and trigger alerts"""
        session_name = metrics['session_name']
        memory_usage = metrics['memory_usage']
        cpu_usage = metrics['cpu_usage']
        response_time = metrics['response_time']
        performance_score = metrics['performance_score']
        
        # Check thresholds and log alerts
        alerts = []
        
        if memory_usage > self.thresholds['memory_critical']:
            alerts.append(f"CRITICAL: Memory usage {memory_usage / (1024*1024):.1f}MB")
        elif memory_usage > self.thresholds['memory_warning']:
            alerts.append(f"WARNING: Memory usage {memory_usage / (1024*1024):.1f}MB")
        
        if cpu_usage > self.thresholds['cpu_critical']:
            alerts.append(f"CRITICAL: CPU usage {cpu_usage:.1f}%")
        elif cpu_usage > self.thresholds['cpu_warning']:
            alerts.append(f"WARNING: CPU usage {cpu_usage:.1f}%")
        
        if response_time > self.thresholds['response_time_critical']:
            alerts.append(f"CRITICAL: Response time {response_time:.2f}s")
        elif response_time > self.thresholds['response_time_warning']:
            alerts.append(f"WARNING: Response time {response_time:.2f}s")
        
        if performance_score < 4.0:
            alerts.append(f"CRITICAL: Performance score {performance_score:.1f}/10")
        elif performance_score < 6.0:
            alerts.append(f"WARNING: Performance score {performance_score:.1f}/10")
        
        # Log alerts
        for alert in alerts:
            self.logger.warning(f"[{session_name}] {alert}")
        
        # Log normal status periodically
        if not alerts:
            self.logger.info(f"[{session_name}] Performance: {performance_score:.1f}/10, "
                           f"Memory: {memory_usage/(1024*1024):.1f}MB, "
                           f"CPU: {cpu_usage:.1f}%, "
                           f"Response: {response_time:.2f}s")

    def perform_ml_analysis(self):
        """Perform ML-based performance pattern analysis"""
        try:
            conn = sqlite3.connect(self.database_path)
            
            # Get recent performance data
            query = '''
                SELECT memory_usage, cpu_usage, execution_time, metric_value
                FROM agent_performance 
                WHERE project_id = ? AND timestamp > datetime('now', '-30 minutes')
                AND memory_usage > 0 AND cpu_usage > 0
            '''
            
            df = pd.read_sql_query(query, conn, params=(self.project_id,))
            conn.close()
            
            if len(df) < 10:  # Need minimum data for ML analysis
                return
            
            # Prepare features for clustering
            features = df[['memory_usage', 'cpu_usage', 'execution_time', 'metric_value']].values
            
            # Normalize features
            features_scaled = self.performance_scaler.fit_transform(features)
            
            # Perform clustering to identify performance patterns
            clusters = self.performance_clusterer.fit_predict(features_scaled)
            
            # Analyze clusters
            cluster_analysis = {}
            for i in range(self.performance_clusterer.n_clusters):
                cluster_mask = clusters == i
                cluster_data = df[cluster_mask]
                
                if len(cluster_data) > 0:
                    cluster_analysis[f'cluster_{i}'] = {
                        'count': len(cluster_data),
                        'avg_memory': cluster_data['memory_usage'].mean(),
                        'avg_cpu': cluster_data['cpu_usage'].mean(),
                        'avg_response_time': cluster_data['execution_time'].mean(),
                        'avg_performance': cluster_data['metric_value'].mean(),
                        'performance_category': self.categorize_cluster_performance(cluster_data)
                    }
            
            # Log ML analysis results
            self.logger.info(f"ML Analysis: Identified {len(cluster_analysis)} performance patterns")
            for cluster_id, analysis in cluster_analysis.items():
                self.logger.info(f"{cluster_id}: {analysis['count']} sessions, "
                               f"category: {analysis['performance_category']}, "
                               f"avg performance: {analysis['avg_performance']:.2f}")
            
        except Exception as e:
            self.logger.error(f"Error in ML analysis: {e}")

    def categorize_cluster_performance(self, cluster_data):
        """Categorize cluster performance based on metrics"""
        avg_performance = cluster_data['metric_value'].mean()
        avg_memory = cluster_data['memory_usage'].mean()
        avg_cpu = cluster_data['cpu_usage'].mean()
        
        if avg_performance >= 8.0:
            return "excellent"
        elif avg_performance >= 6.0:
            return "good"
        elif avg_memory > 500 * 1024 * 1024 or avg_cpu > 70:
            return "resource_intensive"
        else:
            return "needs_optimization"

    def create_monitoring_session(self):
        """Create a new monitoring session record"""
        try:
            conn = sqlite3.connect(self.database_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO monitoring_sessions 
                (project_id, session_name, start_time, total_metrics_collected, optimization_applied)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                self.project_id,
                f"real-time-monitoring-{datetime.utcnow().isoformat()}",
                datetime.utcnow().isoformat(),
                0,
                0
            ))
            
            session_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            return session_id
            
        except Exception as e:
            self.logger.error(f"Error creating monitoring session: {e}")
            return None

    def update_monitoring_session(self, session_id, metrics_collected):
        """Update monitoring session with current metrics count"""
        if session_id is None:
            return
            
        try:
            conn = sqlite3.connect(self.database_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE monitoring_sessions 
                SET total_metrics_collected = ?, monitored_agents = ?
                WHERE id = ?
            ''', (
                metrics_collected,
                json.dumps(self.get_active_agent_sessions()),
                session_id
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error updating monitoring session: {e}")

    def close_monitoring_session(self, session_id, final_metrics_count):
        """Close monitoring session"""
        if session_id is None:
            return
            
        try:
            conn = sqlite3.connect(self.database_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE monitoring_sessions 
                SET end_time = ?, total_metrics_collected = ?
                WHERE id = ?
            ''', (
                datetime.utcnow().isoformat(),
                final_metrics_count,
                session_id
            ))
            
            conn.commit()
            conn.close()
            
            self.logger.info(f"Monitoring session closed: {final_metrics_count} metrics collected")
            
        except Exception as e:
            self.logger.error(f"Error closing monitoring session: {e}")

def main():
    parser = argparse.ArgumentParser(description='Performance Analytics Engine')
    parser.add_argument('--mode', choices=['monitor', 'analyze'], default='monitor',
                       help='Operation mode')
    parser.add_argument('--project-id', required=True, help='Project ID')
    parser.add_argument('--claude-dir', default=f"{Path.home()}/.claude",
                       help='Claude directory path')
    
    args = parser.parse_args()
    
    analytics = PerformanceAnalytics(args.claude_dir, args.project_id)
    
    if args.mode == 'monitor':
        analytics.start_real_time_monitoring()
    elif args.mode == 'analyze':
        analytics.perform_ml_analysis()

if __name__ == "__main__":
    main()