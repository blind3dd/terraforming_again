#!/bin/bash

# Browser Profile Security Audit Script
# Detects JSON injection attacks and malicious browser modifications
# Based on real-world investigation findings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "=========================================="
    echo -e "${CYAN}🔍 $1${NC}"
    echo "=========================================="
    echo ""
}

print_critical() {
    echo -e "${RED}🚨 CRITICAL: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check browser profiles for JSON injection
check_browser_profiles() {
    local browser_name="$1"
    local profile_path="$2"
    
    print_header "CHECKING $browser_name PROFILES"
    
    if [ ! -d "$profile_path" ]; then
        print_info "$browser_name profile directory not found: $profile_path"
        return 0
    fi
    
    print_info "Scanning $browser_name profiles in: $profile_path"
    
    # Check for suspicious JSON files
    local suspicious_files=$(find "$profile_path" -name "*.json" -type f 2>/dev/null | head -20)
    
    if [ -n "$suspicious_files" ]; then
        print_warning "Found JSON files in $browser_name profiles:"
        echo "$suspicious_files"
        echo ""
        
        # Check for JSON injection patterns
        for file in $suspicious_files; do
            if [ -f "$file" ]; then
                # Check for suspicious content
                if grep -q -E "(eval|Function|setTimeout|setInterval|document\.write|innerHTML|outerHTML)" "$file" 2>/dev/null; then
                    print_critical "Potential JSON injection in: $file"
                    echo "Suspicious content found:"
                    grep -n -E "(eval|Function|setTimeout|setInterval|document\.write|innerHTML|outerHTML)" "$file" 2>/dev/null | head -5
                    echo ""
                fi
                
                # Check for base64 encoded content
                if grep -q -E "data:text/html;base64|javascript:|vbscript:" "$file" 2>/dev/null; then
                    print_critical "Base64/script injection in: $file"
                    echo "Suspicious content found:"
                    grep -n -E "data:text/html;base64|javascript:|vbscript:" "$file" 2>/dev/null | head -3
                    echo ""
                fi
                
                # Check for suspicious URLs
                if grep -q -E "(\.ru|\.cn|\.tk|\.ml|\.ga|\.cf)" "$file" 2>/dev/null; then
                    print_warning "Suspicious domains in: $file"
                    echo "Suspicious URLs found:"
                    grep -n -E "(\.ru|\.cn|\.tk|\.ml|\.ga|\.cf)" "$file" 2>/dev/null | head -3
                    echo ""
                fi
            fi
        done
    fi
    
    # Check for malicious extensions
    print_info "Checking for malicious extensions..."
    local extensions_path="$profile_path/Extensions"
    if [ -d "$extensions_path" ]; then
        local extension_count=$(find "$extensions_path" -type d -maxdepth 1 | wc -l)
        print_info "Found $extension_count extensions"
        
        # List extensions
        find "$extensions_path" -type d -maxdepth 1 | while read ext_dir; do
            if [ "$ext_dir" != "$extensions_path" ]; then
                local ext_name=$(basename "$ext_dir")
                print_info "Extension: $ext_name"
            fi
        done
    fi
    
    # Check for suspicious preferences
    print_info "Checking browser preferences..."
    local prefs_file="$profile_path/Preferences"
    if [ -f "$prefs_file" ]; then
        # Check for suspicious settings
        if grep -q -E "(homepage|startup|search)" "$prefs_file" 2>/dev/null; then
            print_warning "Suspicious preferences found in: $prefs_file"
            grep -n -E "(homepage|startup|search)" "$prefs_file" 2>/dev/null | head -5
        fi
    fi
}

# Function to check for browser hijacking
check_browser_hijacking() {
    print_header "BROWSER HIJACKING DETECTION"
    
    # Check for suspicious browser processes
    print_info "Checking for suspicious browser processes..."
    ps aux | grep -E "(chrome|firefox|safari|edge)" | grep -v grep | while read line; do
        print_info "Browser process: $line"
    done
    
    # Check for suspicious browser arguments
    print_info "Checking for suspicious browser command line arguments..."
    ps aux | grep -E "(chrome|firefox|safari|edge)" | grep -v grep | while read line; do
        if echo "$line" | grep -q -E "(proxy|extension|script|eval)"; then
            print_warning "Suspicious browser arguments: $line"
        fi
    done
}

# Function to check for malicious browser data
check_browser_data() {
    print_header "BROWSER DATA ANALYSIS"
    
    # Check for suspicious downloads
    print_info "Checking Downloads folder..."
    if [ -d ~/Downloads ]; then
        local suspicious_downloads=$(find ~/Downloads -name "*.exe" -o -name "*.scr" -o -name "*.bat" -o -name "*.cmd" -o -name "*.js" -o -name "*.jar" 2>/dev/null)
        if [ -n "$suspicious_downloads" ]; then
            print_warning "Suspicious files in Downloads:"
            echo "$suspicious_downloads"
        fi
    fi
    
    # Check for suspicious browser cache
    print_info "Checking browser cache directories..."
    local cache_dirs=(
        "~/Library/Caches/com.google.Chrome"
        "~/Library/Caches/org.mozilla.firefox"
        "~/Library/Caches/com.apple.Safari"
        "~/Library/Caches/com.microsoft.edgemac"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            print_info "Found cache directory: $cache_dir"
            local cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
            print_info "Cache size: $cache_size"
        fi
    done
}

# Function to check for browser security issues
check_browser_security() {
    print_header "BROWSER SECURITY ANALYSIS"
    
    # Check for suspicious browser extensions
    print_info "Checking for suspicious browser extensions..."
    
    # Chrome extensions
    local chrome_extensions="~/Library/Application Support/Google/Chrome/Default/Extensions"
    if [ -d "$chrome_extensions" ]; then
        print_info "Chrome extensions found:"
        find "$chrome_extensions" -type d -maxdepth 1 | while read ext_dir; do
            if [ "$ext_dir" != "$chrome_extensions" ]; then
                local ext_id=$(basename "$ext_dir")
                print_info "Chrome extension ID: $ext_id"
            fi
        done
    fi
    
    # Firefox extensions
    local firefox_extensions="~/Library/Application Support/Firefox/Profiles"
    if [ -d "$firefox_extensions" ]; then
        print_info "Firefox profiles found:"
        find "$firefox_extensions" -type d -maxdepth 1 | while read profile_dir; do
            if [ "$profile_dir" != "$firefox_extensions" ]; then
                local profile_name=$(basename "$profile_dir")
                print_info "Firefox profile: $profile_name"
            fi
        done
    fi
    
    # Check for suspicious browser settings
    print_info "Checking for suspicious browser settings..."
    
    # Check for proxy settings
    if [ -f ~/Library/Preferences/com.apple.SystemConfiguration/preferences.plist ]; then
        if grep -q -i "proxy" ~/Library/Preferences/com.apple.SystemConfiguration/preferences.plist 2>/dev/null; then
            print_warning "Proxy settings found in system preferences"
        fi
    fi
}

# Main execution
main() {
    print_header "BROWSER PROFILE SECURITY AUDIT"
    echo -e "${PURPLE}Detecting JSON injection attacks and malicious browser modifications${NC}"
    echo ""
    
    # Check different browsers
    check_browser_profiles "Chrome" "~/Library/Application Support/Google/Chrome/Default"
    check_browser_profiles "Firefox" "~/Library/Application Support/Firefox/Profiles"
    check_browser_profiles "Safari" "~/Library/Safari"
    check_browser_profiles "Edge" "~/Library/Application Support/Microsoft Edge/Default"
    
    # Check for browser hijacking
    check_browser_hijacking
    
    # Check browser data
    check_browser_data
    
    # Check browser security
    check_browser_security
    
    print_header "BROWSER SECURITY AUDIT COMPLETE"
    echo -e "${GREEN}✅ Browser security audit completed${NC}"
    echo -e "${YELLOW}⚠️  Review any critical findings above${NC}"
    echo -e "${RED}🚨 JSON injection attacks indicate sophisticated browser compromise${NC}"
    echo ""
    echo -e "${BLUE}📋 Recommendations:${NC}"
    echo "1. Clear all browser data and cache"
    echo "2. Remove suspicious extensions"
    echo "3. Reset browser settings to defaults"
    echo "4. Check for malicious downloads"
    echo "5. Consider browser reinstallation"
    echo "6. Monitor for reinfection"
}

# Run main function
main "$@"
