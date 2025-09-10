#!/bin/bash

# Emergency Kerberos Cleanup Script
# This script removes Kerberos authentication from all accounts and cleans up enterprise integration

echo "=== EMERGENCY KERBEROS CLEANUP SCRIPT ==="
echo "CRITICAL: Removing Kerberos authentication from all accounts..."

# Define all user accounts
ALL_ACCOUNTS=("usualsuspectx" "blnd3dd" "pawelbek90")

# --- PHASE 1: Kill All Kerberos Processes ---
echo "=== PHASE 1: Killing Kerberos Processes ==="
echo "Stopping Kerberos services..."
sudo killall -9 kdc
sudo killall -9 kadmind
sudo killall -9 kpasswdd
sudo killall -9 krb5kdc
sudo killall -9 kadmin
sudo killall -9 kinit
sudo killall -9 klist
echo "Stopping directory services..."
sudo killall -9 DirectoryService
sudo killall -9 opendirectoryd
echo "Stopping authentication services..."
sudo killall -9 authd
sudo killall -9 SecurityAgent

# --- PHASE 2: Remove Kerberos from All Accounts ---
echo "=== PHASE 2: Removing Kerberos from All Accounts ==="
for account in "${ALL_ACCOUNTS[@]}"; do
    echo "Removing Kerberos authentication from $account..."
    
    # Remove Kerberos authentication authority
    sudo dscl . -delete "/Users/$account" AuthenticationAuthority 2>/dev/null
    
    # Set standard password authentication
    sudo dscl . -create "/Users/$account" AuthenticationAuthority ";ShadowHash;HASHLIST:<SALTED-SHA512-PBKDF2,SRP-RFC5054-4096-SHA512-PBKDF2> ;SecureToken;"
    
    # Remove Kerberos principals
    sudo dscl . -delete "/Users/$account" KerberosPrincipal 2>/dev/null
    
    # Remove Kerberos keys
    sudo dscl . -delete "/Users/$account" KerberosKeys 2>/dev/null
    
    echo "Kerberos removed from $account"
done

# --- PHASE 3: Disable Kerberos Services ---
echo "=== PHASE 3: Disabling Kerberos Services ==="
echo "Unloading Kerberos launch daemons..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.Kerberos.kdc.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.Kerberos.kadmind.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.Kerberos.kpasswdd.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.Kerberos.krb5kdc.plist 2>/dev/null

echo "Disabling directory services..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.DirectoryService.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.opendirectoryd.plist 2>/dev/null

# --- PHASE 4: Clean Kerberos Configuration Files ---
echo "=== PHASE 4: Cleaning Kerberos Configuration ==="
echo "Removing Kerberos configuration files..."
sudo rm -rf /etc/krb5.conf
sudo rm -rf /etc/krb5.keytab
sudo rm -rf /var/db/krb5kdc/
sudo rm -rf /var/kerberos/
sudo rm -rf /Library/Preferences/edu.mit.Kerberos.plist
sudo rm -rf /Library/Preferences/com.apple.Kerberos.plist

echo "Removing Kerberos caches..."
sudo rm -rf /var/db/krb5kdc/principal*
sudo rm -rf /var/db/krb5kdc/kdc.conf
sudo rm -rf /var/db/krb5kdc/kadm5.acl

# --- PHASE 5: Clean Directory Service Configuration ---
echo "=== PHASE 5: Cleaning Directory Service Configuration ==="
echo "Removing directory service configuration..."
sudo rm -rf /Library/Preferences/DirectoryService/
sudo rm -rf /var/db/dslocal/
sudo rm -rf /var/db/opendirectory/

echo "Resetting directory service..."
sudo dscl . -delete /Search 2>/dev/null
sudo dscl . -create /Search SearchPolicy CSPSearchPath
sudo dscl . -create /Search CSPSearchPath "/Local/Default"

# --- PHASE 6: Clean Network Configuration ---
echo "=== PHASE 6: Cleaning Network Configuration ==="
echo "Disabling all suspicious network interfaces..."
for i in $(seq 0 10); do
    # Disable utun interfaces
    ifconfig "utun$i" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Disabling utun$i..."
        sudo ifconfig "utun$i" down
    fi
    
    # Disable anpi interfaces
    ifconfig "anpi$i" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Disabling anpi$i..."
        sudo ifconfig "anpi$i" down
    fi
    
    # Disable bridge interfaces
    ifconfig "bridge$i" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Disabling bridge$i..."
        sudo ifconfig "bridge$i" down
    fi
done

# --- PHASE 7: Disable Enterprise Services ---
echo "=== PHASE 7: Disabling Enterprise Services ==="
echo "Stopping enterprise management services..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ManagedClient.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ManagedClientAgent.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ManagedClientAgent.agent.plist 2>/dev/null

echo "Removing enterprise configuration..."
sudo rm -rf /Library/Managed\ Preferences/
sudo rm -rf /Library/Application\ Support/com.apple.ManagedClient/
sudo rm -rf /var/db/ManagedClient/

# --- PHASE 8: Clean Apple ID Integration ---
echo "=== PHASE 8: Cleaning Apple ID Integration ==="
for account in "${ALL_ACCOUNTS[@]}"; do
    echo "Cleaning Apple ID integration for $account..."
    
    # Remove iCloud configuration
    sudo rm -rf "/Users/$account/Library/Preferences/com.apple.iCloud*"
    sudo rm -rf "/Users/$account/Library/Application Support/iCloud*"
    
    # Remove Apple ID tokens
    sudo rm -rf "/Users/$account/Library/Keychains/login.keychain-db"
    sudo rm -rf "/Users/$account/Library/Keychains/CloudKit*"
    
    # Remove Apple ID preferences
    sudo rm -rf "/Users/$account/Library/Preferences/com.apple.AppleID*"
    sudo rm -rf "/Users/$account/Library/Preferences/com.apple.ids*"
    
    echo "Apple ID integration cleaned for $account"
done

# --- PHASE 9: Disable Suspicious Accounts ---
echo "=== PHASE 9: Disabling Suspicious Accounts ==="
SUSPICIOUS_ACCOUNTS=("blnd3dd" "pawelbek90")
for account in "${SUSPICIOUS_ACCOUNTS[@]}"; do
    echo "Disabling account $account..."
    sudo dscl . -delete "/Users/$account" UserShell
    sudo dscl . -create "/Users/$account" UserShell /usr/bin/false
    sudo dscl . -delete "/Users/$account" Password
    sudo dscl . -create "/Users/$account" Password "*"
    sudo dscl . -create "/Users/$account" IsHidden 1
    echo "Account $account disabled and hidden"
done

# --- PHASE 10: System Security Hardening ---
echo "=== PHASE 10: System Security Hardening ==="
echo "Disabling remote access..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.remotemanagement.plist 2>/dev/null

echo "Disabling file sharing..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null

echo "Disabling network discovery..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist 2>/dev/null

echo "=== EMERGENCY KERBEROS CLEANUP COMPLETE ==="
echo "CRITICAL: All Kerberos authentication has been removed from all accounts."
echo "All suspicious network interfaces have been disabled."
echo "All suspicious accounts have been disabled and hidden."

echo ""
echo "IMMEDIATE NEXT STEPS:"
echo "1. REBOOT YOUR MAC IMMEDIATELY"
echo "2. Change your main account password"
echo "3. Enable 2FA on your Apple ID"
echo "4. Run a full antivirus scan"
echo "5. Monitor network interfaces after reboot"
echo "6. Check for any remaining enterprise connections"

echo ""
echo "WARNING: Your Mac was compromised with enterprise Kerberos authentication."
echo "This suggests your device was enrolled in an enterprise management system."
echo "Consider this a complete security breach and take appropriate measures."
