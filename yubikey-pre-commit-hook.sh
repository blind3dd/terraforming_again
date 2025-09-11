#!/bin/bash
# Pre-commit hook to enforce GPG signatures
# This hook will reject commits that are not signed

# Ensure GPG_TTY is set for pinentry
export GPG_TTY=$(tty)

echo "🔍 Pre-commit hook: Checking for YubiKey..."

# Check if YubiKey is connected using the Nix GPG path
if ! /Users/usualsuspectx/.nix-profile/bin/gpg --card-status >/dev/null 2>&1; then
    echo "❌ ERROR: YubiKey not detected!"
    echo "Please connect your YubiKey to sign commits."
    echo "Commit rejected for security reasons."
    exit 1
fi

echo "✅ YubiKey detected - commit allowed"
exit 0
