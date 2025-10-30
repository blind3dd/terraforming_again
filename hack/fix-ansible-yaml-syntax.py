#!/usr/bin/env python3
"""
Fix Ansible YAML syntax errors - specifically the indentation issue
where module actions are not properly indented.
"""

import re
import sys
from pathlib import Path


def fix_yaml_indentation(file_path):
    """Fix common YAML indentation issues in Ansible files.
    - Ensures module lines (ansible.builtin.*, kubernetes.core.*, etc.) are indented under a task
    - Aligns task-level keys (register/when/changed_when/failed_when/ignore_errors/loop/retries/delay/until)
    - Indents module parameters under the module line
    """

    with open(file_path, "r") as f:
        lines = f.readlines()

    fixed_lines = []
    i = 0
    changes_made = False

    # Regexes
    task_name_re = re.compile(r"^(?P<indent>\s*)-\s+name:")
    module_re = re.compile(
        r"^(?P<indent>\s*)(ansible\.builtin\.|ansible\.legacy\.|kubernetes\.core\.|amazon\.aws\.|community\.[a-zA-Z_]+\.)\w+:"
    )
    task_keys = (
        "register",
        "when",
        "changed_when",
        "failed_when",
        "ignore_errors",
        "loop",
        "retries",
        "delay",
        "until",
    )

    last_task_indent = None  # indentation of the current "- name:" line
    last_module_indent = None  # indentation of the module line under the task
    in_module_params = False

    while i < len(lines):
        line = lines[i]

        # Detect start of a new task
        m_task = task_name_re.match(line)
        if m_task:
            last_task_indent = m_task.group("indent")
            last_module_indent = None
            in_module_params = False
            fixed_lines.append(line)
            i += 1
            continue

        # Module line under a task: ensure it is indented two spaces more than task indent
        m_mod = module_re.match(line)
        if m_mod and last_task_indent is not None:
            desired_indent = last_task_indent + "  "  # two spaces under "- name:"
            if m_mod.group("indent") != desired_indent:
                line = desired_indent + line[len(m_mod.group("indent")) :]
                changes_made = True
                last_module_indent = desired_indent
                in_module_params = True
                fixed_lines.append(line)
                i += 1
                continue
            else:
                last_module_indent = m_mod.group("indent")
                in_module_params = True
                fixed_lines.append(line)
                i += 1
                continue

        # Task-level keys: align to module indent if present, else two spaces under task
        if last_task_indent is not None and any(
            line.lstrip().startswith(k + ":") for k in task_keys
        ):
            desired_indent = last_module_indent or (last_task_indent + "  ")
            current_indent = line[: len(line) - len(line.lstrip())]
            if current_indent != desired_indent:
                line = desired_indent + line.lstrip()
                changes_made = True
                fixed_lines.append(line)
                i += 1
                continue

        # Module parameters: if the previous line was a module, ensure params are indented two more spaces
        if in_module_params and line.strip() and not line.lstrip().startswith("- "):
            # Stop parameter block if blank line or next task/play/section
            if line.lstrip().startswith(("#", "---")):
                in_module_params = False
            else:
                # param lines should be module_indent + two spaces
                desired_param_indent = (last_module_indent or "") + "  "
                current_indent = line[: len(line) - len(line.lstrip())]
                # Only shift if this looks like a simple key: value line
                if re.match(r"^\s*[a-zA-Z0-9_]+:", line):
                    if current_indent != desired_param_indent:
                        line = desired_param_indent + line.lstrip()
                        changes_made = True
                        fixed_lines.append(line)
                        i += 1
                        continue

        # Reset module params flag on blank line or dedent
        if line.strip() == "":
            in_module_params = False

        fixed_lines.append(line)
        i += 1

    if changes_made:
        with open(file_path, "w") as f:
            f.writelines(fixed_lines)
        return True
    return False


def main():
    ansible_dir = Path("infrastructure/ansible")

    if not ansible_dir.exists():
        print(f"❌ Directory not found: {ansible_dir}")
        sys.exit(1)

    print("🔧 Fixing Ansible YAML Syntax Errors")
    print("=" * 40)
    print()

    # Find all YAML files
    yaml_files = list(ansible_dir.rglob("*.yml")) + list(ansible_dir.rglob("*.yaml"))

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


if __name__ == "__main__":
    main()
