#!/bin/bash

# Terminal History Consolidation Script
# This script consolidates all terminal history into one unified history file

echo "=== TERMINAL HISTORY CONSOLIDATION SCRIPT ==="
echo "This script will consolidate all terminal history into one unified file."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

echo "Starting terminal history consolidation..."
echo ""

# =============================================================================
# PHASE 1: BACKUP EXISTING HISTORY
# =============================================================================

echo "=== PHASE 1: BACKUP EXISTING HISTORY ==="

echo "Creating backup of existing history files..."
mkdir -p ~/terminal_history_backup
cp ~/.bash_history ~/terminal_history_backup/bash_history_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No bash history found"
cp ~/.zsh_history ~/terminal_history_backup/zsh_history_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No zsh history found"

echo "Backup created in ~/terminal_history_backup/"
echo ""

# =============================================================================
# PHASE 2: COLLECT ALL TERMINAL HISTORY
# =============================================================================

echo "=== PHASE 2: COLLECT ALL TERMINAL HISTORY ==="

echo "Collecting all terminal history files..."
HISTORY_DIR="/tmp/consolidated_history_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$HISTORY_DIR"

echo "Collecting bash history..."
if [ -f ~/.bash_history ]; then
    cp ~/.bash_history "$HISTORY_DIR/bash_history"
    echo "Bash history collected"
else
    echo "No bash history found"
fi

echo "Collecting zsh history..."
if [ -f ~/.zsh_history ]; then
    cp ~/.zsh_history "$HISTORY_DIR/zsh_history"
    echo "Zsh history collected"
else
    echo "No zsh history found"
fi

echo "Collecting history from all terminal sessions..."
# Collect history from all active terminal sessions
for tty in $(who | grep "ttys" | awk '{print $2}'); do
    echo "Collecting history from $tty..."
    # Try to get history from each terminal session
    ps aux | grep "$tty" | grep -v grep | while read line; do
        echo "Terminal session: $line" >> "$HISTORY_DIR/terminal_sessions.txt"
    done
done

echo ""

# =============================================================================
# PHASE 3: CONSOLIDATE HISTORY FILES
# =============================================================================

echo "=== PHASE 3: CONSOLIDATE HISTORY FILES ==="

echo "Consolidating all history into one file..."
CONSOLIDATED_HISTORY="$HISTORY_DIR/consolidated_history.txt"

# Start with bash history
if [ -f "$HISTORY_DIR/bash_history" ]; then
    echo "Adding bash history..."
    cat "$HISTORY_DIR/bash_history" >> "$CONSOLIDATED_HISTORY"
fi

# Add zsh history
if [ -f "$HISTORY_DIR/zsh_history" ]; then
    echo "Adding zsh history..."
    cat "$HISTORY_DIR/zsh_history" >> "$CONSOLIDATED_HISTORY"
fi

# Add any additional history files
find ~ -name ".*history*" -type f 2>/dev/null | while read file; do
    echo "Adding history from $file..."
    cat "$file" >> "$CONSOLIDATED_HISTORY"
done

echo ""

# =============================================================================
# PHASE 4: CLEAN AND DEDUPLICATE HISTORY
# =============================================================================

echo "=== PHASE 4: CLEAN AND DEDUPLICATE HISTORY ==="

echo "Cleaning and deduplicating history..."
CLEAN_HISTORY="$HISTORY_DIR/clean_history.txt"

# Remove duplicates and sort
sort "$CONSOLIDATED_HISTORY" | uniq > "$CLEAN_HISTORY"

# Remove empty lines
sed '/^$/d' "$CLEAN_HISTORY" > "$CLEAN_HISTORY.tmp"
mv "$CLEAN_HISTORY.tmp" "$CLEAN_HISTORY"

# Remove lines that are just timestamps or session info
grep -v "^:" "$CLEAN_HISTORY" > "$CLEAN_HISTORY.tmp"
mv "$CLEAN_HISTORY.tmp" "$CLEAN_HISTORY"

echo "History cleaned and deduplicated"
echo ""

# =============================================================================
# PHASE 5: CREATE UNIFIED HISTORY FILE
# =============================================================================

echo "=== PHASE 5: CREATE UNIFIED HISTORY FILE ==="

echo "Creating unified history file..."
UNIFIED_HISTORY="$HISTORY_DIR/unified_history.txt"

# Add header
echo "# Unified Terminal History - $(date)" > "$UNIFIED_HISTORY"
echo "# Consolidated from all terminal sessions" >> "$UNIFIED_HISTORY"
echo "# Total commands: $(wc -l < "$CLEAN_HISTORY")" >> "$UNIFIED_HISTORY"
echo "" >> "$UNIFIED_HISTORY"

# Add cleaned history
cat "$CLEAN_HISTORY" >> "$UNIFIED_HISTORY"

echo "Unified history file created: $UNIFIED_HISTORY"
echo ""

# =============================================================================
# PHASE 6: UPDATE SHELL CONFIGURATION
# =============================================================================

echo "=== PHASE 6: UPDATE SHELL CONFIGURATION ==="

echo "Updating shell configuration for unified history..."

# Update bash configuration
if [ -f ~/.bashrc ]; then
    echo "Updating .bashrc..."
    echo "" >> ~/.bashrc
    echo "# Unified terminal history configuration" >> ~/.bashrc
    echo "export HISTFILE=~/.unified_history" >> ~/.bashrc
    echo "export HISTSIZE=10000" >> ~/.bashrc
    echo "export HISTFILESIZE=10000" >> ~/.bashrc
    echo "export HISTCONTROL=ignoredups:erasedups" >> ~/.bashrc
    echo "shopt -s histappend" >> ~/.bashrc
    echo "PROMPT_COMMAND='history -a; history -c; history -r'" >> ~/.bashrc
fi

# Update zsh configuration
if [ -f ~/.zshrc ]; then
    echo "Updating .zshrc..."
    echo "" >> ~/.zshrc
    echo "# Unified terminal history configuration" >> ~/.zshrc
    echo "export HISTFILE=~/.unified_history" >> ~/.zshrc
    echo "export HISTSIZE=10000" >> ~/.zshrc
    echo "export SAVEHIST=10000" >> ~/.zshrc
    echo "setopt SHARE_HISTORY" >> ~/.zshrc
    echo "setopt HIST_IGNORE_DUPS" >> ~/.zshrc
    echo "setopt HIST_IGNORE_ALL_DUPS" >> ~/.zshrc
    echo "setopt HIST_REDUCE_BLANKS" >> ~/.zshrc
fi

echo ""

# =============================================================================
# PHASE 7: INSTALL UNIFIED HISTORY
# =============================================================================

echo "=== PHASE 7: INSTALL UNIFIED HISTORY ==="

echo "Installing unified history file..."
cp "$CLEAN_HISTORY" ~/.unified_history
chmod 600 ~/.unified_history

echo "Unified history installed as ~/.unified_history"
echo ""

# =============================================================================
# PHASE 8: CREATE HISTORY MANAGEMENT TOOLS
# =============================================================================

echo "=== PHASE 8: CREATE HISTORY MANAGEMENT TOOLS ==="

echo "Creating history management tools..."

# Create history search script
cat > ~/search_history.sh << 'EOF'
#!/bin/bash
# Search unified terminal history
if [ -z "$1" ]; then
    echo "Usage: $0 <search_term>"
    exit 1
fi
grep -i "$1" ~/.unified_history | tail -20
EOF

chmod +x ~/search_history.sh

# Create history stats script
cat > ~/history_stats.sh << 'EOF'
#!/bin/bash
# Show terminal history statistics
echo "=== TERMINAL HISTORY STATISTICS ==="
echo "Total commands: $(wc -l < ~/.unified_history)"
echo "Unique commands: $(sort ~/.unified_history | uniq | wc -l)"
echo "Most used commands:"
sort ~/.unified_history | uniq -c | sort -nr | head -10
echo ""
echo "Recent commands:"
tail -10 ~/.unified_history
EOF

chmod +x ~/history_stats.sh

echo "History management tools created:"
echo "  - ~/search_history.sh (search history)"
echo "  - ~/history_stats.sh (show statistics)"
echo ""

# =============================================================================
# PHASE 9: FINAL VERIFICATION
# =============================================================================

echo "=== PHASE 9: FINAL VERIFICATION ==="

echo "Verifying unified history installation..."
if [ -f ~/.unified_history ]; then
    echo "✅ Unified history file created successfully"
    echo "   File: ~/.unified_history"
    echo "   Size: $(wc -l < ~/.unified_history) lines"
else
    echo "❌ Unified history file not found"
fi

echo "Verifying shell configuration..."
if grep -q "unified_history" ~/.bashrc 2>/dev/null; then
    echo "✅ Bash configuration updated"
else
    echo "❌ Bash configuration not updated"
fi

if grep -q "unified_history" ~/.zshrc 2>/dev/null; then
    echo "✅ Zsh configuration updated"
else
    echo "❌ Zsh configuration not updated"
fi

echo ""

# =============================================================================
# PHASE 10: CLEANUP
# =============================================================================

echo "=== PHASE 10: CLEANUP ==="

echo "Cleaning up temporary files..."
rm -rf "$HISTORY_DIR"

echo "Temporary files cleaned up"
echo ""

echo "=== TERMINAL HISTORY CONSOLIDATION COMPLETE ==="
echo ""
echo "SUMMARY OF ACTIONS PERFORMED:"
echo "✅ Backed up existing history files"
echo "✅ Collected all terminal history"
echo "✅ Consolidated history into one file"
echo "✅ Cleaned and deduplicated history"
echo "✅ Created unified history file"
echo "✅ Updated shell configuration"
echo "✅ Installed unified history"
echo "✅ Created history management tools"
echo "✅ Verified installation"
echo "✅ Cleaned up temporary files"
echo ""
echo "UNIFIED HISTORY FILE: ~/.unified_history"
echo "HISTORY MANAGEMENT TOOLS:"
echo "  - ~/search_history.sh <term> (search history)"
echo "  - ~/history_stats.sh (show statistics)"
echo ""
echo "NEXT STEPS:"
echo "1. Restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc)"
echo "2. All new commands will be saved to unified history"
echo "3. Use ~/search_history.sh to search your history"
echo "4. Use ~/history_stats.sh to see statistics"
echo ""
echo "All terminal sessions will now share the same history file!"
echo ""
