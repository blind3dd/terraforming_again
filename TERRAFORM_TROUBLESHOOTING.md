# Terraform Extension Troubleshooting Guide

## 🚨 Issue: Terraform Extension Not Working
- No syntax highlighting
- No command-click navigation
- No module resolution
- No IntelliSense/autocomplete

## 🔧 Quick Fixes

### 1. Restart Language Server
```bash
# In VSCode/Cursor Command Palette (Cmd+Shift+P):
Terraform: Restart Language Server
```

### 2. Reload Window
```bash
# In VSCode/Cursor Command Palette (Cmd+Shift+P):
Developer: Reload Window
```

### 3. Check Extensions
Make sure these extensions are installed:
- **HashiCorp Terraform** (hashicorp.terraform)
- **HCL** (hashicorp.hcl)

### 4. Verify Nix Environment
```bash
# Make sure you're in the Nix environment
nix develop --impure

# Check if terraform-ls is available
which terraform-ls
which terraform
```

## 🛠️ Detailed Troubleshooting

### Step 1: Check Language Server Status
1. Open Command Palette (`Cmd+Shift+P`)
2. Type "Terraform: Show Language Server Status"
3. Check if it shows "Running" or any errors

### Step 2: Check Output Panel
1. Open Output panel (`Cmd+Shift+P` → "View: Toggle Output")
2. Select "Terraform" from dropdown
3. Look for error messages

### Step 3: Verify Workspace Settings
Check `.vscode/settings.json` in terraform directory:
```json
{
    "terraform.languageServer": {
        "enabled": true,
        "path": "${workspaceFolder}/.nix/bin/terraform-ls"
    }
}
```

### Step 4: Test with Simple File
1. Open `test-syntax.tf` file
2. Check if syntax highlighting works
3. Try command-click on `aws_s3_bucket.test`

### Step 5: Initialize Terraform
```bash
cd infrastructure/terraform
terraform init -backend=false
```

## 🎯 Module Navigation Issues

### Problem: Can't navigate to modules
**Solution:**
1. Ensure modules have proper `variables.tf` and `outputs.tf`
2. Check module source paths are correct
3. Run `terraform init` to download modules

### Problem: No autocomplete in modules
**Solution:**
1. Check module has proper variable definitions
2. Verify module is properly referenced in main.tf
3. Restart language server

## 🔍 Debug Commands

### Check Terraform Language Server Process
```bash
ps aux | grep terraform-ls
```

### Check Terraform Validation
```bash
cd infrastructure/terraform
terraform validate
```

### Check Module Structure
```bash
find modules -name "*.tf" -type f
```

## 📋 Common Issues & Solutions

### Issue: "terraform-ls not found"
**Solution:**
```bash
nix develop --impure
which terraform-ls
```

### Issue: "No syntax highlighting"
**Solution:**
1. Check file associations in settings
2. Restart VSCode/Cursor
3. Verify Terraform extension is enabled

### Issue: "Module not found"
**Solution:**
1. Check module source path
2. Run `terraform init`
3. Verify module directory exists

### Issue: "No IntelliSense"
**Solution:**
1. Check language server is running
2. Verify workspace settings
3. Restart language server

## 🚀 Final Steps

1. **Open a .tf file** - Should show syntax highlighting
2. **Command-click on resource** - Should navigate to definition
3. **Type `resource "aws_`** - Should show autocomplete
4. **Check Output panel** - Should show no errors

## 📞 If Still Not Working

1. Check VSCode/Cursor version compatibility
2. Try disabling other Terraform extensions
3. Check workspace trust settings
4. Verify file permissions
5. Try opening terraform directory as workspace root

## 🎯 Test Commands

```bash
# Run the initialization script
./hack/init-terraform-ls.sh

# Run the troubleshooting script
./hack/fix-terraform-linting.sh
```



