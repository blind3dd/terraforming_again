#!/bin/bash

# Aggressive Android Cleanup Script
# Removes all malicious apps and most Samsung bloatware

set -e

ADB_PATH="./platform-tools/adb"
DEVICE_ID=""

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check ADB connection
check_adb() {
    if ! command -v "$ADB_PATH" &> /dev/null; then
        log_error "ADB not found at $ADB_PATH"
        exit 1
    fi
    
    DEVICE_ID=$("$ADB_PATH" devices | grep -v "List of devices" | grep -v "^$" | awk '{print $1}' | head -1)
    if [[ -z "$DEVICE_ID" ]]; then
        log_error "No Android device connected"
        exit 1
    fi
    
    log "Connected to device: $DEVICE_ID"
}

# Remove Microsoft apps
remove_microsoft_apps() {
    log "Removing Microsoft apps..."
    local microsoft_apps=(
        "com.microsoft.appmanager"
        "com.microsoft.skydrive"
        "com.microsoft.office.excel"
        "com.microsoft.office.powerpoint"
        "com.microsoft.office.word"
        "com.microsoft.edge"
        "com.microsoft.teams"
        "com.microsoft.outlook"
        "com.microsoft.authenticator"
    )
    
    for app in "${microsoft_apps[@]}"; do
        if "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -q "$app"; then
            log "Removing $app"
            "$ADB_PATH" -s "$DEVICE_ID" shell pm uninstall --user 0 "$app" 2>/dev/null || true
        fi
    done
}

# Remove Facebook apps
remove_facebook_apps() {
    log "Removing Facebook apps..."
    local facebook_apps=(
        "com.facebook.katana"
        "com.facebook.services"
        "com.facebook.system"
        "com.facebook.appmanager"
        "com.facebook.mlite"
        "com.facebook.orca"
    )
    
    for app in "${facebook_apps[@]}"; do
        if "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -q "$app"; then
            log "Removing $app"
            "$ADB_PATH" -s "$DEVICE_ID" shell pm uninstall --user 0 "$app" 2>/dev/null || true
        fi
    done
}

# Remove Knox/MDM/Enterprise apps
remove_enterprise_apps() {
    log "Removing Knox/MDM/Enterprise apps..."
    local enterprise_apps=(
        "com.samsung.android.knox.containercore"
        "com.samsung.android.knox.attestation"
        "com.samsung.android.knox.containeragent"
        "com.samsung.knox.keychain"
        "com.samsung.knox.securefolder"
        "com.sec.enterprise.knox.attestation"
        "com.sec.enterprise.mdm.services.simpin"
        "com.samsung.android.mdm"
        "com.samsung.android.knox.analytics.uploader"
        "com.knox.vpn.proxyhandler"
        "com.sec.enterprise.knox.cloudmdm.smdms"
    )
    
    for app in "${enterprise_apps[@]}"; do
        if "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -q "$app"; then
            log "Removing $app"
            "$ADB_PATH" -s "$DEVICE_ID" shell pm uninstall --user 0 "$app" 2>/dev/null || true
        fi
    done
}

# Remove Samsung bloatware (aggressive)
remove_samsung_bloatware() {
    log "Removing Samsung bloatware..."
    local samsung_apps=(
        "com.samsung.android.bixby.service"
        "com.samsung.android.bixby.agent"
        "com.samsung.android.bixby.wakeup"
        "com.samsung.android.app.settings.bixby"
        "com.samsung.systemui.bixby2"
        "com.samsung.android.game.gamehome"
        "com.samsung.android.game.gametools"
        "com.samsung.android.game.gos"
        "com.samsung.android.app.ledcoverdream"
        "com.sec.android.widgetapp.samsungapps"
        "com.samsung.android.smartswitchassistant"
        "com.samsung.android.app.galaxyfinder"
        "com.samsung.android.themestore"
        "com.samsung.android.app.aodservice"
        "com.samsung.android.app.cocktailbarservice"
        "com.samsung.android.aremoji"
        "com.samsung.android.app.social"
        "com.samsung.android.samsungpass"
        "com.samsung.android.app.sbrowseredge"
        "com.sec.android.gallery3d.panorama360view"
    )
    
    for app in "${samsung_apps[@]}"; do
        if "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -q "$app"; then
            log "Removing $app"
            "$ADB_PATH" -s "$DEVICE_ID" shell pm uninstall --user 0 "$app" 2>/dev/null || true
        fi
    done
}

# Remove Google bloatware
remove_google_bloatware() {
    log "Removing Google bloatware..."
    local google_apps=(
        "com.google.android.googlequicksearchbox"
        "com.google.android.onetimeinitializer"
        "com.google.android.apps.photos"
        "com.google.android.apps.docs"
        "com.google.android.apps.sheets"
        "com.google.android.apps.slides"
        "com.google.android.apps.tachyon"
        "com.google.android.apps.meetings"
        "com.google.android.youtube"
        "com.google.android.apps.maps"
        "com.google.android.gm"
    )
    
    for app in "${google_apps[@]}"; do
        if "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -q "$app"; then
            log "Removing $app"
            "$ADB_PATH" -s "$DEVICE_ID" shell pm uninstall --user 0 "$app" 2>/dev/null || true
        fi
    done
}

# Check remaining apps
check_remaining_apps() {
    log "Checking remaining apps..."
    local total_apps=$("$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | wc -l)
    log "Total apps remaining: $total_apps"
    
    log "Remaining Microsoft apps:"
    "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -i microsoft || echo "None"
    
    log "Remaining Facebook apps:"
    "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -i facebook || echo "None"
    
    log "Remaining Knox/Enterprise apps:"
    "$ADB_PATH" -s "$DEVICE_ID" shell pm list packages | grep -E "(knox|mdm|enterprise)" || echo "None"
}

# Main execution
main() {
    log "Starting aggressive Android cleanup..."
    check_adb
    
    remove_microsoft_apps
    remove_facebook_apps
    remove_enterprise_apps
    remove_samsung_bloatware
    remove_google_bloatware
    
    check_remaining_apps
    
    log "Aggressive cleanup completed!"
}

main "$@"
