#!/bin/bash

# Kubernetes API Compatibility Checker
# This script checks if Kustomize and Helm configurations use compatible API versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KUBERNETES_VERSION=${KUBERNETES_VERSION:-"1.28"}
CHART_PATH="go-mysql-api/chart"
KUSTOMIZE_PATH="kustomize"
HELMFILE_PATH="helmfile"

# API Version mappings for different Kubernetes versions
declare -A API_VERSIONS=(
    ["1.28"]="apps/v1,networking.k8s.io/v1,autoscaling/v2,policy/v1"
    ["1.27"]="apps/v1,networking.k8s.io/v1,autoscaling/v2,policy/v1"
    ["1.26"]="apps/v1,networking.k8s.io/v1,autoscaling/v2,policy/v1"
    ["1.25"]="apps/v1,networking.k8s.io/v1,autoscaling/v2,policy/v1"
)

# Deprecated API versions that should trigger chart version updates
declare -A DEPRECATED_APIS=(
    ["extensions/v1beta1"]="1.16"
    ["apps/v1beta1"]="1.16"
    ["apps/v1beta2"]="1.16"
    ["networking.k8s.io/v1beta1"]="1.19"
    ["autoscaling/v2beta1"]="1.23"
    ["autoscaling/v2beta2"]="1.23"
    ["policy/v1beta1"]="1.21"
)

echo -e "${BLUE}🔍 Checking Kubernetes API Compatibility${NC}"
echo -e "${BLUE}Target Kubernetes Version: ${KUBERNETES_VERSION}${NC}"
echo ""

# Function to extract API versions from YAML files
extract_api_versions() {
    local path="$1"
    local pattern="apiVersion:"
    
    find "$path" -name "*.yaml" -o -name "*.yml" | xargs grep -h "$pattern" | \
    sed 's/.*apiVersion: *//' | sort | uniq
}

# Function to check if API version is deprecated
check_deprecated_api() {
    local api_version="$1"
    local k8s_version="$2"
    
    for deprecated_api in "${!DEPRECATED_APIS[@]}"; do
        if [[ "$api_version" == "$deprecated_api" ]]; then
            local deprecation_version="${DEPRECATED_APIS[$deprecated_api]}"
            if [[ "$(printf '%s\n' "$deprecation_version" "$k8s_version" | sort -V | head -n1)" == "$deprecation_version" ]]; then
                return 0  # API is deprecated
            fi
        fi
    done
    return 1  # API is not deprecated
}

# Function to get current chart version
get_chart_version() {
    local chart_yaml="$1"
    if [[ -f "$chart_yaml" ]]; then
        grep "^version:" "$chart_yaml" | sed 's/version: *//' | tr -d ' '
    else
        echo "0.0.0"
    fi
}

# Function to increment chart version
increment_chart_version() {
    local current_version="$1"
    local version_type="$2"  # patch, minor, major
    
    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major="${VERSION_PARTS[0]}"
    local minor="${VERSION_PARTS[1]}"
    local patch="${VERSION_PARTS[2]}"
    
    case "$version_type" in
        "major")
            echo "$((major + 1)).0.0"
            ;;
        "minor")
            echo "$major.$((minor + 1)).0"
            ;;
        "patch")
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            echo "$major.$minor.$((patch + 1))"
            ;;
    esac
}

# Main compatibility check
main() {
    local issues_found=0
    local chart_version_update_needed=false
    
    echo -e "${BLUE}📋 Extracting API versions from configurations...${NC}"
    
    # Extract API versions from Kustomize
    echo -e "${YELLOW}Kustomize API versions:${NC}"
    local kustomize_apis=$(extract_api_versions "$KUSTOMIZE_PATH")
    echo "$kustomize_apis"
    echo ""
    
    # Extract API versions from Helm charts
    echo -e "${YELLOW}Helm Chart API versions:${NC}"
    local helm_apis=$(extract_api_versions "$CHART_PATH")
    echo "$helm_apis"
    echo ""
    
    # Check for deprecated APIs
    echo -e "${BLUE}🔍 Checking for deprecated API versions...${NC}"
    
    local all_apis=$(echo -e "$kustomize_apis\n$helm_apis" | sort | uniq)
    
    while IFS= read -r api_version; do
        if [[ -n "$api_version" ]]; then
            if check_deprecated_api "$api_version" "$KUBERNETES_VERSION"; then
                echo -e "${RED}❌ Deprecated API found: $api_version${NC}"
                issues_found=$((issues_found + 1))
                chart_version_update_needed=true
            else
                echo -e "${GREEN}✅ API version OK: $api_version${NC}"
            fi
        fi
    done <<< "$all_apis"
    
    echo ""
    
    # Check for API version mismatches between Kustomize and Helm
    echo -e "${BLUE}🔍 Checking for API version mismatches...${NC}"
    
    local kustomize_apis_array=($(echo "$kustomize_apis"))
    local helm_apis_array=($(echo "$helm_apis"))
    
    for kustomize_api in "${kustomize_apis_array[@]}"; do
        if [[ -n "$kustomize_api" ]]; then
            local found=false
            for helm_api in "${helm_apis_array[@]}"; do
                if [[ "$kustomize_api" == "$helm_api" ]]; then
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == false ]]; then
                echo -e "${YELLOW}⚠️  API version in Kustomize but not in Helm: $kustomize_api${NC}"
                issues_found=$((issues_found + 1))
            fi
        fi
    done
    
    echo ""
    
    # Check Chart.yaml version
    echo -e "${BLUE}📊 Checking Chart.yaml version...${NC}"
    local current_chart_version=$(get_chart_version "$CHART_PATH/Chart.yaml")
    echo -e "${YELLOW}Current Chart version: $current_chart_version${NC}"
    
    if [[ "$chart_version_update_needed" == true ]]; then
        local new_version=$(increment_chart_version "$current_chart_version" "minor")
        echo -e "${RED}🔄 Chart version update needed: $current_chart_version → $new_version${NC}"
        echo -e "${YELLOW}Reason: Deprecated API versions detected${NC}"
        
        # Update Chart.yaml if requested
        if [[ "${UPDATE_CHART_VERSION:-false}" == "true" ]]; then
            echo -e "${BLUE}📝 Updating Chart.yaml version...${NC}"
            sed -i "s/^version: .*/version: $new_version/" "$CHART_PATH/Chart.yaml"
            echo -e "${GREEN}✅ Chart.yaml updated to version $new_version${NC}"
        fi
    else
        echo -e "${GREEN}✅ Chart version is up to date${NC}"
    fi
    
    echo ""
    
    # Summary
    echo -e "${BLUE}📋 Compatibility Check Summary${NC}"
    echo -e "${BLUE}==============================${NC}"
    
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✅ All API versions are compatible${NC}"
        echo -e "${GREEN}✅ No chart version update needed${NC}"
        exit 0
    else
        echo -e "${RED}❌ Found $issues_found compatibility issues${NC}"
        if [[ "$chart_version_update_needed" == true ]]; then
            echo -e "${YELLOW}🔄 Chart version update recommended${NC}"
        fi
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Kubernetes API Compatibility Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -k, --k8s-version VERSION    Target Kubernetes version (default: 1.28)"
    echo "  -u, --update-chart          Update Chart.yaml version if needed"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  KUBERNETES_VERSION          Target Kubernetes version"
    echo "  UPDATE_CHART_VERSION        Set to 'true' to update Chart.yaml"
    echo ""
    echo "Examples:"
    echo "  $0                          # Check compatibility"
    echo "  $0 -k 1.27                  # Check for Kubernetes 1.27"
    echo "  $0 -u                       # Check and update Chart.yaml"
    echo "  UPDATE_CHART_VERSION=true $0 # Check and update Chart.yaml"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--k8s-version)
            KUBERNETES_VERSION="$2"
            shift 2
            ;;
        -u|--update-chart)
            UPDATE_CHART_VERSION="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main

