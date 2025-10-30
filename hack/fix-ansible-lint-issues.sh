#!/bin/bash
set -e

echo "🔧 Fixing Ansible Lint Issues"
echo "=============================="
echo ""

# Detect which sed to use
if command -v gsed &> /dev/null; then
    SED_CMD="gsed"
    SED_INPLACE="-i"
    echo "Using GNU sed (gsed)"
else
    SED_CMD="sed"
    SED_INPLACE="-i ''"
    echo "Using BSD sed (macOS default)"
fi
echo ""

# Fix trailing spaces in all YAML files
echo "1. Removing trailing spaces..."
find infrastructure/ansible/ -type f \( -name "*.yaml" -o -name "*.yml" \) | while IFS= read -r file; do
    if [ -f "$file" ]; then
        echo "  Processing: $file"
        if [ "$SED_CMD" = "gsed" ]; then
            gsed -i 's/[[:space:]]*$//' "$file" 2>/dev/null || true
        else
            sed -i '' -E 's/[[:space:]]+$//' "$file" 2>/dev/null || true
        fi
    fi
done

# Fix newline at end of files
echo ""
echo "2. Adding newlines at end of files..."
find infrastructure/ansible/ -type f \( -name "*.yml" -o -name "*.yaml" \) | while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Add newline if missing (BSD tail syntax)
        if [ -n "$(tail -c1 "$file" 2>/dev/null)" ]; then
            echo "" >> "$file"
            echo "  Fixed: $file"
        fi
    fi
done

# Fix FQCN in database-init.yml
echo ""
echo "3. Fixing FQCN (Fully Qualified Collection Names)..."
if [ -f "infrastructure/ansible/database-init.yml" ]; then
    if [ "$SED_CMD" = "gsed" ]; then
        gsed -i 's/^  - yum:/  - ansible.builtin.yum:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - apt:/  - ansible.builtin.apt:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - command:/  - ansible.builtin.command:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - shell:/  - ansible.builtin.shell:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - copy:/  - ansible.builtin.copy:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - template:/  - ansible.builtin.template:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - file:/  - ansible.builtin.file:/g' infrastructure/ansible/database-init.yml
        gsed -i 's/^  - debug:/  - ansible.builtin.debug:/g' infrastructure/ansible/database-init.yml
    else
        # BSD sed requires different syntax
        /usr/bin/sed -i '' 's/^  - yum:/  - ansible.builtin.yum:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - apt:/  - ansible.builtin.apt:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - command:/  - ansible.builtin.command:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - shell:/  - ansible.builtin.shell:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - copy:/  - ansible.builtin.copy:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - template:/  - ansible.builtin.template:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - file:/  - ansible.builtin.file:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
        /usr/bin/sed -i '' 's/^  - debug:/  - ansible.builtin.debug:/g' infrastructure/ansible/database-init.yml 2>/dev/null || true
    fi
    echo "  Fixed: infrastructure/ansible/database-init.yml"
fi

echo ""
echo "Ansible lint issues fixed!"
echo ""
echo "Manual fixes still needed:"
echo "  1. Rename 'namespace' variable in group_vars/all.yml (it's reserved)"
echo "  2. Check YAML indentation in:"
echo "     - infrastructure/ansible/helm-kustomize/cluster-autoscaler/values.yaml"
echo "     - infrastructure/ansible/helm-kustomize/ansible-operator/crds/ansiblejobs.yaml"
echo "  3. Reorder task keys in database-init.yml (name, when, block)"
echo ""

