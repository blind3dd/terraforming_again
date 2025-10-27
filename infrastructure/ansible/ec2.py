#!/usr/bin/env python3
"""
AWS EC2 Dynamic Inventory for Ansible
Automatically discovers EC2 instances based on tags
"""

import json
import os
import sys
import boto3
import argparse
from botocore.exceptions import ClientError, NoCredentialsError

class EC2Inventory:
    def __init__(self):
        self.region = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')
        self.ec2_client = None
        self.instances = []
        
    def connect_aws(self):
        """Connect to AWS EC2"""
        try:
            self.ec2_client = boto3.client('ec2', region_name=self.region)
        except NoCredentialsError:
            print("ERROR: AWS credentials not found. Please configure AWS CLI or set environment variables.", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"ERROR: Failed to connect to AWS: {e}", file=sys.stderr)
            sys.exit(1)
    
    def get_instances(self):
        """Get all EC2 instances with their tags"""
        try:
            response = self.ec2_client.describe_instances(
                Filters=[
                    {
                        'Name': 'instance-state-name',
                        'Values': ['running', 'pending']
                    }
                ]
            )
            
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    self.instances.append(instance)
                    
        except ClientError as e:
            print(f"ERROR: Failed to describe instances: {e}", file=sys.stderr)
            sys.exit(1)
    
    def get_instance_groups(self, instance):
        """Determine Ansible groups based on instance tags"""
        groups = []
        
        # Add instance to all group
        groups.append('all')
        
        # Add to webservers group if it's a web server
        if self.has_tag(instance, 'Service', 'go-mysql-api'):
            groups.append('webservers')
            groups.append('go_mysql_api_instances')
        
        # Add environment-based groups
        environment = self.get_tag_value(instance, 'Environment')
        if environment:
            groups.append(f"env_{environment}")
        
        # Add instance type groups
        instance_type = instance.get('InstanceType', 'unknown')
        groups.append(f"type_{instance_type}")
        
        # Add availability zone groups
        az = instance.get('Placement', {}).get('AvailabilityZone', 'unknown')
        groups.append(f"az_{az.replace('-', '_')}")
        
        return groups
    
    def has_tag(self, instance, key, value):
        """Check if instance has a specific tag key-value pair"""
        tags = instance.get('Tags', [])
        for tag in tags:
            if tag.get('Key') == key and tag.get('Value') == value:
                return True
        return False
    
    def get_tag_value(self, instance, key):
        """Get tag value for a specific key"""
        tags = instance.get('Tags', [])
        for tag in tags:
            if tag.get('Key') == key:
                return tag.get('Value')
        return None
    
    def get_instance_vars(self, instance):
        """Get variables for an instance"""
        vars_dict = {
            'ansible_host': instance.get('PublicIpAddress') or instance.get('PrivateIpAddress'),
            'private_ip': instance.get('PrivateIpAddress'),
            'public_ip': instance.get('PublicIpAddress'),
            'instance_id': instance['InstanceId'],
            'instance_type': instance.get('InstanceType'),
            'availability_zone': instance.get('Placement', {}).get('AvailabilityZone'),
            'vpc_id': instance.get('VpcId'),
            'subnet_id': instance.get('SubnetId'),
            'state': instance.get('State', {}).get('Name'),
            'launch_time': instance.get('LaunchTime').isoformat() if instance.get('LaunchTime') else None
        }
        
        # Add tags as variables
        tags = instance.get('Tags', [])
        for tag in tags:
            key = tag.get('Key', '').lower().replace('-', '_')
            value = tag.get('Value')
            if key and value:
                vars_dict[f"tag_{key}"] = value
        
        return vars_dict
    
    def generate_inventory(self):
        """Generate the complete inventory structure"""
        inventory = {
            '_meta': {
                'hostvars': {}
            }
        }
        
        # Initialize groups
        all_groups = set()
        
        for instance in self.instances:
            instance_id = instance['InstanceId']
            groups = self.get_instance_groups(instance)
            vars_dict = self.get_instance_vars(instance)
            
            # Add instance to groups
            for group in groups:
                if group not in inventory:
                    inventory[group] = {
                        'hosts': [],
                        'vars': {}
                    }
                inventory[group]['hosts'].append(instance_id)
                all_groups.add(group)
            
            # Add host variables
            inventory['_meta']['hostvars'][instance_id] = vars_dict
        
        # Add group variables
        if 'webservers' in inventory:
            inventory['webservers']['vars'] = {
                'ansible_user': 'ec2-user',
                'ansible_ssh_common_args': '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null',
                'ansible_python_interpreter': '/usr/bin/python3',
                'ansible_become': True,
                'ansible_become_method': 'sudo'
            }
        
        if 'go_mysql_api_instances' in inventory:
            inventory['go_mysql_api_instances']['vars'] = {
                'app_name': 'go-mysql-api',
                'app_port': 8080
            }
        
        return inventory
    
    def list_instances(self):
        """List all instances (for --list argument)"""
        self.connect_aws()
        self.get_instances()
        inventory = self.generate_inventory()
        
        # Remove _meta section for --list output
        if '_meta' in inventory:
            del inventory['_meta']
        
        return inventory
    
    def get_host_vars(self, hostname):
        """Get variables for a specific host (for --host argument)"""
        self.connect_aws()
        self.get_instances()
        
        for instance in self.instances:
            if instance['InstanceId'] == hostname:
                return self.get_instance_vars(instance)
        
        return {}

def main():
    parser = argparse.ArgumentParser(description='AWS EC2 Dynamic Inventory')
    parser.add_argument('--list', action='store_true', help='List all instances')
    parser.add_argument('--host', help='Get variables for a specific host')
    parser.add_argument('--pretty', action='store_true', help='Pretty print JSON output')
    
    args = parser.parse_args()
    
    inventory = EC2Inventory()
    
    if args.host:
        # Get host variables
        host_vars = inventory.get_host_vars(args.host)
        print(json.dumps(host_vars, indent=2 if args.pretty else None))
    else:
        # List all instances
        inventory_data = inventory.list_instances()
        print(json.dumps(inventory_data, indent=2 if args.pretty else None))

if __name__ == '__main__':
    main()
