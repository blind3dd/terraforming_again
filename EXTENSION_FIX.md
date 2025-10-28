# Fix: "command 'go.languageserver.restart' not found"

## 🚨 **Problem**
The error "command 'go.languageserver.restart' not found" means the Go extension isn't installed in Cursor.

## 🔧 **Quick Fix**

### **Step 1: Install Go Extension**
1. **Open Cursor**
2. **Press `Cmd+Shift+P`** (Command Palette)
3. **Type**: `Extensions: Install Extensions`
4. **Search for**: `Go`
5. **Install**: "Go" by Google (golang.go)

### **Step 2: Install Terraform Extension**
1. **In the same Extensions panel**
2. **Search for**: `Terraform`
3. **Install**: "HashiCorp Terraform" (hashicorp.terraform)

### **Step 3: Restart Cursor**
1. **Close Cursor completely**
2. **Reopen Cursor**
3. **Open the project**: `./open-cursor.sh`

## 🧪 **Test After Installation**

### **Test Go**
1. **Open**: `applications/go-mysql-api/conff/config.go`
2. **Check**: Keywords should be colored
3. **Try**: Command Palette → "Go: Restart Language Server" (should work now)

### **Test Terraform**
1. **Open**: `infrastructure/terraform/syntax-test.tf`
2. **Check**: Keywords should be colored
3. **Try**: Command Palette → "Terraform: Restart Language Server"

## 🔍 **If Still Not Working**

1. **Check Extensions Panel**:
   - View → Extensions
   - Verify "Go" and "HashiCorp Terraform" are installed and enabled

2. **Check Output Panel**:
   - View → Output
   - Select "Go" or "Terraform" from dropdown
   - Look for error messages

3. **Reload Window**:
   - Command Palette → "Developer: Reload Window"

## 💡 **Alternative Installation**

If manual installation doesn't work, try:
```bash
# Run the extension installation guide
./hack/install-extensions.sh
```

## ✅ **Success Indicators**

After installing extensions:
- ✅ Go keywords are colored
- ✅ Terraform keywords are colored
- ✅ Command Palette shows "Go: Restart Language Server"
- ✅ Command Palette shows "Terraform: Restart Language Server"
- ✅ IntelliSense/autocomplete works for both languages

The key is that Cursor needs the proper extensions installed to provide language support!


