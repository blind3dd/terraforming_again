#!/bin/bash
# CloudFormation Stack Analysis Script

echo "=== CloudFormation Stack Analysis ==="
echo "Date: $(date)"
echo

echo "Stack Count:"
find stacks/ -name "*_details.json" | wc -l

echo
echo "Stack Names:"
find stacks/ -name "*_details.json" -exec basename {} _details.json \;

echo
echo "Stack Status Summary:"
for file in stacks/*_details.json; do
    if [[ -f "$file" ]]; then
        stack_name=$(basename "$file" _details.json)
        status=$(jq -r '.Stacks[0].StackStatus' "$file" 2>/dev/null || echo "Unknown")
        echo "  $stack_name: $status"
    fi
done

echo
echo "Resource Count by Stack:"
for file in resources/*_resources.json; do
    if [[ -f "$file" ]]; then
        stack_name=$(basename "$file" _resources.json)
        count=$(jq -r '.StackResources | length' "$file" 2>/dev/null || echo "0")
        echo "  $stack_name: $count resources"
    fi
done
