#!/usr/bin/env python3

"""
Complexity Scoring Engine
Part of Master Worker 1 - Recursive Task Decomposition
Revolutionary AI Orchestration System - Phase 2
"""

import json
import sys
import os
import time
import sqlite3
from datetime import datetime
from pathlib import Path

class ComplexityScorer:
    def __init__(self, workspace_dir):
        self.workspace_dir = Path(workspace_dir)
        self.db_path = Path(os.environ.get('CLAUDE_DIR', Path.home() / '.claude')) / 'databases' / 'task-complexity.db'
        self.init_database()
        
    def init_database(self):
        """Initialize SQLite database for complexity scoring"""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS complexity_patterns (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    pattern_type TEXT NOT NULL,
                    pattern_text TEXT NOT NULL,
                    weight REAL NOT NULL,
                    category TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Insert default complexity patterns if table is empty
            cursor.execute('SELECT COUNT(*) FROM complexity_patterns')
            if cursor.fetchone()[0] == 0:
                self.insert_default_patterns(cursor)
            
            conn.commit()
    
    def insert_default_patterns(self, cursor):
        """Insert default complexity scoring patterns"""
        patterns = [
            # High complexity patterns
            ('high', 'enterprise', 0.4, 'scale'),
            ('high', 'large-scale', 0.4, 'scale'),
            ('high', 'comprehensive', 0.3, 'scope'),
            ('high', 'complex', 0.3, 'complexity'),
            ('high', 'advanced', 0.3, 'difficulty'),
            ('high', 'microservices', 0.4, 'architecture'),
            ('high', 'distributed', 0.4, 'architecture'),
            ('high', 'real-time', 0.3, 'requirements'),
            ('high', 'machine learning', 0.4, 'technology'),
            ('high', 'artificial intelligence', 0.4, 'technology'),
            
            # Medium complexity patterns
            ('medium', 'moderate', 0.2, 'complexity'),
            ('medium', 'standard', 0.2, 'complexity'),
            ('medium', 'typical', 0.2, 'complexity'),
            ('medium', 'api', 0.2, 'technology'),
            ('medium', 'database', 0.2, 'technology'),
            ('medium', 'authentication', 0.25, 'feature'),
            ('medium', 'optimization', 0.25, 'operation'),
            ('medium', 'integration', 0.25, 'operation'),
            
            # Low complexity patterns
            ('low', 'simple', 0.1, 'complexity'),
            ('low', 'basic', 0.1, 'complexity'),
            ('low', 'quick', 0.1, 'time'),
            ('low', 'small', 0.1, 'scale'),
            ('low', 'minor', 0.1, 'scale'),
            ('low', 'update', 0.1, 'operation'),
            ('low', 'fix', 0.1, 'operation'),
            
            # Technology multipliers
            ('tech', 'react', 0.15, 'frontend'),
            ('tech', 'vue', 0.15, 'frontend'),
            ('tech', 'angular', 0.2, 'frontend'),
            ('tech', 'node.js', 0.15, 'backend'),
            ('tech', 'python', 0.1, 'backend'),
            ('tech', 'java', 0.2, 'backend'),
            ('tech', 'kubernetes', 0.3, 'infrastructure'),
            ('tech', 'docker', 0.2, 'infrastructure'),
            ('tech', 'aws', 0.25, 'cloud'),
            ('tech', 'azure', 0.25, 'cloud'),
            ('tech', 'postgresql', 0.15, 'database'),
            ('tech', 'mongodb', 0.2, 'database'),
            
            # Intent multipliers
            ('intent', 'create', 0.3, 'operation'),
            ('intent', 'build', 0.3, 'operation'),
            ('intent', 'implement', 0.25, 'operation'),
            ('intent', 'develop', 0.25, 'operation'),
            ('intent', 'optimize', 0.2, 'operation'),
            ('intent', 'improve', 0.2, 'operation'),
            ('intent', 'fix', 0.1, 'operation'),
            ('intent', 'debug', 0.15, 'operation'),
            ('intent', 'test', 0.15, 'operation'),
            ('intent', 'deploy', 0.2, 'operation'),
            ('intent', 'secure', 0.25, 'operation'),
            ('intent', 'analyze', 0.15, 'operation')
        ]
        
        cursor.executemany(
            'INSERT INTO complexity_patterns (pattern_type, pattern_text, weight, category) VALUES (?, ?, ?, ?)',
            patterns
        )
    
    def calculate_complexity(self, query):
        """Calculate complexity score for a given query"""
        query_lower = query.lower()
        word_count = len(query.split())
        
        # Base complexity from word count
        base_complexity = min(word_count / 50.0, 0.3)  # Max 0.3 from word count
        
        # Get patterns from database
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT pattern_type, pattern_text, weight FROM complexity_patterns')
            patterns = cursor.fetchall()
        
        # Calculate pattern-based complexity
        pattern_score = 0.0
        matched_patterns = []
        
        for pattern_type, pattern_text, weight in patterns:
            if pattern_text in query_lower:
                pattern_score += weight
                matched_patterns.append((pattern_type, pattern_text, weight))
        
        # Calculate technology diversity bonus
        tech_count = len([p for p in matched_patterns if p[0] == 'tech'])
        tech_bonus = min(tech_count * 0.05, 0.2)  # Max 0.2 bonus for technology diversity
        
        # Calculate intent complexity
        intent_count = len([p for p in matched_patterns if p[0] == 'intent'])
        intent_bonus = min(intent_count * 0.03, 0.15)  # Max 0.15 bonus for multiple intents
        
        # Final complexity calculation
        total_complexity = base_complexity + pattern_score + tech_bonus + intent_bonus
        final_complexity = min(total_complexity, 1.0)  # Cap at 1.0
        
        return {
            'complexity_score': final_complexity,
            'base_complexity': base_complexity,
            'pattern_score': pattern_score,
            'tech_bonus': tech_bonus,
            'intent_bonus': intent_bonus,
            'word_count': word_count,
            'matched_patterns': matched_patterns,
            'estimation': self.estimate_effort(final_complexity, word_count, tech_count)
        }
    
    def estimate_effort(self, complexity, word_count, tech_count):
        """Estimate development effort based on complexity"""
        # Base effort in hours
        base_effort = complexity * 40  # 0-40 hours base
        
        # Adjust for project size (word count proxy)
        size_multiplier = 1 + (word_count / 100)  # Each 100 words adds 100% effort
        
        # Adjust for technology complexity
        tech_multiplier = 1 + (tech_count * 0.2)  # Each technology adds 20% effort
        
        estimated_hours = base_effort * size_multiplier * tech_multiplier
        
        return {
            'estimated_hours': round(estimated_hours, 2),
            'estimated_days': round(estimated_hours / 8, 2),
            'estimated_weeks': round(estimated_hours / 40, 2),
            'size_multiplier': round(size_multiplier, 2),
            'tech_multiplier': round(tech_multiplier, 2)
        }
    
    def save_complexity_score(self, query, complexity_data):
        """Save complexity score to database"""
        query_hash = str(hash(query))
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO complexity_scores 
                (query, query_hash, complexity_score, intent_keywords, technology_keywords, 
                 word_count, estimated_effort, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                query,
                query_hash,
                complexity_data['complexity_score'],
                json.dumps([p[1] for p in complexity_data['matched_patterns'] if p[0] == 'intent']),
                json.dumps([p[1] for p in complexity_data['matched_patterns'] if p[0] == 'tech']),
                complexity_data['word_count'],
                complexity_data['estimation']['estimated_hours'],
                datetime.utcnow().isoformat()
            ))
            conn.commit()
    
    def analyze_query_file(self, input_file):
        """Analyze query from input file and save results"""
        try:
            with open(input_file, 'r') as f:
                data = json.load(f)
            
            query = data.get('original_query', '')
            if not query:
                return None
            
            print(f"Analyzing query: {query}")
            
            # Calculate complexity
            complexity_data = self.calculate_complexity(query)
            
            # Save to database
            self.save_complexity_score(query, complexity_data)
            
            # Update the analysis file with complexity data
            data.update(complexity_data)
            
            # Save updated analysis
            output_file = self.workspace_dir / 'input' / 'complexity-analysis.json'
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2)
            
            print(f"Complexity analysis complete: {complexity_data['complexity_score']:.3f}")
            print(f"Estimated effort: {complexity_data['estimation']['estimated_hours']} hours")
            
            return output_file
            
        except Exception as e:
            print(f"Error analyzing query: {e}")
            return None
    
    def monitor_workspace(self):
        """Monitor workspace for new analysis requests"""
        input_dir = self.workspace_dir / 'input'
        input_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Complexity scoring engine monitoring: {input_dir}")
        print("Waiting for query analysis files...")
        
        processed_files = set()
        
        while True:
            try:
                # Look for new query analysis files
                for analysis_file in input_dir.glob('query-analysis.json'):
                    if analysis_file not in processed_files:
                        print(f"Processing new analysis: {analysis_file}")
                        result = self.analyze_query_file(analysis_file)
                        if result:
                            processed_files.add(analysis_file)
                            print(f"Analysis saved to: {result}")
                
                time.sleep(2)  # Check every 2 seconds
                
            except KeyboardInterrupt:
                print("Complexity scoring engine shutting down...")
                break
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                time.sleep(5)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 complexity-scoring.py <workspace_dir>")
        sys.exit(1)
    
    workspace_dir = sys.argv[1]
    scorer = ComplexityScorer(workspace_dir)
    
    # Start monitoring workspace
    scorer.monitor_workspace()

if __name__ == "__main__":
    main()