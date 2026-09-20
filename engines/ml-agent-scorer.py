#!/usr/bin/env python3

"""
ML Agent Scoring Engine
Part of Master Worker 2 - Intelligent Agent Assignment Matrix
Revolutionary AI Orchestration System - Phase 2
"""

import json
import sys
import os
import time
import sqlite3
import numpy as np
from datetime import datetime
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from collections import defaultdict

class MLAgentScorer:
    def __init__(self, workspace_dir):
        self.workspace_dir = Path(workspace_dir)
        self.db_path = Path(os.environ.get('CLAUDE_DIR', Path.home() / '.claude')) / 'databases' / 'agent-scoring.db'
        self.vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')
        self.init_database()
        self.load_historical_data()
        
    def init_database(self):
        """Initialize SQLite database for agent scoring"""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS task_agent_vectors (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    task_description TEXT NOT NULL,
                    task_vector TEXT,
                    agent_type TEXT NOT NULL,
                    compatibility_score REAL,
                    confidence_level REAL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS ml_model_performance (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    model_version TEXT,
                    accuracy REAL,
                    precision_score REAL,
                    recall_score REAL,
                    f1_score REAL,
                    training_samples INTEGER,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Insert sample performance data if table is empty
            cursor.execute('SELECT COUNT(*) FROM agent_performance')
            if cursor.fetchone()[0] == 0:
                self.insert_sample_performance_data(cursor)
            
            conn.commit()
    
    def insert_sample_performance_data(self, cursor):
        """Insert sample agent performance data for initial training"""
        sample_data = [
            # Frontend Developer Performance
            ('frontend-developer', 'ui-component', 'Create React dashboard component', 0.4, 4.5, 0.9, 0.95, 0.8),
            ('frontend-developer', 'responsive-design', 'Implement mobile-responsive layout', 0.3, 3.2, 0.85, 0.9, 0.9),
            ('frontend-developer', 'state-management', 'Setup Redux state management', 0.6, 6.8, 0.8, 0.85, 0.7),
            
            # Backend Developer Performance
            ('backend-developer', 'api-development', 'Build REST API endpoints', 0.5, 5.2, 0.9, 0.92, 0.85),
            ('backend-developer', 'database-integration', 'Integrate PostgreSQL database', 0.4, 4.0, 0.95, 0.98, 0.8),
            ('backend-developer', 'microservices', 'Design microservices architecture', 0.8, 12.5, 0.85, 0.8, 0.9),
            
            # Security Specialist Performance
            ('security-specialist', 'authentication', 'Implement OAuth authentication', 0.7, 8.0, 0.95, 0.9, 0.7),
            ('security-specialist', 'encryption', 'Setup data encryption at rest', 0.6, 6.5, 0.9, 0.95, 0.6),
            ('security-specialist', 'audit', 'Conduct security audit', 0.5, 7.2, 0.85, 0.88, 0.8),
            
            # DevOps Engineer Performance
            ('devops-engineer', 'containerization', 'Setup Docker containers', 0.4, 3.8, 0.9, 0.95, 0.85),
            ('devops-engineer', 'orchestration', 'Deploy Kubernetes cluster', 0.8, 10.2, 0.85, 0.85, 0.8),
            ('devops-engineer', 'monitoring', 'Setup monitoring and alerting', 0.5, 5.5, 0.88, 0.9, 0.9),
            
            # Database Specialist Performance
            ('database-specialist', 'schema-design', 'Design relational database schema', 0.6, 7.0, 0.92, 0.9, 0.75),
            ('database-specialist', 'optimization', 'Optimize database queries', 0.5, 4.8, 0.95, 0.95, 0.7),
            ('database-specialist', 'migration', 'Database migration planning', 0.7, 8.5, 0.88, 0.85, 0.8),
            
            # UI Designer Performance
            ('ui-designer', 'wireframing', 'Create application wireframes', 0.3, 4.2, 0.9, 0.92, 0.95),
            ('ui-designer', 'prototyping', 'Build interactive prototypes', 0.4, 5.5, 0.85, 0.88, 0.9),
            ('ui-designer', 'user-research', 'Conduct user research sessions', 0.2, 6.0, 0.8, 0.85, 0.95),
        ]
        
        cursor.executemany('''
            INSERT INTO agent_performance 
            (agent_type, task_type, task_description, complexity_score, completion_time, 
             quality_score, success_rate, collaboration_score)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', sample_data)
    
    def load_historical_data(self):
        """Load historical performance data for ML training"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT agent_type, task_description, complexity_score, 
                       completion_time, quality_score, success_rate, collaboration_score
                FROM agent_performance
                ORDER BY created_at DESC
            ''')
            
            self.historical_data = cursor.fetchall()
        
        print(f"Loaded {len(self.historical_data)} historical performance records")
    
    def calculate_agent_task_similarity(self, task_description, agent_capabilities):
        """Calculate semantic similarity between task and agent capabilities"""
        # Combine agent capabilities into a single text
        agent_text = ' '.join(agent_capabilities)
        
        # Create TF-IDF vectors
        texts = [task_description.lower(), agent_text.lower()]
        
        try:
            tfidf_matrix = self.vectorizer.fit_transform(texts)
            similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
            return max(0.0, min(1.0, similarity))  # Ensure 0-1 range
        except:
            # Fallback to keyword matching if TF-IDF fails
            task_words = set(task_description.lower().split())
            capability_words = set(agent_text.lower().split())
            
            if not task_words or not capability_words:
                return 0.0
            
            intersection = task_words.intersection(capability_words)
            return len(intersection) / len(task_words.union(capability_words))
    
    def predict_agent_performance(self, agent_type, task_description, task_complexity):
        """Predict agent performance using historical data and ML techniques"""
        # Filter historical data for this agent type
        agent_history = [record for record in self.historical_data if record[0] == agent_type]
        
        if not agent_history:
            # No history available, return baseline prediction
            return {
                'predicted_completion_time': task_complexity * 10,  # 10 hours per complexity unit
                'predicted_quality': 0.7,
                'predicted_success_rate': 0.8,
                'confidence': 0.3
            }
        
        # Calculate weighted averages based on task similarity
        total_weight = 0.0
        weighted_time = 0.0
        weighted_quality = 0.0
        weighted_success = 0.0
        
        for record in agent_history:
            _, hist_task_desc, hist_complexity, hist_time, hist_quality, hist_success, _ = record
            
            # Calculate similarity weight
            similarity = self.calculate_task_similarity(task_description, hist_task_desc)
            complexity_similarity = 1.0 - abs(task_complexity - hist_complexity)
            
            weight = (similarity * 0.7 + complexity_similarity * 0.3) ** 2  # Emphasize similar tasks
            
            if weight > 0.1:  # Only consider reasonably similar tasks
                total_weight += weight
                weighted_time += hist_time * weight
                weighted_quality += hist_quality * weight
                weighted_success += hist_success * weight
        
        if total_weight > 0:
            predicted_time = weighted_time / total_weight
            predicted_quality = weighted_quality / total_weight
            predicted_success = weighted_success / total_weight
            confidence = min(0.9, total_weight / len(agent_history))
        else:
            # Fallback to simple averages
            predicted_time = sum(record[4] for record in agent_history) / len(agent_history)
            predicted_quality = sum(record[5] for record in agent_history) / len(agent_history)
            predicted_success = sum(record[6] for record in agent_history) / len(agent_history)
            confidence = 0.4
        
        return {
            'predicted_completion_time': predicted_time,
            'predicted_quality': predicted_quality,
            'predicted_success_rate': predicted_success,
            'confidence': confidence
        }
    
    def calculate_task_similarity(self, task1, task2):
        """Calculate similarity between two task descriptions"""
        if not task1 or not task2:
            return 0.0
        
        # Simple keyword-based similarity
        words1 = set(task1.lower().split())
        words2 = set(task2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        return len(intersection) / len(union) if union else 0.0
    
    def score_agent_for_task(self, agent_type, agent_info, task_description, task_complexity):
        """Generate comprehensive ML-based score for agent-task pairing"""
        # Calculate semantic similarity
        similarity_score = self.calculate_agent_task_similarity(
            task_description, 
            agent_info.get('capabilities', [])
        )
        
        # Predict performance
        performance = self.predict_agent_performance(agent_type, task_description, task_complexity)
        
        # Check complexity range fit
        complexity_range = agent_info.get('complexity_range', [0.0, 1.0])
        complexity_fit = 1.0
        if task_complexity < complexity_range[0]:
            complexity_fit = 0.7  # Underutilized
        elif task_complexity > complexity_range[1]:
            complexity_fit = 0.5  # Overloaded
        
        # Calculate cost-effectiveness
        cost_factor = agent_info.get('cost_factor', 1.0)
        speed_multiplier = agent_info.get('speed_multiplier', 1.0)
        cost_effectiveness = (speed_multiplier / cost_factor) if cost_factor > 0 else 1.0
        
        # Combine all factors into final score
        base_score = (
            similarity_score * 0.3 +
            performance['predicted_quality'] * 0.25 +
            performance['predicted_success_rate'] * 0.25 +
            complexity_fit * 0.2
        )
        
        # Apply modifiers
        final_score = base_score * cost_effectiveness * agent_info.get('specialization_score', 1.0)
        
        return {
            'agent_type': agent_type,
            'final_score': min(1.0, final_score),
            'similarity_score': similarity_score,
            'predicted_performance': performance,
            'complexity_fit': complexity_fit,
            'cost_effectiveness': cost_effectiveness,
            'confidence': performance['confidence'],
            'recommendation': 'excellent' if final_score >= 0.8 else 'good' if final_score >= 0.6 else 'acceptable' if final_score >= 0.4 else 'poor'
        }
    
    def analyze_assignment_request(self, request_file):
        """Analyze assignment request and generate ML-based scores"""
        try:
            with open(request_file, 'r') as f:
                request_data = json.load(f)
            
            print(f"Analyzing assignment request: {request_file}")
            
            # Load agent capability matrix
            matrix_file = self.workspace_dir / 'models' / 'agent-capability-matrix.json'
            if not matrix_file.exists():
                print("Error: Agent capability matrix not found")
                return None
            
            with open(matrix_file, 'r') as f:
                agent_matrix = json.load(f)
            
            # Process task assignments
            ml_scores = {
                'analyzed_at': datetime.utcnow().isoformat() + 'Z',
                'ml_version': '2.0',
                'task_scores': {},
                'agent_rankings': {},
                'optimization_insights': []
            }
            
            for task_assignment in request_data.get('task_assignments', []):
                task_name = task_assignment['task_name']
                task_description = task_assignment['task_description']
                task_complexity = task_assignment['task_complexity']
                
                # Score all agents for this task
                agent_scores = {}
                for agent_type, agent_info in agent_matrix['agents'].items():
                    score_data = self.score_agent_for_task(
                        agent_type, agent_info, task_description, task_complexity
                    )
                    agent_scores[agent_type] = score_data
                
                # Rank agents by score
                ranked_agents = sorted(agent_scores.items(), key=lambda x: x[1]['final_score'], reverse=True)
                
                ml_scores['task_scores'][task_name] = {
                    'task_description': task_description,
                    'task_complexity': task_complexity,
                    'agent_scores': agent_scores,
                    'top_3_agents': [
                        {
                            'agent_type': agent_type,
                            'score': score_data['final_score'],
                            'confidence': score_data['confidence'],
                            'recommendation': score_data['recommendation']
                        }
                        for agent_type, score_data in ranked_agents[:3]
                    ]
                }
            
            # Generate global agent rankings
            agent_totals = defaultdict(list)
            for task_scores in ml_scores['task_scores'].values():
                for agent_type, score_data in task_scores['agent_scores'].items():
                    agent_totals[agent_type].append(score_data['final_score'])
            
            ml_scores['agent_rankings'] = {
                agent_type: {
                    'average_score': sum(scores) / len(scores),
                    'max_score': max(scores),
                    'min_score': min(scores),
                    'tasks_evaluated': len(scores),
                    'overall_ranking': 'top' if sum(scores) / len(scores) >= 0.7 else 'medium' if sum(scores) / len(scores) >= 0.5 else 'low'
                }
                for agent_type, scores in agent_totals.items()
            }
            
            # Generate optimization insights
            high_confidence_tasks = sum(1 for task_scores in ml_scores['task_scores'].values() 
                                     if task_scores['top_3_agents'][0]['confidence'] >= 0.8)
            total_tasks = len(ml_scores['task_scores'])
            
            if high_confidence_tasks / total_tasks < 0.8:
                ml_scores['optimization_insights'].append(
                    "Consider gathering more historical performance data for better ML predictions"
                )
            
            if len(agent_totals) < 3:
                ml_scores['optimization_insights'].append(
                    "Limited agent diversity may impact assignment quality"
                )
            
            # Save ML scores
            output_file = self.workspace_dir / 'assignments' / 'ml-agent-scores.json'
            output_file.parent.mkdir(parents=True, exist_ok=True)
            with open(output_file, 'w') as f:
                json.dump(ml_scores, f, indent=2)
            
            print(f"ML scoring complete: {len(ml_scores['task_scores'])} tasks analyzed")
            print(f"High confidence assignments: {high_confidence_tasks}/{total_tasks}")
            
            return output_file
            
        except Exception as e:
            print(f"Error analyzing assignment request: {e}")
            return None
    
    def monitor_workspace(self):
        """Monitor workspace for new assignment requests"""
        input_dir = self.workspace_dir / 'input'
        input_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"ML Agent Scorer monitoring: {input_dir}")
        print("Waiting for assignment request files...")
        
        processed_files = set()
        
        while True:
            try:
                # Look for assignment request files
                for request_file in input_dir.glob('*-compatibility.json'):
                    if request_file not in processed_files:
                        print(f"Processing ML scoring for: {request_file}")
                        result = self.analyze_assignment_request(request_file)
                        if result:
                            processed_files.add(request_file)
                            print(f"ML scores saved to: {result}")
                
                time.sleep(3)  # Check every 3 seconds
                
            except KeyboardInterrupt:
                print("ML Agent Scorer shutting down...")
                break
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                time.sleep(5)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 ml-agent-scorer.py <workspace_dir>")
        sys.exit(1)
    
    workspace_dir = sys.argv[1]
    scorer = MLAgentScorer(workspace_dir)
    
    # Start monitoring workspace
    scorer.monitor_workspace()

if __name__ == "__main__":
    main()