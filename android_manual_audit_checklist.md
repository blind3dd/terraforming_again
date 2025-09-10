# Android Device Manual Security Audit Checklist

## 🚨 CRITICAL: Static Tundra Rootkit Compromise Check

**Date:** $(date)  
**Purpose:** Manual audit of Android device for Static Tundra rootkit compromise and Microsoft app installations

---

## 📱 DEVICE INFORMATION

**Device Model:** _________________  
**Android Version:** _________________  
**Build Number:** _________________  
**Last Security Update:** _________________  

---

## 🔍 MICROSOFT APPS AUDIT

**Check your Android device for these Microsoft apps:**

### ❌ CRITICAL - REMOVE IF FOUND:
- [ ] **Microsoft Edge** (Browser)
- [ ] **Microsoft OneDrive** (Cloud Storage)
- [ ] **Microsoft Office** (Word, Excel, PowerPoint)
- [ ] **Microsoft Teams**
- [ ] **Microsoft Outlook**
- [ ] **Microsoft Authenticator**
- [ ] **Microsoft Intune**
- [ ] **Microsoft Intune Portal**

**If any Microsoft apps are found:**
1. **Uninstall immediately**
2. **Clear app data before uninstalling**
3. **Check for any remaining files in Downloads**

---

## 🔐 AUTHENTICATOR APPS AUDIT

**Check for these authenticator apps:**

### ✅ SAFE TO KEEP:
- [ ] **Google Authenticator**
- [ ] **Authy**
- [ ] **LastPass Authenticator**
- [ ] **1Password Authenticator**
- [ ] **Duo Mobile**
- [ ] **Yubico Authenticator**

**If Microsoft Authenticator is found:**
1. **Export all MFA codes** to another authenticator app
2. **Uninstall Microsoft Authenticator**
3. **Re-import codes to safe authenticator app**

---

## 🌐 NETWORK & SECURITY AUDIT

### Network Settings:
- [ ] **WiFi Networks:** Check for suspicious networks
- [ ] **VPN Settings:** Verify no unauthorized VPNs
- [ ] **Proxy Settings:** Ensure no proxy is configured
- [ ] **DNS Settings:** Check for non-standard DNS servers

### Security Settings:
- [ ] **Screen Lock:** Enabled with strong PIN/Password
- [ ] **Biometric Security:** Fingerprint/Face unlock enabled
- [ ] **Developer Options:** Disabled (unless needed)
- [ ] **USB Debugging:** Disabled (unless needed)
- [ ] **Unknown Sources:** Disabled
- [ ] **Google Play Protect:** Enabled

---

## 📊 SUSPICIOUS ACTIVITY CHECK

### Apps to Investigate:
- [ ] **Unknown apps** you don't remember installing
- [ ] **Apps with excessive permissions**
- [ ] **Apps that can't be uninstalled**
- [ ] **Apps that run in background constantly**

### Network Activity:
- [ ] **High data usage** from unknown apps
- [ ] **Battery drain** from unknown apps
- [ ] **Slow performance** or overheating
- [ ] **Unexpected popups** or ads

---

## 🔧 CLEANUP ACTIONS

### If Microsoft Apps Found:
1. **Uninstall all Microsoft apps**
2. **Clear browser data** (if Microsoft Edge was present)
3. **Check Downloads folder** for Microsoft files
4. **Clear app cache** for all browsers
5. **Reset network settings**

### If Suspicious Activity Found:
1. **Uninstall suspicious apps**
2. **Clear all app data** for removed apps
3. **Reset network settings**
4. **Change all passwords** used on device
5. **Enable 2FA** on all accounts

---

## 📋 POST-CLEANUP VERIFICATION

### After Cleanup:
- [ ] **No Microsoft apps** remain installed
- [ ] **All authenticator apps** are working properly
- [ ] **Network settings** are clean
- [ ] **Device performance** has improved
- [ ] **No unexpected popups** or ads

### Security Improvements:
- [ ] **Screen lock** enabled
- [ ] **Google Play Protect** enabled
- [ ] **Unknown sources** disabled
- [ ] **Developer options** disabled
- [ ] **USB debugging** disabled

---

## 🚨 IMMEDIATE ACTIONS REQUIRED

**If Microsoft apps are found:**
1. **STOP using the device** for sensitive activities
2. **Uninstall Microsoft apps immediately**
3. **Change all passwords** used on the device
4. **Enable 2FA** on all accounts
5. **Monitor for suspicious activity**

**If no Microsoft apps are found:**
1. **Continue monitoring** for 24-48 hours
2. **Check for any re-emerging threats**
3. **Verify iCloud sync** works properly after cleanup

---

## 📞 NEXT STEPS

**After completing this audit:**
1. **Report findings** to security team
2. **Document any Microsoft apps found**
3. **Note any suspicious activity**
4. **Proceed with iCloud sync repair**

**This manual audit is critical for determining if the Static Tundra rootkit has spread to your Android device and is interfering with iCloud sync.**

---

**Audit Completed By:** _________________  
**Date Completed:** _________________  
**Findings Summary:** _________________  
