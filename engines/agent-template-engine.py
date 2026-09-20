#!/usr/bin/env python3

"""
Agent Template Engine
Part of Master Worker 3 - Dynamic Agent Creation Factory
Revolutionary AI Orchestration System - Phase 2
"""

import json
import sys
import os
import time
import sqlite3
import shutil
from datetime import datetime
from pathlib import Path
from string import Template

class AgentTemplateEngine:
    def __init__(self, workspace_dir):
        self.workspace_dir = Path(workspace_dir)
        self.db_path = Path(os.environ.get('CLAUDE_DIR', Path.home() / '.claude')) / 'databases' / 'agent-templates.db'
        self.templates_dir = self.workspace_dir / 'templates'
        self.instances_dir = self.workspace_dir / 'instances'
        self.init_database()
        
    def init_database(self):
        """Initialize SQLite database for template management"""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
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
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS template_optimizations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    template_name TEXT NOT NULL,
                    optimization_type TEXT NOT NULL,
                    before_metrics TEXT,
                    after_metrics TEXT,
                    improvement_percentage REAL,
                    optimization_description TEXT,
                    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            conn.commit()
    
    def generate_dynamic_template(self, agent_type, project_context, performance_requirements):
        """Generate optimized template based on project context and requirements"""
        print(f"Generating dynamic template for {agent_type}")
        
        # Load base template
        base_template_file = self.templates_dir / f"{agent_type}-template.json"
        if not base_template_file.exists():
            print(f"Base template not found for {agent_type}")
            return None
        
        with open(base_template_file, 'r') as f:
            base_template = json.load(f)
        
        # Apply context-specific optimizations
        optimized_template = self.apply_context_optimizations(
            base_template, project_context, performance_requirements
        )
        
        # Apply performance optimizations
        optimized_template = self.apply_performance_optimizations(
            optimized_template, performance_requirements
        )
        
        # Apply security optimizations
        optimized_template = self.apply_security_optimizations(
            optimized_template, project_context
        )
        
        return optimized_template
    
    def apply_context_optimizations(self, template, project_context, performance_req):
        """Apply optimizations based on project context"""
        optimized = template.copy()
        
        # Adjust resource limits based on project size
        project_size = project_context.get('project_size', 'medium')
        
        if project_size == 'large':
            # Increase resources for large projects
            optimized['resources']['memory_limit'] = self.increase_resource(
                optimized['resources']['memory_limit'], 1.5
            )
            optimized['resources']['disk_space'] = self.increase_resource(
                optimized['resources']['disk_space'], 2.0
            )
            optimized['performance']['cpu_limit'] = min(2.0, optimized['performance']['cpu_limit'] * 1.5)
        
        elif project_size == 'small':
            # Optimize for minimal resource usage
            optimized['resources']['memory_limit'] = self.increase_resource(
                optimized['resources']['memory_limit'], 0.7
            )
            optimized['performance']['cpu_limit'] = max(0.5, optimized['performance']['cpu_limit'] * 0.8)
        
        # Adjust for specific technologies
        technologies = project_context.get('technologies', [])
        
        if 'react' in technologies and template['agent_type'] == 'frontend-developer':
            # React-specific optimizations
            optimized['specialization']['primary_skills'].insert(0, 'react')
            optimized['context']['workspace_structure'].extend(['src/components/', 'src/hooks/'])
            
        if 'kubernetes' in technologies and template['agent_type'] == 'devops-engineer':
            # Kubernetes-specific optimizations
            optimized['resources']['memory_limit'] = self.increase_resource(
                optimized['resources']['memory_limit'], 1.3
            )
            optimized['specialization']['tools'].insert(0, 'kubectl')
        
        # Adjust timeout based on complexity
        complexity = project_context.get('complexity', 0.5)
        base_timeout = optimized['performance']['timeout']
        optimized['performance']['timeout'] = int(base_timeout * (1 + complexity))
        
        return optimized
    
    def apply_performance_optimizations(self, template, performance_req):
        """Apply performance-specific optimizations"""
        optimized = template.copy()
        
        # Speed vs quality tradeoff
        speed_priority = performance_req.get('speed_priority', 0.5)
        
        if speed_priority > 0.7:
            # Optimize for speed
            optimized['lifecycle']['startup_time_target'] = min(
                2.0, optimized['lifecycle']['startup_time_target'] * 0.8
            )
            optimized['performance']['auto_scaling'] = True
            optimized['performance']['load_balancing'] = True
            
        elif speed_priority < 0.3:
            # Optimize for quality and resource efficiency
            optimized['lifecycle']['health_check_interval'] = 15  # More frequent health checks
            optimized['performance']['memory_limit'] = self.increase_resource(
                optimized['performance']['memory_limit'], 0.8  # Reduce memory for efficiency
            )
        
        # Concurrency requirements
        concurrency = performance_req.get('concurrency', 1)
        if concurrency > 1:
            optimized['performance']['cpu_limit'] = min(4.0, concurrency)
            optimized['communication']['rate_limiting'] = False  # Remove rate limits for high concurrency
        
        return optimized
    
    def apply_security_optimizations(self, template, project_context):
        """Apply security-specific optimizations"""
        optimized = template.copy()
        
        security_level = project_context.get('security_level', 'standard')
        
        if security_level == 'high':
            # Enhanced security for sensitive projects
            optimized['security']['isolation_level'] = 'maximum'
            optimized['security']['audit_logging'] = True
            optimized['security']['encryption_strength'] = 'aes256'
            optimized['lifecycle']['idle_timeout'] = 600  # Shorter idle timeout
            optimized['lifecycle']['max_lifetime'] = 3600  # Shorter max lifetime
            
        elif security_level == 'enterprise':
            # Enterprise-grade security
            optimized['security']['isolation_level'] = 'maximum'
            optimized['security']['compliance_monitoring'] = True
            optimized['security']['data_classification'] = 'confidential'
            optimized['security']['access_logging'] = True
            optimized['lifecycle']['idle_timeout'] = 300
            
        # Compliance requirements
        compliance = project_context.get('compliance_requirements', [])
        if 'hipaa' in compliance:
            optimized['security']['encryption_at_rest'] = True
            optimized['security']['audit_trail'] = True
            
        if 'gdpr' in compliance:
            optimized['security']['data_minimization'] = True
            optimized['security']['consent_tracking'] = True
        
        return optimized
    
    def increase_resource(self, resource_string, multiplier):
        """Helper to increase resource limits"""
        if isinstance(resource_string, str):
            # Extract number and unit (e.g., "512MB" -> 512, "MB")
            import re
            match = re.match(r'(\d+)(\w+)', resource_string)
            if match:
                value, unit = match.groups()
                new_value = int(int(value) * multiplier)
                return f"{new_value}{unit}"
        return resource_string
    
    def optimize_template_for_workload(self, template, workload_analysis):
        """Optimize template based on workload analysis"""
        optimized = template.copy()
        
        # Analyze historical performance data
        avg_cpu_usage = workload_analysis.get('avg_cpu_usage', 0.5)
        avg_memory_usage = workload_analysis.get('avg_memory_usage', 0.5)
        peak_concurrent_tasks = workload_analysis.get('peak_concurrent_tasks', 1)
        
        # Adjust CPU limits
        if avg_cpu_usage > 0.8:
            optimized['performance']['cpu_limit'] = min(4.0, optimized['performance']['cpu_limit'] * 1.3)
        elif avg_cpu_usage < 0.3:
            optimized['performance']['cpu_limit'] = max(0.5, optimized['performance']['cpu_limit'] * 0.8)
        
        # Adjust memory limits
        if avg_memory_usage > 0.8:
            optimized['resources']['memory_limit'] = self.increase_resource(
                optimized['resources']['memory_limit'], 1.4
            )
        elif avg_memory_usage < 0.3:
            optimized['resources']['memory_limit'] = self.increase_resource(
                optimized['resources']['memory_limit'], 0.8
            )
        
        # Adjust concurrency settings
        if peak_concurrent_tasks > 3:
            optimized['performance']['auto_scaling'] = True
            optimized['performance']['max_instances'] = min(10, peak_concurrent_tasks * 2)
        
        return optimized
    
    def create_instance_from_template(self, template, instance_id, project_name):
        """Create agent instance from optimized template"""
        print(f"Creating instance {instance_id} from template")
        
        start_time = time.time()
        
        # Create instance directory structure
        claude_dir = Path(os.environ.get('CLAUDE_DIR', Path.home() / '.claude'))
        instance_dir = claude_dir / 'agents' / instance_id
        instance_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        (instance_dir / 'workspace').mkdir(exist_ok=True)
        (instance_dir / 'config').mkdir(exist_ok=True)
        (instance_dir / 'logs').mkdir(exist_ok=True)
        (instance_dir / 'temp').mkdir(exist_ok=True)
        
        # Set secure permissions
        os.chmod(instance_dir, 0o700)
        
        # Create workspace structure from template
        workspace_structure = template.get('context', {}).get('workspace_structure', [])
        for directory in workspace_structure:
            (instance_dir / 'workspace' / directory).mkdir(parents=True, exist_ok=True)
        
        # Generate instance configuration
        instance_config = {
            'instance_id': instance_id,
            'agent_type': template['agent_type'],
            'project_name': project_name,
            'created_at': datetime.utcnow().isoformat() + 'Z',
            'template_version': template.get('template_version', '2.0'),
            'workspace_dir': str(instance_dir / 'workspace'),
            'session_name': f'claude-agent-{instance_id}',
            'pipe_path': str(claude_dir / 'pipes' / f'pipe_{instance_id}'),
            'status': 'active',
            **template
        }
        
        # Save instance configuration
        config_file = instance_dir / 'config' / 'agent.json'
        with open(config_file, 'w') as f:
            json.dump(instance_config, f, indent=2)
        
        # Create named pipe for communication
        pipe_path = Path(instance_config['pipe_path'])
        pipe_path.parent.mkdir(parents=True, exist_ok=True)
        if not pipe_path.exists():
            os.mkfifo(pipe_path)
            os.chmod(pipe_path, 0o600)
        
        # Initialize agent-specific files
        self.initialize_agent_files(instance_dir, template)
        
        creation_time = time.time() - start_time
        
        # Record instance in database
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO agent_instances 
                (instance_id, agent_type, template_version, project_name, creation_time, 
                 status, workspace_path, session_name, pipe_path)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                instance_id, template['agent_type'], template.get('template_version'),
                project_name, creation_time, 'active', str(instance_dir),
                instance_config['session_name'], instance_config['pipe_path']
            ))
            conn.commit()
        
        print(f"Instance created in {creation_time:.2f}s: {instance_id}")
        return instance_config
    
    def initialize_agent_files(self, instance_dir, template):
        """Initialize agent-specific files and configurations"""
        agent_type = template['agent_type']
        workspace_dir = instance_dir / 'workspace'
        
        if agent_type == 'frontend-developer':
            # Create package.json for frontend projects
            package_json = {
                'name': f'agent-{instance_dir.name}',
                'version': '1.0.0',
                'private': True,
                'scripts': {
                    'dev': 'vite',
                    'build': 'vite build',
                    'lint': 'eslint src',
                    'test': 'vitest'
                },
                'dependencies': {},
                'devDependencies': {
                    'vite': '^4.0.0',
                    'eslint': '^8.0.0',
                    'vitest': '^0.30.0'
                }
            }
            
            with open(workspace_dir / 'package.json', 'w') as f:
                json.dump(package_json, f, indent=2)
            
            # Create basic vite config
            vite_config = '''import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 3000,
    host: true
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})
'''
            with open(workspace_dir / 'vite.config.js', 'w') as f:
                f.write(vite_config)
        
        elif agent_type == 'backend-developer':
            # Create basic server structure
            if 'node.js' in template.get('specialization', {}).get('primary_skills', []):
                package_json = {
                    'name': f'agent-{instance_dir.name}',
                    'version': '1.0.0',
                    'main': 'src/index.js',
                    'scripts': {
                        'start': 'node src/index.js',
                        'dev': 'nodemon src/index.js',
                        'test': 'jest'
                    },
                    'dependencies': {
                        'express': '^4.18.0',
                        'cors': '^2.8.5',
                        'helmet': '^6.0.0'
                    },
                    'devDependencies': {
                        'nodemon': '^2.0.0',
                        'jest': '^29.0.0'
                    }
                }
                
                with open(workspace_dir / 'package.json', 'w') as f:
                    json.dump(package_json, f, indent=2)
        
        elif agent_type == 'devops-engineer':
            # Create basic Dockerfile
            dockerfile_content = '''FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
'''
            with open(workspace_dir / 'Dockerfile', 'w') as f:
                f.write(dockerfile_content)
            
            # Create docker-compose.yml
            compose_content = '''version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
'''
            with open(workspace_dir / 'docker-compose.yml', 'w') as f:
                f.write(compose_content)
    
    def monitor_template_requests(self):
        """Monitor workspace for template creation requests"""
        input_dir = self.workspace_dir / 'input'
        input_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Agent Template Engine monitoring: {input_dir}")
        print("Waiting for template requests...")
        
        processed_files = set()
        
        while True:
            try:
                # Look for assignment files that need agent creation
                for request_file in input_dir.glob('*-assignments.json'):
                    if request_file not in processed_files:
                        print(f"Processing template request: {request_file}")
                        
                        # Load assignment data
                        with open(request_file, 'r') as f:
                            assignment_data = json.load(f)
                        
                        # Extract agent requirements
                        required_agents = self.extract_agent_requirements(assignment_data)
                        
                        # Create optimized templates for each agent
                        for agent_req in required_agents:
                            template = self.generate_dynamic_template(
                                agent_req['agent_type'],
                                agent_req['project_context'],
                                agent_req['performance_requirements']
                            )
                            
                            if template:
                                # Create instance from template
                                instance_config = self.create_instance_from_template(
                                    template,
                                    agent_req['instance_id'],
                                    agent_req['project_name']
                                )
                                print(f"Created instance: {instance_config['instance_id']}")
                        
                        processed_files.add(request_file)
                
                time.sleep(3)  # Check every 3 seconds
                
            except KeyboardInterrupt:
                print("Agent Template Engine shutting down...")
                break
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                time.sleep(5)
    
    def extract_agent_requirements(self, assignment_data):
        """Extract agent requirements from assignment data"""
        requirements = []
        
        # Extract unique agent types
        unique_agents = set()
        for task_name, assignment in assignment_data.get('agent_assignments', {}).items():
            agent_type = assignment.get('assigned_agent')
            if agent_type:
                unique_agents.add(agent_type)
        
        # Generate requirements for each agent type
        for agent_type in unique_agents:
            instance_id = f"{assignment_data.get('project_name', 'default')}-{agent_type}-{int(time.time())}"
            
            req = {
                'agent_type': agent_type,
                'instance_id': instance_id,
                'project_name': assignment_data.get('project_name', 'default'),
                'project_context': {
                    'project_size': 'medium',  # Default
                    'technologies': [],
                    'complexity': 0.5,
                    'security_level': 'standard',
                    'compliance_requirements': []
                },
                'performance_requirements': {
                    'speed_priority': 0.7,
                    'concurrency': 1
                }
            }
            
            requirements.append(req)
        
        return requirements

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 agent-template-engine.py <workspace_dir>")
        sys.exit(1)
    
    workspace_dir = sys.argv[1]
    engine = AgentTemplateEngine(workspace_dir)
    
    # Start monitoring workspace
    engine.monitor_template_requests()

if __name__ == "__main__":
    main()