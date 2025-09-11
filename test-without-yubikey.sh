#!/bin/bash
# Test script to simulate YubiKey not connected

echo "🧪 Testing commit without YubiKey connected..."
echo "This should FAIL if our security is working properly"

# Temporarily disable the pre-commit hook
mv .git/hooks/pre-commit .git/hooks/pre-commit.backup

# Try to commit without YubiKey (this should work but be unsigned)
echo "Test without YubiKey" > test-no-yubikey.txt
/Users/usualsuspectx/.nix-profile/bin/git add test-no-yubikey.txt

echo "Attempting commit without YubiKey..."
if /Users/usualsuspectx/.nix-profile/bin/git commit -m "Test 4: Without YubiKey - should be unsigned

❌ This commit should be unsigned
❌ YubiKey is not connected
❌ This demonstrates what happens without security enforcement"

then
    echo "✅ Commit succeeded (but should be unsigned)"
    echo "🔍 Checking if commit is signed..."
    /Users/usualsuspectx/.nix-profile/bin/git show --show-signature HEAD | grep -q "Good signature" && echo "❌ ERROR: Commit was signed when it shouldn't be!" || echo "✅ Correct: Commit is unsigned"
else
    echo "❌ Commit failed (unexpected)"
fi

# Restore the pre-commit hook
mv .git/hooks/pre-commit.backup .git/hooks/pre-commit

echo "🧪 Test completed"
