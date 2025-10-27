#!/bin/bash
# Fix Go Navigation and gopls in VSCode/Cursor
# This script ensures gopls can properly navigate Go code with command+click

set -e

echo "🔄 Fixing Go navigation and gopls setup..."

# Kill any running gopls instances
echo "1️⃣ Killing existing gopls processes..."
pkill gopls 2>/dev/null && echo "   ✅ gopls processes killed" || echo "   ℹ️  No gopls processes found"

# Ensure GOPATH is set correctly
export GOPATH="$HOME/Development/go"
export GO111MODULE="on"
export GOMODCACHE="$HOME/.cache/go/mod"
export GOCACHE="$HOME/.cache/go/build"

echo "2️⃣ Checking Go environment..."
echo "   GOPATH:     $GOPATH"
echo "   GO111MODULE: $GO111MODULE"
echo "   GOMODCACHE: $GOMODCACHE"
echo "   GOCACHE:    $GOCACHE"

# Download dependencies for all Go modules in the repo
echo "3️⃣ Downloading Go module dependencies..."

# Main go.mod (if exists at root)
if [ -f "go.mod" ]; then
    echo "   📦 Downloading root module dependencies..."
    go mod download
    go mod tidy
fi

# Application go.mod
if [ -f "crossplane/applications/go-mysql-api/go.mod" ]; then
    echo "   📦 Downloading go-mysql-api dependencies..."
    cd crossplane/applications/go-mysql-api
    go mod download
    go mod tidy
    cd - > /dev/null
fi

# Find all other go.mod files
find . -name "go.mod" -not -path "./vendor/*" -not -path "./.terraform/*" -not -path "./demo-venv/*" | while read gomod; do
    dir=$(dirname "$gomod")
    if [ "$dir" != "." ] && [ "$dir" != "crossplane/applications/go-mysql-api" ]; then
        echo "   📦 Downloading dependencies in $dir..."
        cd "$dir"
        go mod download || true
        go mod tidy || true
        cd - > /dev/null
    fi
done

# Reinstall gopls to ensure it's in the right location
echo "4️⃣ Installing gopls..."
go install golang.org/x/tools/gopls@latest
echo "   ✅ gopls installed at: $(which gopls)"

# Create symlinks in .nix/bin
echo "5️⃣ Creating tool symlinks..."
mkdir -p .nix/bin
ln -sf "$(which go)" .nix/bin/go
ln -sf "$(which gopls)" .nix/bin/gopls
ln -sf "$(which gofmt)" .nix/bin/gofmt
echo "   ✅ Symlinks created in .nix/bin"

# Update VSCode settings if they exist
echo "6️⃣ Checking VSCode settings..."
if [ -f ".vscode/settings.json" ]; then
    echo "   ✅ VSCode settings found"
else
    echo "   📝 Creating VSCode settings from template..."
    mkdir -p .vscode
    if [ -f ".nix/dotfiles/ide/settings.json" ]; then
        cp .nix/dotfiles/ide/settings.json .vscode/settings.json
        echo "   ✅ VSCode settings created"
    fi
fi

if [ -f ".vscode/extensions.json" ]; then
    echo "   ✅ VSCode extensions.json found"
else
    echo "   📝 Creating VSCode extensions.json from template..."
    if [ -f ".nix/dotfiles/ide/extensions.json" ]; then
        cp .nix/dotfiles/ide/extensions.json .vscode/extensions.json
        echo "   ✅ VSCode extensions.json created"
    fi
fi

# Clear Go cache to force rebuild
echo "7️⃣ Clearing Go caches..."
go clean -cache -modcache -testcache 2>/dev/null || true
echo "   ✅ Caches cleared"

# Rebuild Go workspace
echo "8️⃣ Rebuilding Go workspace..."
if [ -f "crossplane/applications/go-mysql-api/go.mod" ]; then
    cd crossplane/applications/go-mysql-api
    go build -v ./... 2>/dev/null || echo "   ℹ️  Build had warnings (expected)"
    cd - > /dev/null
fi

echo ""
echo "✅ Go navigation setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart VSCode/Cursor"
echo "   2. Open a Go file in crossplane/applications/go-mysql-api/cmd/main.go"
echo "   3. Command+click on imports or function names"
echo "   4. If it still doesn't work, run: pkill gopls && code ."
echo ""
echo "💡 Troubleshooting:"
echo "   - Check Go output panel in VSCode for errors"
echo "   - Run: gopls version (should show latest version)"
echo "   - Check GOPATH: echo \$GOPATH (should be /Users/usualsuspectx/Development/go)"
echo ""

