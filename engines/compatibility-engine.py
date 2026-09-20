#!/usr/bin/env python3

"""
Compatibility Engine
Part of Master Worker 2 - Intelligent Agent Assignment Matrix
Revolutionary AI Orchestration System - Phase 2
"""

import json
import sys
import os
import time
import sqlite3
import networkx as nx
from datetime import datetime
from pathlib import Path
from collections import defaultdict, Counter
import itertools

class CompatibilityEngine:
    def __init__(self, workspace_dir):
        self.workspace_dir = Path(workspace_dir)
        self.db_path = Path(os.environ.get('CLAUDE_DIR', Path.home() / '.claude')) / 'databases' / 'compatibility.db'
        self.compatibility_graph = nx.Graph()
        self.init_database()
        self.load_compatibility_data()
        
    def init_database(self):
        """Initialize SQLite database for compatibility tracking"""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS compatibility_rules (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    rule_name TEXT UNIQUE NOT NULL,
                    rule_type TEXT NOT NULL,
                    condition_pattern TEXT,
                    compatibility_modifier REAL,
                    description TEXT,
                    active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Insert default compatibility data if empty
            cursor.execute('SELECT COUNT(*) FROM agent_compatibility')
            if cursor.fetchone()[0] == 0:
                self.insert_default_compatibility_data(cursor)
            
            # Insert default rules if empty
            cursor.execute('SELECT COUNT(*) FROM compatibility_rules')
            if cursor.fetchone()[0] == 0:
                self.insert_default_compatibility_rules(cursor)
            
            conn.commit()
    
    def insert_default_compatibility_data(self, cursor):
        """Insert default agent compatibility data"""
        compatibility_data = [
            # High compatibility pairs
            ('frontend-developer', 'ui-designer', 0.9, 0.85, 0.9, 0.1, 0.8, 'web-development', 0.92),
            ('backend-developer', 'database-specialist', 0.85, 0.9, 0.85, 0.15, 0.75, 'api-development', 0.88),
            ('devops-engineer', 'security-specialist', 0.8, 0.8, 0.85, 0.2, 0.7, 'infrastructure', 0.85),
            ('api-architect', 'backend-developer', 0.85, 0.9, 0.8, 0.1, 0.8, 'architecture', 0.9),
            ('performance-specialist', 'backend-developer', 0.75, 0.8, 0.75, 0.25, 0.65, 'optimization', 0.82),
            ('compliance-officer', 'security-specialist', 0.8, 0.85, 0.9, 0.15, 0.7, 'governance', 0.86),
            ('qa-specialist', 'frontend-developer', 0.7, 0.75, 0.8, 0.3, 0.6, 'testing', 0.78),
            ('qa-specialist', 'backend-developer', 0.75, 0.8, 0.8, 0.25, 0.65, 'testing', 0.8),
            
            # Medium compatibility pairs
            ('fullstack-developer', 'ui-designer', 0.65, 0.7, 0.75, 0.35, 0.55, 'web-development', 0.72),
            ('frontend-developer', 'backend-developer', 0.6, 0.65, 0.7, 0.4, 0.5, 'fullstack', 0.68),
            ('data-scientist', 'backend-developer', 0.55, 0.6, 0.65, 0.45, 0.45, 'data-driven', 0.62),
            ('devops-engineer', 'database-specialist', 0.6, 0.7, 0.65, 0.35, 0.5, 'infrastructure', 0.65),
            
            # Lower compatibility pairs (still workable)
            ('ui-designer', 'database-specialist', 0.4, 0.45, 0.5, 0.6, 0.3, 'mixed', 0.45),
            ('data-scientist', 'ui-designer', 0.35, 0.4, 0.45, 0.65, 0.25, 'mixed', 0.4),
            ('compliance-officer', 'ui-designer', 0.45, 0.5, 0.6, 0.55, 0.35, 'governance', 0.5),
            ('performance-specialist', 'ui-designer', 0.4, 0.45, 0.5, 0.6, 0.3, 'optimization', 0.42),
        ]
        
        cursor.executemany('''
            INSERT INTO agent_compatibility 
            (agent_type_1, agent_type_2, compatibility_score, collaboration_quality, 
             communication_efficiency, conflict_probability, synergy_factor, project_context, success_rate)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', compatibility_data)
    
    def insert_default_compatibility_rules(self, cursor):
        """Insert default compatibility rules"""
        rules = [
            ('same_domain_bonus', 'domain_match', 'frontend+frontend', 0.1, 'Agents from same domain work well together'),
            ('complementary_skills', 'skill_complement', 'design+development', 0.15, 'Design and development skills complement each other'),
            ('security_governance', 'domain_synergy', 'security+compliance', 0.2, 'Security and compliance have natural synergy'),
            ('technical_stack_alignment', 'tech_alignment', 'backend+database', 0.12, 'Backend and database work closely together'),
            ('size_penalty_large', 'team_size', 'size>6', -0.1, 'Large teams have coordination overhead'),
            ('specialization_conflict', 'over_specialization', 'specialist+specialist', -0.05, 'Multiple specialists may have overlap conflicts'),
        ]
        
        cursor.executemany('''
            INSERT INTO compatibility_rules 
            (rule_name, rule_type, condition_pattern, compatibility_modifier, description)
            VALUES (?, ?, ?, ?, ?)
        ''', rules)
    
    def load_compatibility_data(self):
        """Load compatibility data into graph structure"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT agent_type_1, agent_type_2, compatibility_score, 
                       collaboration_quality, synergy_factor
                FROM agent_compatibility
            ''')
            
            compatibility_records = cursor.fetchall()
        
        # Build compatibility graph
        for agent1, agent2, compat_score, collab_quality, synergy in compatibility_records:
            self.compatibility_graph.add_edge(agent1, agent2, 
                                            compatibility=compat_score,
                                            collaboration=collab_quality,
                                            synergy=synergy)
        
        print(f"Loaded {len(compatibility_records)} compatibility relationships")
    
    def calculate_team_compatibility(self, agent_list):
        """Calculate overall team compatibility score"""
        if len(agent_list) <= 1:
            return 1.0
        
        total_score = 0.0
        pair_count = 0
        
        # Calculate pairwise compatibility scores
        for agent1, agent2 in itertools.combinations(agent_list, 2):
            if self.compatibility_graph.has_edge(agent1, agent2):
                edge_data = self.compatibility_graph[agent1][agent2]
                pair_score = edge_data.get('compatibility', 0.5)
            else:
                # No direct compatibility data, use heuristic
                pair_score = self.estimate_compatibility(agent1, agent2)
            
            total_score += pair_score
            pair_count += 1
        
        if pair_count == 0:
            return 0.5  # Neutral score for single agent
        
        base_compatibility = total_score / pair_count
        
        # Apply team size penalty/bonus
        size_modifier = self.calculate_size_modifier(len(agent_list))
        
        # Apply diversity bonus
        diversity_bonus = self.calculate_diversity_bonus(agent_list)
        
        final_score = base_compatibility * size_modifier + diversity_bonus
        return min(1.0, max(0.0, final_score))
    
    def estimate_compatibility(self, agent1, agent2):
        """Estimate compatibility for agents without direct data"""
        # Load agent matrix for heuristic calculation
        matrix_file = self.workspace_dir / 'models' / 'agent-capability-matrix.json'
        if not matrix_file.exists():
            return 0.5  # Neutral default
        
        try:
            with open(matrix_file, 'r') as f:
                agent_matrix = json.load(f)
            
            agents = agent_matrix.get('agents', {})
            if agent1 not in agents or agent2 not in agents:
                return 0.5
            
            agent1_info = agents[agent1]
            agent2_info = agents[agent2]
            
            # Calculate technology stack overlap
            tech1 = set(agent1_info.get('technology_stack', []))
            tech2 = set(agent2_info.get('technology_stack', []))
            
            if tech1 and tech2:
                overlap = len(tech1.intersection(tech2))
                union = len(tech1.union(tech2))
                tech_similarity = overlap / union if union > 0 else 0
            else:
                tech_similarity = 0
            
            # Calculate capability overlap (some overlap is good, too much is redundant)
            cap1 = set(agent1_info.get('capabilities', []))
            cap2 = set(agent2_info.get('capabilities', []))
            
            if cap1 and cap2:
                overlap = len(cap1.intersection(cap2))
                optimal_overlap = 2  # Sweet spot for collaboration
                capability_score = 1.0 - abs(overlap - optimal_overlap) / max(len(cap1), len(cap2))
            else:
                capability_score = 0.5
            
            # Combine factors
            estimated_score = (tech_similarity * 0.4 + capability_score * 0.6)
            return max(0.3, min(0.8, estimated_score))  # Keep within reasonable bounds
            
        except Exception:
            return 0.5
    
    def calculate_size_modifier(self, team_size):
        """Calculate team size modifier for compatibility"""
        if team_size <= 2:
            return 1.0  # No penalty for small teams
        elif team_size <= 4:
            return 0.95  # Small penalty for medium teams
        elif team_size <= 6:
            return 0.9   # Medium penalty for larger teams
        else:
            return 0.85  # Higher penalty for very large teams
    
    def calculate_diversity_bonus(self, agent_list):
        """Calculate diversity bonus for varied skill sets"""
        # Count unique domains/specializations
        domains = set()
        
        matrix_file = self.workspace_dir / 'models' / 'agent-capability-matrix.json'
        if matrix_file.exists():
            try:
                with open(matrix_file, 'r') as f:
                    agent_matrix = json.load(f)
                
                for agent in agent_list:
                    if agent in agent_matrix.get('agents', {}):
                        tech_stack = agent_matrix['agents'][agent].get('technology_stack', [])
                        domains.update(tech_stack)
            except Exception:
                pass
        
        # Bonus for having diverse skill domains
        diversity_ratio = len(domains) / max(1, len(agent_list))
        return min(0.1, diversity_ratio * 0.05)  # Max 0.1 bonus
    
    def optimize_team_composition(self, available_agents, target_team_size=None):
        """Find optimal team composition from available agents"""
        if not available_agents:
            return []
        
        if target_team_size is None:
            target_team_size = min(4, len(available_agents))  # Default to 4 or fewer
        
        best_team = []
        best_score = 0.0
        
        # Try different team size combinations
        for team_size in range(2, min(target_team_size + 1, len(available_agents) + 1)):
            for team_combination in itertools.combinations(available_agents, team_size):
                team_list = list(team_combination)
                compatibility_score = self.calculate_team_compatibility(team_list)
                
                if compatibility_score > best_score:
                    best_score = compatibility_score
                    best_team = team_list
        
        return {
            'optimal_team': best_team,
            'compatibility_score': best_score,
            'team_size': len(best_team),
            'optimization_rationale': f'Selected from {len(available_agents)} available agents'
        }
    
    def analyze_team_dynamics(self, agent_assignments):
        """Analyze team dynamics and identify potential issues"""
        analysis = {
            'analyzed_at': datetime.utcnow().isoformat() + 'Z',
            'team_composition': {},
            'compatibility_matrix': {},
            'potential_conflicts': [],
            'collaboration_opportunities': [],
            'optimization_recommendations': []
        }
        
        # Extract unique agents from assignments
        assigned_agents = []
        for task_name, assignment in agent_assignments.items():
            agent_type = assignment.get('assigned_agent')
            if agent_type and agent_type not in assigned_agents:
                assigned_agents.append(agent_type)
        
        # Calculate pairwise compatibility matrix
        for agent1 in assigned_agents:
            analysis['compatibility_matrix'][agent1] = {}
            for agent2 in assigned_agents:
                if agent1 != agent2:
                    if self.compatibility_graph.has_edge(agent1, agent2):
                        edge_data = self.compatibility_graph[agent1][agent2]
                        compat_score = edge_data.get('compatibility', 0.5)
                    else:
                        compat_score = self.estimate_compatibility(agent1, agent2)
                    
                    analysis['compatibility_matrix'][agent1][agent2] = compat_score
                    
                    # Identify potential conflicts (low compatibility)
                    if compat_score < 0.4:
                        analysis['potential_conflicts'].append({
                            'agents': [agent1, agent2],
                            'compatibility_score': compat_score,
                            'risk_level': 'high' if compat_score < 0.3 else 'medium',
                            'mitigation': 'Consider adding intermediary agent or restructuring tasks'
                        })
                    
                    # Identify collaboration opportunities (high compatibility)
                    elif compat_score > 0.8:
                        analysis['collaboration_opportunities'].append({
                            'agents': [agent1, agent2],
                            'compatibility_score': compat_score,
                            'synergy_potential': 'high',
                            'recommendation': 'Assign related tasks to leverage synergy'
                        })
        
        # Overall team compatibility
        overall_compatibility = self.calculate_team_compatibility(assigned_agents)
        analysis['team_composition'] = {
            'agents': assigned_agents,
            'team_size': len(assigned_agents),
            'overall_compatibility': overall_compatibility,
            'compatibility_rating': 'excellent' if overall_compatibility >= 0.8 else 'good' if overall_compatibility >= 0.6 else 'acceptable' if overall_compatibility >= 0.4 else 'poor'
        }
        
        # Generate optimization recommendations
        if overall_compatibility < 0.6:
            analysis['optimization_recommendations'].append(
                'Team compatibility is below optimal. Consider restructuring assignments.'
            )
        
        if len(analysis['potential_conflicts']) > 2:
            analysis['optimization_recommendations'].append(
                'Multiple compatibility conflicts detected. Review agent pairing strategy.'
            )
        
        if len(assigned_agents) > 6:
            analysis['optimization_recommendations'].append(
                'Large team size may impact coordination. Consider breaking into sub-teams.'
            )
        
        return analysis
    
    def monitor_workspace(self):
        """Monitor workspace for compatibility analysis requests"""
        input_dir = self.workspace_dir / 'assignments'
        input_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Compatibility Engine monitoring: {input_dir}")
        print("Waiting for assignment files...")
        
        processed_files = set()
        
        while True:
            try:
                # Look for assignment files
                for assignment_file in input_dir.glob('*-assignments.json'):
                    if assignment_file not in processed_files:
                        print(f"Processing compatibility analysis for: {assignment_file}")
                        
                        # Load assignment data
                        with open(assignment_file, 'r') as f:
                            assignment_data = json.load(f)
                        
                        # Analyze team dynamics
                        if 'agent_assignments' in assignment_data:
                            analysis = self.analyze_team_dynamics(assignment_data['agent_assignments'])
                            
                            # Save compatibility analysis
                            output_file = self.workspace_dir / 'assignments' / f'compatibility-analysis-{assignment_file.stem}.json'
                            with open(output_file, 'w') as f:
                                json.dump(analysis, f, indent=2)
                            
                            print(f"Compatibility analysis saved: {output_file}")
                            print(f"Team compatibility: {analysis['team_composition']['compatibility_rating']}")
                            
                            processed_files.add(assignment_file)
                
                time.sleep(3)  # Check every 3 seconds
                
            except KeyboardInterrupt:
                print("Compatibility Engine shutting down...")
                break
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                time.sleep(5)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 compatibility-engine.py <workspace_dir>")
        sys.exit(1)
    
    workspace_dir = sys.argv[1]
    engine = CompatibilityEngine(workspace_dir)
    
    # Start monitoring workspace
    engine.monitor_workspace()

if __name__ == "__main__":
    main()