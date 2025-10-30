#!/usr/bin/env bash
# Bulk fix FQCNs, trailing spaces, and formatting in Ansible files

set -euo pipefail

ANSIBLE_DIR="infrastructure/ansible"

echo "🔧 Fixing Ansible files..."

find "$ANSIBLE_DIR" -name "*.yml" -type f | while read -r file; do
    # Skip templates and helm files
    if [[ "$file" == *"/templates/"* ]] || [[ "$file" == *"/helm-kustomize/"* ]]; then
        continue
    fi
    
    echo "Processing: $file"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Apply FQCN replacements using sed (macOS syntax)
    sed -i.bak2 \
        -e 's/^\([[:space:]]*\)include_tasks:/  ansible.builtin.include_tasks:/g' \
        -e 's/^\([[:space:]]*\)include:/  ansible.builtin.include_tasks:/g' \
        -e 's/^\([[:space:]]*\)command:/  ansible.builtin.command:/g' \
        -e 's/^\([[:space:]]*\)shell:/  ansible.builtin.shell:/g' \
        -e 's/^\([[:space:]]*\)get_url:/  ansible.builtin.get_url:/g' \
        -e 's/^\([[:space:]]*\)template:/  ansible.builtin.template:/g' \
        -e 's/^\([[:space:]]*\)copy:/  ansible.builtin.copy:/g' \
        -e 's/^\([[:space:]]*\)file:/  ansible.builtin.file:/g' \
        -e 's/^\([[:space:]]*\)debug:/  ansible.builtin.debug:/g' \
        -e 's/^\([[:space:]]*\)fail:/  ansible.builtin.fail:/g' \
        -e 's/^\([[:space:]]*\)package:/  ansible.builtin.package:/g' \
        -e 's/^\([[:space:]]*\)lineinfile:/  ansible.builtin.lineinfile:/g' \
        -e 's/^\([[:space:]]*\)set_fact:/  ansible.builtin.set_fact:/g' \
        -e 's/^\([[:space:]]*\)authorized_key:/  ansible.builtin.authorized_key:/g' \
        -e 's/^\([[:space:]]*\)yum:/  ansible.builtin.yum:/g' \
        -e 's/^\([[:space:]]*\)apt:/  ansible.builtin.apt:/g' \
        -e 's/^\([[:space:]]*\)service:/  ansible.builtin.service:/g' \
        -e 's/^\([[:space:]]*\)stat:/  ansible.builtin.stat:/g' \
        -e 's/^\([[:space:]]*\)uri:/  ansible.builtin.uri:/g' \
        -e 's/^\([[:space:]]*\)wait_for:/  ansible.builtin.wait_for:/g' \
        -e 's/become: yes/become: true/g' \
        -e 's/ignore_errors: yes/ignore_errors: true/g' \
        -e 's/create: yes/create: true/g' \
        -e 's/with_decryption: yes/with_decryption: true/g' \
        -e 's/[[:space:]]*$//' \
        "$file" && rm -f "$file.bak2"
    
    # Clean up backup if no changes
    if diff -q "$file" "$file.bak" > /dev/null 2>&1; then
        rm "$file.bak"
    else
        echo "  ✓ Updated $file"
    fi
done

echo "✅ Done! Review changes with: git diff infrastructure/ansible/"
echo "⚠️  Backup files created as *.bak - remove them after review"

