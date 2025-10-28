#!/bin/bash

echo "🔧 YubiKey TOTP Setup for AWS"
echo "=============================="
echo ""

echo "📋 Steps to configure YubiKey as TOTP device:"
echo ""
echo "1. 🌐 Go to AWS Console → IAM → Users → iacrunner"
echo "2. 🔐 Security credentials tab"
echo "3. ❌ Remove existing FIDO2 device"
echo "4. ➕ Add MFA device → Authenticator app"
echo "5. 📱 Scan QR code with YubiKey Authenticator app"
echo "6. ✅ Verify with 6-digit code"
echo ""

echo "🔑 Alternative: Use YubiKey Manager to configure TOTP slot"
echo ""

# Check if ykman is available
if command -v ykman &> /dev/null; then
    echo "✅ ykman found"
    echo ""
    echo "🔧 Configure HOTP slot 1 (for AWS MFA):"
    echo "ykman otp hotp 1 --digits 6 --identifier 'AWS'"
    echo ""
    echo "🔧 Configure HOTP slot 2 (backup):"
    echo "ykman otp hotp 2 --digits 6 --identifier 'AWS2'"
    echo ""
    echo "📱 Then use YubiKey Authenticator app to get codes"
    echo "💡 Or use: ykman otp calculate 1"
else
    echo "❌ ykman not found. Install YubiKey Manager first"
fi

echo ""
echo "🎯 After setup, update the script with the new MFA serial:"
echo "arn:aws:iam::690248313240:mfa/iacrunner"
echo ""
echo "💡 This will be much shorter and work with our script!"
