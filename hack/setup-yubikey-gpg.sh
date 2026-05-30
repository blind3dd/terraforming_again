#!/bin/bash
# Setup YubiKey GPG for Git Signing
# Ensures YubiKey is properly configured for commit signing

set -e

echo "🔐 Setting up YubiKey GPG for Git Signing"
echo ""

# Check if YubiKey is present
if ! ykman list >/dev/null 2>&1; then
    echo "❌ No YubiKey detected!"
    echo "   Plug in your YubiKey and try again"
    exit 1
fi

echo "✅ YubiKey detected: $(ykman list | head -1)"

# Check GPG card status
if ! gpg --card-status >/dev/null 2>&1; then
    echo "❌ GPG cannot access YubiKey card!"
    echo "   Try: sudo killall -9 gpg-agent && gpg-agent --daemon"
    exit 1
fi

echo "✅ GPG can access YubiKey"

# Get the signing key from the card
SIGNING_KEY=$(gpg --card-status | grep "Signature key" | awk '{print $NF}' | tr -d ':')

if [ -z "$SIGNING_KEY" ]; then
    echo "❌ No signing key found on YubiKey!"
    echo "   You may need to import your GPG key to the YubiKey"
    exit 1
fi

echo "✅ Signing key found: $SIGNING_KEY"

# Setup gpg wrappers (signing key: ~/.config/git/yubikey-signing.env)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/install-gpg-wrappers.sh"
echo "For full YubiKey reset: ${SCRIPT_DIR}/reset-yubikey-openpgp.sh"

# Restart gpg-agent to pick up config
echo "🔄 Restarting gpg-agent..."
gpgconf --kill gpg-agent 2>/dev/null || true
gpg-agent --daemon --enable-ssh-support >/dev/null 2>&1

# Set environment variables
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

echo "✅ GPG environment variables set"

# Configure Git to use the YubiKey signing key
echo "📝 Configuring Git..."
git config --local user.name "usualsuspectx"
git config --local user.email "blind3dd@gmail.com"
git config --local user.signingkey "$SIGNING_KEY"
git config --local commit.gpgsign true
git config --local tag.gpgsign true
git config --local gpg.program "$(which gpg)"

echo "✅ Git configured for GPG signing"

# Test signing
echo "🧪 Testing GPG signing..."
echo "test" | gpg --clearsign --local-user "$SIGNING_KEY" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ GPG signing works!"
    echo ""
    echo "🎉 YubiKey GPG setup complete!"
    echo ""
    echo "Your commits will now be signed with YubiKey."
    echo "Key: $SIGNING_KEY"
else
    echo "❌ GPG signing test failed!"
    echo "   Try unplugging and replugging your YubiKey"
    echo "   Then run: gpg --card-status"
    exit 1
fi

# Show card status
echo ""
echo "📋 YubiKey Card Status:"
gpg --card-status | grep -E "(Reader|Serial|Signature key|Name)"
echo ""

