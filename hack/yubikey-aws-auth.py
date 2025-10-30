#!/usr/bin/env python3
"""
YubiKey Static Password AWS Authentication Script
"""

import boto3
import subprocess
import sys
import json
from botocore.exceptions import ClientError


def get_yubikey_password():
    """Get password from YubiKey touch"""
    print("Touch your YubiKey to generate password...")

    # Try different ykman commands
    commands = [
        ["ykman", "otp", "static", "1"],
        ["ykman", "otp", "static", "--slot", "1"],
        ["ykman", "otp", "static", "--slot", "1", "--touch"],
    ]

    for cmd in commands:
        try:
            print(f"Trying: {' '.join(cmd)}")
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            if result.returncode == 0 and result.stdout.strip():
                password = result.stdout.strip()
                print(f"Got password: {password[:10]}...")
                return password
            else:
                print(f"Command failed: {result.stderr}")
        except subprocess.TimeoutExpired:
            print("Timeout waiting for YubiKey touch")
        except FileNotFoundError:
            print("ykman not found. Install YubiKey Manager")
            return None

    # If all commands failed, try manual input
    print("\nManual input mode:")
    print("Touch your YubiKey and paste the generated password:")
    password = input("Password: ").strip()
    if password and len(password) > 10:
        return password

    return None


def generate_mfa_codes(yubikey_password):
    """Generate two MFA codes from YubiKey password"""

    import hashlib
    import time

    # Code 1: Use YubiKey password directly (first 6 digits)
    digits_only = "".join(filter(str.isdigit, yubikey_password))
    if len(digits_only) >= 6:
        mfa_code_1 = digits_only[:6]
    else:
        # Hash-based approach for code 1
        hash_obj = hashlib.md5(yubikey_password.encode())
        hash_hex = hash_obj.hexdigest()
        digits_from_hash = "".join(filter(str.isdigit, hash_hex))
        mfa_code_1 = digits_from_hash[:6] if len(digits_from_hash) >= 6 else "123456"

    # Code 2: Time-based derived code (for consistency)
    current_time = int(time.time())
    time_hash = hashlib.sha256(f"{yubikey_password}{current_time}".encode()).hexdigest()
    time_digits = "".join(filter(str.isdigit, time_hash))
    mfa_code_2 = time_digits[:6] if len(time_digits) >= 6 else "654321"

    print(f"MFA Code 1: {mfa_code_1}")
    print(f"MFA Code 2: {mfa_code_2}")

    return mfa_code_1, mfa_code_2


def assume_role_with_yubikey(role_arn, mfa_serial, yubikey_password):
    """Assume AWS role using YubiKey password as MFA"""

    # Create STS client
    sts = boto3.client("sts")

    try:
        print(f"Assuming role: {role_arn}")
        print(f"Using MFA: {mfa_serial}")

        # Generate two MFA codes
        mfa_code_1, mfa_code_2 = generate_mfa_codes(yubikey_password)

        # Try with Code 1 first
        print(f"Trying MFA Code 1: {mfa_code_1}")
        print(f"Serial Number Length: {len(mfa_serial)}")
        print(f"Serial Number: {mfa_serial}")
        try:
            response = sts.assume_role(
                RoleArn=role_arn,
                RoleSessionName="yubikey-session",
                SerialNumber=mfa_serial,
                TokenCode=mfa_code_1,
            )
            print("Success with MFA Code 1!")
            return response["Credentials"]
        except ClientError as e1:
            print(f"Code 1 failed: {e1}")

            # Try with Code 2
            print(f"Trying MFA Code 2: {mfa_code_2}")
            try:
                response = sts.assume_role(
                    RoleArn=role_arn,
                    RoleSessionName="yubikey-session",
                    SerialNumber=mfa_serial,
                    TokenCode=mfa_code_2,
                )
                print("Success with MFA Code 2!")
                return response["Credentials"]
            except ClientError as e2:
                print(f"Code 2 failed: {e2}")
                print("Both codes failed. You may need to configure OTP device in AWS.")
                return None

    except Exception as e:
        print(f"Unexpected error: {e}")
        return None


def main():
    # Configuration
    ROLE_ARN = "arn:aws:iam::690248313240:role/iacrole"

    # Try both FIDO2 and TOTP MFA serials
    MFA_SERIALS = [
        "arn:aws:iam::690248313240:u2f/user/iacrunner/fido-key-3MPFODX5WZH27BLUTGSB22VEZE",  # FIDO2
        "arn:aws:iam::690248313240:mfa/iacrunner",  # TOTP (if configured)
    ]

    print("🚀 YubiKey AWS Authentication")
    print(f"Role: {ROLE_ARN}")
    print()

    # Get YubiKey password
    yubikey_password = get_yubikey_password()
    if not yubikey_password:
        sys.exit(1)

    print(f"Got YubiKey password: {yubikey_password[:10]}...")

    # Try each MFA serial
    for i, mfa_serial in enumerate(MFA_SERIALS, 1):
        print(f"\nTrying MFA Serial {i}: {mfa_serial}")

        # Assume role
        credentials = assume_role_with_yubikey(ROLE_ARN, mfa_serial, yubikey_password)

        if credentials:
            print("Successfully assumed role!")
            print(f"Access Key: {credentials['AccessKeyId']}")
            print(f"Secret Key: {credentials['SecretAccessKey'][:10]}...")
            print(f"Session Token: {credentials['SessionToken'][:10]}...")

            # Export credentials for use
            print("\nExport these for use:")
            print(f"export AWS_ACCESS_KEY_ID={credentials['AccessKeyId']}")
            print(f"export AWS_SECRET_ACCESS_KEY={credentials['SecretAccessKey']}")
            print(f"export AWS_SESSION_TOKEN={credentials['SessionToken']}")
            sys.exit(0)

    print("\nAll MFA serials failed")
    print("Run: ./hack/setup-yubikey-totp.sh for setup instructions")
    sys.exit(1)


if __name__ == "__main__":
    main()
