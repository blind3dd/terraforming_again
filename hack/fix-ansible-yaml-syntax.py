#!/usr/bin/env python3
"""
Fix Ansible YAML syntax errors - specifically the indentation issue
where module actions are not properly indented.
"""

import re
import sys
from pathlib import Path

def fix_yaml_indentation(file_path):
    """Fix common YAML indentation issues in Ansible files"""
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    fixed_lines = []
    i = 0
    changes_made = False
    
    while i < len(lines):
        line = lines[i]
        
        # Pattern 1: Fix module action indentation
        # Match lines like "  ansible.builtin.command: ..." that should be "    ansible.builtin.command: ..."
        if re.match(r'^  (ansible\.builtin\.\w+|ansible\.legacy\.\w+|kubernetes\.core\.\w+|amazon\.aws\.\w+):', line):
            # Check if this is inside a block/task (previous line should be name or similar)
            if i > 0 and re.search(r'- name:|block:|rescue:|always:', lines[i-1]):
                # Add 2 more spaces to make it 4 spaces total
                fixed_line = '  ' + line
                fixed_lines.append(fixed_line)
                changes_made = True
                print(f"  Fixed line {i+1}: module action indentation")
                i += 1
                continue
        
        # Pattern 2: Fix register indentation (often follows the above pattern)
        if re.match(r'^\s{6,}register:', line):
            # Should be 2 or 4 spaces, not 6+
            fixed_line = '  register:' + line.split('register:')[1]
            fixed_lines.append(fixed_line)
            changes_made = True
            print(f"  Fixed line {i+1}: register indentation")
            i += 1
            continue
        
        # Keep line as-is
        fixed_lines.append(line)
        i += 1
    
    if changes_made:
        with open(file_path, 'w') as f:
            f.writelines(fixed_lines)
        return True
    return False

def main():
    ansible_dir = Path('infrastructure/ansible')
    
    if not ansible_dir.exists():
        print(f"❌ Directory not found: {ansible_dir}")
        sys.exit(1)
    
    print("🔧 Fixing Ansible YAML Syntax Errors")
    print("=" * 40)
    print()
    
    # Find all YAML files
    yaml_files = list(ansible_dir.rglob('*.yml')) + list(ansible_dir.rglob('*.yaml'))
    
    print(f"Found {len(yaml_files)} YAML files")
    print()
    
    fixed_count = 0
    for yaml_file in yaml_files:
        print(f"Processing: {yaml_file}")
        if fix_yaml_indentation(yaml_file):
            fixed_count += 1
            print(f"  ✅ Fixed")
        else:
            print(f"  ⏭️  No changes needed")
    
    print()
    print(f"✅ Fixed {fixed_count} files")
    print()
    
    if fixed_count > 0:
        print("💡 Run ansible-lint again to verify fixes")

if __name__ == '__main__':
    main()

