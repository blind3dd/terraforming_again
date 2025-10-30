#!/usr/bin/env bash
# Quick script to activate Nix environment

echo "🔧 Activating Nix development environment..."
nix develop --accept-flake-config

echo "✅ Nix environment activated!"
echo "💡 You can now use:"
echo "   - Go tools (go, gopls, etc.)"
echo "   - Terraform tools (terraform, terraform-ls, tflint)"
echo "   - Ansible tools (ansible)"
echo "   - Cloud CLIs (aws, az, gcloud)"
echo "   - Security tools (trivy, semgrep)"
