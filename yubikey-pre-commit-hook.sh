#!/bin/bash
# Pre-commit hook to enforce GPG signatures
# This hook will reject commits that are not signed

# Ensure GPG_TTY is set for pinentry
export GPG_TTY=$(tty)

echo "🔍 Pre-commit hook: Checking for GPG signing capability..."

# Check if we can sign with the new key
if ! /Users/usualsuspectx/.nix-profile/bin/gpg --list-secret-keys C6535566CF5B0BB061DA2E95F42227B06AD875D3 >/dev/null 2>&1; then
    echo "❌ ERROR: New signing key not found!"
    echo "Please ensure your new GPG key is available."
    echo "Commit rejected for security reasons."
    exit 1
fi

# Test if we can actually sign (this will fail if YubiKey is not connected)
if ! echo "test" | /Users/usualsuspectx/.nix-profile/bin/gpg --clearsign --default-key C6535566CF5B0BB061DA2E95F42227B06AD875D3 >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot sign with GPG key!"
    echo "Please connect your YubiKey or ensure GPG key is accessible."
    echo "Commit rejected for security reasons."
    exit 1
fi

echo "✅ GPG signing capability verified - commit allowed"
exit 0
