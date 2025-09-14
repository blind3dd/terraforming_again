# Static Tundra/FSB-linked Rootkit Detection & Removal Toolkit

## Overview
This toolkit is based on a real-world investigation of a sophisticated state-sponsored attack by Static Tundra (FSB-linked) targeting macOS systems. It provides comprehensive detection and removal capabilities for similar rootkit attacks.

## What It Detects
- **Malicious Ansible modules** (Meraki NetFlow, Fortinet Sniffer, Cisco SMB, Inspur capture)
- **Rootkit processes** (diskarbitrationd, diskimagesiod, simdiskimaged)
- **Suspicious network interfaces** (tunnel interfaces, bridge interfaces)
- **Suspicious ports** (8021, 22, 21, 69)
- **Mounted simulators** (iOS simulators with malicious payloads)

## What It Removes
- Malicious Ansible modules
- Rootkit processes
- Suspicious network interfaces
- Mounted simulators
- Blocks suspicious ports with firewall rules

## Usage

### Basic Detection Only
```bash
./rootkit_detection_removal_toolkit.sh
```

### For Intel Macs - NVRAM Reset
1. Power off completely
2. Hold `Command + Option + P + R`
3. Power on while holding keys
4. Hold for 20 seconds (hear startup chime twice)
5. Release keys

### For Apple Silicon (M1/M2/M3) - NVRAM Reset
1. Power off completely
2. Hold power button until "Loading startup options"
3. Hold `Command + Option + P + R`
4. Click "Continue" while holding keys
5. Hold for 20 seconds then release

## Files Created
- `rootkit_audit_YYYYMMDD_HHMMSS.log` - Detailed audit log
- `security_report_YYYYMMDD_HHMMSS.txt` - Summary report

## Attack Timeline
- **Attack Date:** August 27, 2025, 11:48 AM
- **Attack Vector:** Static Tundra (FSB-linked) via Meraki SD-WAN
- **Compromise Level:** Firmware-level rootkit
- **Evidence:** Meraki NetFlow, Fortinet Sniffer, tunnel interfaces

## Critical Indicators
1. **Malicious modules installed simultaneously** (same timestamp)
2. **Tunnel interfaces** (utun0-3) for data exfiltration
3. **Bridge interfaces** for traffic redirection
4. **iOS simulators** with malicious payloads
5. **Core system services** compromised (diskarbitrationd)
6. **Automatic remounting** of attack infrastructure

## Emergency Response
If threats are detected:
1. **DISCONNECT FROM INTERNET** immediately
2. Document all evidence for law enforcement
3. Check all other devices (iPad, iPhone, other computers)
4. Report to FBI, CISA, local law enforcement
5. Consider professional forensic assistance
6. May require hardware replacement for firmware compromise

## Based On Real Investigation
This toolkit is based on actual investigation of:
- Static Tundra FSB-linked attacks
- Meraki SD-WAN exploitation
- NetFlow data collection
- Network traffic redirection
- Persistent firmware-level compromise

## Compatibility
- macOS (Intel and Apple Silicon)
- Requires sudo access for some operations
- Works with System Integrity Protection enabled

## Warning
This is a sophisticated state-sponsored attack that may require professional forensic assistance and potentially hardware replacement if firmware-level compromise is detected.
