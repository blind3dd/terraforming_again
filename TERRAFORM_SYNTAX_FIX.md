# Terraform Syntax Highlighting Fix

## 🚨 Problem: No Terraform Syntax Highlighting
- Terraform files show as plain text
- No IntelliSense/autocomplete
- No command-click navigation
- Language server not working

## 🔧 Solution: Nix Environment Integration

### **Root Cause**
VSCode/Cursor needs to run with the Nix environment to access `terraform-ls` and other Terraform tools.

### **Quick Fix**

1. **Close VSCode/Cursor completely**
2. **Run the launch script**:
   ```bash
   ./hack/launch-vscode-with-nix.sh
   ```
3. **Open a Terraform file** (e.g., `syntax-test.tf`)
4. **Check syntax highlighting**

### **Manual Fix**

1. **Activate Nix environment**:
   ```bash
   nix develop --impure
   ```

2. **Launch VSCode/Cursor from terminal**:
   ```bash
   code .  # or cursor .
   ```

3. **Restart Terraform language server**:
   - Command Palette (`Cmd+Shift+P`)
   - "Terraform: Restart Language Server"

## 🎯 **Verification Steps**

### **Test 1: Syntax Highlighting**
1. Open `infrastructure/terraform/syntax-test.tf`
2. Check if keywords are colored:
   - `terraform` (blue)
   - `resource` (purple)
   - `data` (orange)
   - `output` (green)

### **Test 2: IntelliSense**
1. Type `resource "aws_`
2. Should show autocomplete suggestions
3. Should show resource documentation

### **Test 3: Command-Click Navigation**
1. Click on `aws_s3_bucket.test` in output
2. Should navigate to resource definition
3. Should show "Go to Definition" option

### **Test 4: Module Navigation**
1. Open `environments/dev/main.tf`
2. Command-click on `module.networking`
3. Should navigate to module definition

## 🔍 **Troubleshooting**

### **Issue: Still no syntax highlighting**
**Solution:**
1. Check Output panel → "Terraform" for errors
2. Verify HashiCorp Terraform extension is installed
3. Restart VSCode/Cursor completely
4. Run `./hack/launch-vscode-with-nix.sh`

### **Issue: Language server not starting**
**Solution:**
1. Check if `terraform-ls` is available:
   ```bash
   nix develop --impure --command which terraform-ls
   ```
2. Verify VSCode settings in `.vscode/settings.json`
3. Check workspace trust settings

### **Issue: Module resolution not working**
**Solution:**
1. Run `terraform init` in environment directory
2. Check module source paths are correct
3. Verify module has proper `variables.tf` and `outputs.tf`

## 📋 **Required Extensions**

Make sure these extensions are installed:
- **HashiCorp Terraform** (`hashicorp.terraform`)
- **HCL** (`hashicorp.hcl`)

## 🚀 **Final Steps**

1. **Test with simple file**: Open `syntax-test.tf`
2. **Test with module**: Open `environments/dev/main.tf`
3. **Test command-click**: Click on module references
4. **Test autocomplete**: Type `resource "aws_`

## 💡 **Pro Tips**

- Always launch VSCode/Cursor from the Nix environment
- Use the wrapper script for consistent results
- Check Output panel for language server logs
- Restart language server if issues persist

## 🎯 **Success Indicators**

✅ Terraform keywords are colored  
✅ IntelliSense shows suggestions  
✅ Command-click navigates to definitions  
✅ Module references are clickable  
✅ Validation errors are highlighted  
✅ Format on save works  

If all these work, Terraform integration is properly configured!



