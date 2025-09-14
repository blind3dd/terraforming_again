#!/bin/bash

# Kill All Terminal Sessions Script
# This script kills all terminal sessions and starts fresh

echo "=== KILL ALL TERMINAL SESSIONS SCRIPT ==="
echo "This script will kill all terminal sessions and start fresh."
echo ""

echo "Current terminal sessions:"
who | grep "ttys" | wc -l
echo ""

echo "Killing all terminal sessions..."

# Kill all ttys sessions except console
who | grep "ttys" | awk '{print $2}' | while read tty; do
    echo "Killing session: $tty"
    sudo pkill -9 -t "$tty" 2>/dev/null || echo "Failed to kill $tty"
done

echo ""

echo "Waiting for sessions to terminate..."
sleep 3

echo "Remaining terminal sessions:"
who | grep "ttys" | wc -l

echo ""
echo "=== TERMINAL SESSION CLEANUP COMPLETE ==="
echo "You can now open a fresh terminal session."
echo ""
