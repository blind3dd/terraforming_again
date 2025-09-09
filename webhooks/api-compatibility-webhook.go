package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	
	"github.com/blind3dd/database_CI/webhooks/encryption"
	"github.com/google/uuid"
	// "github.com/gorilla/mux" // Commented out - using standard http mux
)

// WebhookPayload represents the incoming webhook payload
type WebhookPayload struct {
	Event      string            `json:"event"`
	Repository string            `json:"repository"`
	Branch     string            `json:"branch"`
	Commit     string            `json:"commit"`
	Files      []string          `json:"files"`
	Metadata   map[string]string `json:"metadata"`
}

// APICompatibilityRequest represents the API compatibility check request
type APICompatibilityRequest struct {
	KubernetesVersion string   `json:"kubernetes_version"`
	ForceUpdate       bool     `json:"force_update"`
	Files             []string `json:"files"`
	Repository        string   `json:"repository"`
	Branch            string   `json:"branch"`
}

// APICompatibilityResponse represents the response from the compatibility check
type APICompatibilityResponse struct {
	Success             bool     `json:"success"`
	ChartVersion        string   `json:"chart_version"`
	NewChartVersion     string   `json:"new_chart_version,omitempty"`
	APIVersions         []string `json:"api_versions"`
	DeprecatedAPIs      []string `json:"deprecated_apis"`
	CompatibilityIssues []string `json:"compatibility_issues"`
	Message             string   `json:"message"`
	Timestamp           string   `json:"timestamp"`
}

// Config holds the webhook configuration
type Config struct {
	Port              string
	GitHubToken       string
	Repository        string
	WorkingDir        string
	KubernetesVersion string
}

var config Config
var encryptedEnv *encryption.EncryptedEnv

// Context key for request ID
type contextKey string

const (
	RequestIDKey contextKey = "requestID"
)

func main() {
	// Initialize encrypted environment handler
	encryptionKey := getEnv("ENCRYPTION_KEY", "default-webhook-encryption-key-change-in-production")
	encryptedEnv = encryption.NewEncryptedEnv(encryptionKey)

	// Check if we should use Carlos-style configuration
	useCarlosConfig := getEnv("USE_CARLOS_CONFIG", "false") == "true"

	if useCarlosConfig {
		// Load Carlos-style configuration
		carlosConfig, err := LoadCarlosConfig(encryptedEnv)
		if err != nil {
			log.Fatalf("Failed to load Carlos configuration: %v", err)
		}

		// Validate configuration
		if err := carlosConfig.Validate(); err != nil {
			log.Fatalf("Configuration validation failed: %v", err)
		}

		// Convert to legacy config format
		config = Config{
			Port:              carlosConfig.Port,
			GitHubToken:       carlosConfig.GitHubToken,
			Repository:        carlosConfig.Repository,
			WorkingDir:        carlosConfig.WorkingDir,
			KubernetesVersion: carlosConfig.KubernetesVersion,
		}

		// Log configuration (with sensitive data redacted)
		configJSON, _ := carlosConfig.ToJSON()
		log.Printf("Loaded Carlos configuration: %s", configJSON)

		// Log encrypted fields for debugging
		encryptedFields := carlosConfig.GetEncryptedFields()
		encryptedEnvVars := carlosConfig.GetEncryptedEnvVars()
		log.Printf("Encrypted fields: %v", encryptedFields)
		log.Printf("Encrypted environment variables: %v", encryptedEnvVars)
	} else {
		// Load legacy configuration
		config = Config{
			Port:              getEnv("PORT", "8080"),
			GitHubToken:       getSecureEnv("GITHUB_TOKEN", "", encryptedEnv),
			Repository:        getEnv("REPOSITORY", "blind3dd/database_CI"),
			WorkingDir:        getEnv("WORKING_DIR", "/tmp/webhook-workspace"),
			KubernetesVersion: getEnv("KUBERNETES_VERSION", "1.31"),
		}
	}

	// Validate configuration
	if config.GitHubToken == "" {
		log.Fatal("GITHUB_TOKEN is required")
	}

	// Create working directory if it doesn't exist
	if err := os.MkdirAll(config.WorkingDir, 0755); err != nil {
		log.Fatalf("Failed to create working directory: %v", err)
	}

	// Setup HTTP routes
	mux := http.NewServeMux()
	mux.HandleFunc("/webhook", webhookHandler)
	mux.HandleFunc("/api/compatibility", apiCompatibilityHandler)
	mux.HandleFunc("/health", healthHandler)

	// Apply middleware chain
	handler := requestIDMiddleware(corsMiddleware(mux))

	log.Printf("Starting webhook server on port %s", config.Port)
	log.Printf("Repository: %s", config.Repository)
	log.Printf("Kubernetes Version: %s", config.KubernetesVersion)
	log.Printf("Working Directory: %s", config.WorkingDir)

	if err := http.ListenAndServe(":"+config.Port, handler); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

// generateRequestID creates a unique request ID with date prefix
func generateRequestID() string {
	date := time.Now().Format("20060102")  // YYYYMMDD format
	id := uuid.New().String()[:8]          // First 8 chars of UUID
	return fmt.Sprintf("%s-%s", date, id)  // 20241201-a1b2c3d4
}

// requestIDMiddleware adds request ID to context and logs
func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Generate or extract request ID
		requestID := r.Header.Get("X-Request-ID")
		if requestID == "" {
			requestID = generateRequestID()
		}
		
		// Add to context
		ctx := context.WithValue(r.Context(), RequestIDKey, requestID)
		r = r.WithContext(ctx)
		
		// Add to response headers
		w.Header().Set("X-Request-ID", requestID)
		
		// Log request start
		logWithRequestID(ctx, "INFO", "%s %s - Request started", r.Method, r.URL.Path)
		
		// Call next handler
		next.ServeHTTP(w, r)
		
		// Log request completion
		logWithRequestID(ctx, "INFO", "%s %s - Request completed", r.Method, r.URL.Path)
	})
}

// logWithRequestID logs a message with request ID from context
func logWithRequestID(ctx context.Context, level, message string, args ...interface{}) {
	requestID := ctx.Value(RequestIDKey)
	if requestID != nil {
		log.Printf("[%s] %s: %s", requestID, level, fmt.Sprintf(message, args...))
	} else {
		log.Printf("%s: %s", level, fmt.Sprintf(message, args...))
	}
}

// logInfo logs an info message with request ID
func logInfo(ctx context.Context, message string, args ...interface{}) {
	logWithRequestID(ctx, "INFO", message, args...)
}

// logError logs an error message with request ID
func logError(ctx context.Context, message string, args ...interface{}) {
	logWithRequestID(ctx, "ERROR", message, args...)
}

// logDebug logs a debug message with request ID
func logDebug(ctx context.Context, message string, args ...interface{}) {
	logWithRequestID(ctx, "DEBUG", message, args...)
}

// CORS middleware
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// webhookHandler handles incoming webhook requests
func webhookHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	if r.Method != http.MethodPost {
		logError(ctx, "Method not allowed: %s", r.Method)
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload WebhookPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		logError(ctx, "Invalid JSON payload: %v", err)
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	logInfo(ctx, "Received webhook: %s for repository %s", payload.Event, payload.Repository)

	// Process the webhook
	response := processWebhook(ctx, payload)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	
	logInfo(ctx, "Webhook processed successfully")
}

// apiCompatibilityHandler handles API compatibility check requests
func apiCompatibilityHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var request APICompatibilityRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid JSON request", http.StatusBadRequest)
		return
	}

	log.Printf("API compatibility check requested for version %s", request.KubernetesVersion)

	// Perform compatibility check
	response := checkAPICompatibility(request)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// healthHandler provides health check endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":    "healthy",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

// processWebhook processes incoming webhook events
func processWebhook(ctx context.Context, payload WebhookPayload) map[string]interface{} {
	response := map[string]interface{}{
		"success":   true,
		"message":   "Webhook processed successfully",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	// Check if any Kubernetes-related files were changed
	kubernetesFiles := []string{
		"kustomization.yaml",
		"kustomization.yml",
		"Chart.yaml",
		"values.yaml",
		"deployment.yaml",
		"service.yaml",
		"ingress.yaml",
	}

	hasKubernetesChanges := false
	for _, file := range payload.Files {
		for _, k8sFile := range kubernetesFiles {
			if strings.Contains(file, k8sFile) {
				hasKubernetesChanges = true
				break
			}
		}
		if hasKubernetesChanges {
			break
		}
	}

	if hasKubernetesChanges {
		log.Printf("Kubernetes files detected in changes, triggering API compatibility check")

		// Trigger API compatibility check
		request := APICompatibilityRequest{
			KubernetesVersion: config.KubernetesVersion,
			ForceUpdate:       false,
			Files:             payload.Files,
			Repository:        payload.Repository,
			Branch:            payload.Branch,
		}

		compatibilityResponse := checkAPICompatibility(request)
		response["compatibility_check"] = compatibilityResponse
	}

	return response
}

// checkAPICompatibility performs API compatibility checks
func checkAPICompatibility(request APICompatibilityRequest) APICompatibilityResponse {
	response := APICompatibilityResponse{
		Success:             false,
		ChartVersion:        "",
		APIVersions:         []string{},
		DeprecatedAPIs:      []string{},
		CompatibilityIssues: []string{},
		Message:             "",
		Timestamp:           time.Now().Format(time.RFC3339),
	}

	// Clone or update repository
	repoPath := filepath.Join(config.WorkingDir, "repo")
	if err := cloneOrUpdateRepo(repoPath, request.Repository, request.Branch); err != nil {
		response.Message = fmt.Sprintf("Failed to clone/update repository: %v", err)
		return response
	}

	// Check for Chart.yaml files
	chartFiles, err := findChartFiles(repoPath)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to find Chart.yaml files: %v", err)
		return response
	}

	if len(chartFiles) == 0 {
		response.Message = "No Chart.yaml files found"
		response.Success = true
		return response
	}

	// Process each Chart.yaml file
	for _, chartFile := range chartFiles {
		chartVersion, err := getChartVersion(chartFile)
		if err != nil {
			response.CompatibilityIssues = append(response.CompatibilityIssues,
				fmt.Sprintf("Failed to read Chart.yaml version: %v", err))
			continue
		}

		if response.ChartVersion == "" {
			response.ChartVersion = chartVersion
		}

		// Check API versions in the chart directory
		chartDir := filepath.Dir(chartFile)
		apiVersions, deprecatedAPIs, err := checkAPIVersions(chartDir, request.KubernetesVersion)
		if err != nil {
			response.CompatibilityIssues = append(response.CompatibilityIssues,
				fmt.Sprintf("Failed to check API versions: %v", err))
			continue
		}

		response.APIVersions = append(response.APIVersions, apiVersions...)
		response.DeprecatedAPIs = append(response.DeprecatedAPIs, deprecatedAPIs...)

		// Update Chart.yaml version if needed
		if len(deprecatedAPIs) > 0 || request.ForceUpdate {
			newVersion, err := updateChartVersion(chartFile, chartVersion)
			if err != nil {
				response.CompatibilityIssues = append(response.CompatibilityIssues,
					fmt.Sprintf("Failed to update Chart.yaml version: %v", err))
				continue
			}
			response.NewChartVersion = newVersion
		}
	}

	// Remove duplicates
	response.APIVersions = removeDuplicates(response.APIVersions)
	response.DeprecatedAPIs = removeDuplicates(response.DeprecatedAPIs)

	if len(response.CompatibilityIssues) == 0 {
		response.Success = true
		if len(response.DeprecatedAPIs) == 0 {
			response.Message = "All API versions are compatible"
		} else {
			response.Message = fmt.Sprintf("Found %d deprecated APIs, Chart.yaml version updated", len(response.DeprecatedAPIs))
		}
	} else {
		response.Message = fmt.Sprintf("Found %d compatibility issues", len(response.CompatibilityIssues))
	}

	return response
}

// cloneOrUpdateRepo clones or updates the repository
func cloneOrUpdateRepo(repoPath, repository, branch string) error {
	// Check if repository already exists
	if _, err := os.Stat(repoPath); os.IsNotExist(err) {
		// Clone repository
		cloneCmd := exec.Command("git", "clone",
			fmt.Sprintf("https://%s@github.com/%s.git", config.GitHubToken, repository),
			repoPath)
		cloneCmd.Env = append(os.Environ(), fmt.Sprintf("GITHUB_TOKEN=%s", config.GitHubToken))

		if err := cloneCmd.Run(); err != nil {
			return fmt.Errorf("failed to clone repository: %v", err)
		}
	} else {
		// Update existing repository
		pullCmd := exec.Command("git", "pull", "origin", branch)
		pullCmd.Dir = repoPath
		pullCmd.Env = append(os.Environ(), fmt.Sprintf("GITHUB_TOKEN=%s", config.GitHubToken))

		if err := pullCmd.Run(); err != nil {
			return fmt.Errorf("failed to pull latest changes: %v", err)
		}
	}

	// Checkout the specified branch
	checkoutCmd := exec.Command("git", "checkout", branch)
	checkoutCmd.Dir = repoPath

	if err := checkoutCmd.Run(); err != nil {
		return fmt.Errorf("failed to checkout branch %s: %v", branch, err)
	}

	return nil
}

// findChartFiles finds all Chart.yaml files in the repository
func findChartFiles(repoPath string) ([]string, error) {
	var chartFiles []string

	err := filepath.Walk(repoPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.Name() == "Chart.yaml" {
			chartFiles = append(chartFiles, path)
		}

		return nil
	})

	return chartFiles, err
}

// getChartVersion extracts the version from Chart.yaml
func getChartVersion(chartFile string) (string, error) {
	data, err := os.ReadFile(chartFile)
	if err != nil {
		return "", err
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "version:") {
			parts := strings.Split(line, ":")
			if len(parts) >= 2 {
				return strings.TrimSpace(parts[1]), nil
			}
		}
	}

	return "", fmt.Errorf("version not found in Chart.yaml")
}

// checkAPIVersions checks API versions in the chart directory
func checkAPIVersions(chartDir, kubernetesVersion string) ([]string, []string, error) {
	var apiVersions []string
	var deprecatedAPIs []string

	// Run the API compatibility check script
	scriptPath := filepath.Join(filepath.Dir(chartDir), "..", "..", "scripts", "check-api-compatibility.sh")

	cmd := exec.Command("bash", scriptPath, chartDir, kubernetesVersion)
	output, err := cmd.Output()
	if err != nil {
		return nil, nil, fmt.Errorf("API compatibility check failed: %v", err)
	}

	// Parse output to extract API versions and deprecated APIs
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "API_VERSION:") {
			apiVersions = append(apiVersions, strings.TrimPrefix(line, "API_VERSION:"))
		} else if strings.HasPrefix(line, "DEPRECATED:") {
			deprecatedAPIs = append(deprecatedAPIs, strings.TrimPrefix(line, "DEPRECATED:"))
		}
	}

	return apiVersions, deprecatedAPIs, nil
}

// updateChartVersion updates the Chart.yaml version
func updateChartVersion(chartFile, currentVersion string) (string, error) {
	// Parse current version (assuming semantic versioning)
	parts := strings.Split(currentVersion, ".")
	if len(parts) < 3 {
		return "", fmt.Errorf("invalid version format: %s", currentVersion)
	}

	// Increment patch version
	patch, err := strconv.Atoi(parts[2])
	if err != nil {
		return "", fmt.Errorf("invalid patch version: %s", parts[2])
	}

	newVersion := fmt.Sprintf("%s.%s.%d", parts[0], parts[1], patch+1)

	// Read the file
	data, err := os.ReadFile(chartFile)
	if err != nil {
		return "", err
	}

	// Replace version line
	lines := strings.Split(string(data), "\n")
	for i, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "version:") {
			lines[i] = fmt.Sprintf("version: %s", newVersion)
			break
		}
	}

	// Write back to file
	newData := strings.Join(lines, "\n")
	if err := os.WriteFile(chartFile, []byte(newData), 0644); err != nil {
		return "", err
	}

	return newVersion, nil
}

// removeDuplicates removes duplicate strings from a slice
func removeDuplicates(slice []string) []string {
	keys := make(map[string]bool)
	var result []string

	for _, item := range slice {
		if !keys[item] {
			keys[item] = true
			result = append(result, item)
		}
	}

	return result
}

// getEnv gets an environment variable with a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getSecureEnv gets an encrypted environment variable and decrypts it
func getSecureEnv(key, defaultValue string, encryptedEnv *encryption.EncryptedEnv) string {
	encryptedValue := os.Getenv(key)
	if encryptedValue == "" {
		return defaultValue
	}

	// Method 1: Check for explicit encryption marker
	if strings.HasPrefix(encryptedValue, "ENC:") {
		// Remove the ENC: prefix and decrypt
		encryptedData := strings.TrimPrefix(encryptedValue, "ENC:")
		decrypted, err := encryptedEnv.Decrypt(encryptedData)
		if err != nil {
			log.Printf("Warning: Failed to decrypt %s with ENC: prefix: %v", key, err)
			return defaultValue
		}
		return decrypted
	}

	// Method 2: Try to decrypt without marker (backward compatibility)
	decrypted, err := encryptedEnv.Decrypt(encryptedValue)
	if err != nil {
		// If decryption fails, assume it's plaintext
		log.Printf("Info: %s appears to be plaintext (decryption failed: %v)", key, err)
		return encryptedValue
	}

	// Decryption succeeded, return decrypted value
	return decrypted
}
