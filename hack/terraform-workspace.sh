#!/usr/bin/env bash
# Terraform workspace management script
# Allows easy switching between environments (dev, test, prod)

set -e

TERRAFORM_DIR="${1:-infrastructure/terraform/environments}"
WORKSPACE="${2:-}"

# Use terraform if available, otherwise tofu
TERRAFORM_CMD="terraform"
if ! command -v terraform >/dev/null 2>&1; then
  if command -v tofu >/dev/null 2>&1; then
    TERRAFORM_CMD="tofu"
  else
    echo "❌ Neither terraform nor tofu found!"
    exit 1
  fi
fi

cd "$TERRAFORM_DIR" || exit 1

# Function to list workspaces
list_workspaces() {
  echo "📋 Available workspaces:"
  $TERRAFORM_CMD workspace list
}

# Function to create and switch to a workspace
create_workspace() {
  local workspace=$1
  echo "🔧 Creating workspace: $workspace"
  $TERRAFORM_CMD workspace new "$workspace" || $TERRAFORM_CMD workspace select "$workspace"
  echo "✅ Switched to workspace: $workspace"
}

# Function to switch workspace
switch_workspace() {
  local workspace=$1
  echo "🔄 Switching to workspace: $workspace"
  $TERRAFORM_CMD workspace select "$workspace" || create_workspace "$workspace"
  echo "✅ Current workspace: $($TERRAFORM_CMD workspace show)"
}

# Function to show current workspace
show_current() {
  echo "📍 Current workspace: $($TERRAFORM_CMD workspace show)"
}

# Function to initialize with workspace-specific backend
init_workspace() {
  local workspace=$1
  echo "🚀 Initializing workspace: $workspace"
  
  # Switch to workspace first
  switch_workspace "$workspace"
  
  # Initialize terraform
  $TERRAFORM_CMD init
  
  echo "✅ Workspace $workspace initialized"
}

# Main menu
if [ -z "$WORKSPACE" ]; then
  echo "🔧 Terraform Workspace Manager"
  echo ""
  echo "Usage:"
  echo "  $0 [terraform_dir] [workspace]"
  echo ""
  echo "Examples:"
  echo "  $0                         # Show current workspace"
  echo "  $0 . dev                   # Switch to dev workspace"
  echo "  $0 . test                  # Switch to test workspace"
  echo "  $0 . prod                  # Switch to prod workspace"
  echo "  $0 . list                  # List all workspaces"
  echo ""
  show_current
  list_workspaces
else
  case "$WORKSPACE" in
    list)
      list_workspaces
      ;;
    init-dev|init-test|init-prod)
      WORKSPACE_NAME=$(echo "$WORKSPACE" | sed 's/init-//')
      init_workspace "$WORKSPACE_NAME"
      ;;
    *)
      switch_workspace "$WORKSPACE"
      ;;
  esac
fi

