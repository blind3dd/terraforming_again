package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/blind3dd/database_CI/webhooks/encryption"
)

// ExampleConfig demonstrates the encrypt tag usage
type ExampleConfig struct {
	// Public configuration (not encrypted)
	AppName       string `env:"APP_NAME" default:"my-app" json:"app_name"`
	Port          string `env:"PORT" default:"8080" json:"port"`
	LogLevel      string `env:"LOG_LEVEL" default:"info" json:"log_level"`
	EnableMetrics bool   `env:"ENABLE_METRICS" default:"true" json:"enable_metrics"`

	// Sensitive configuration (encrypted)
	DatabaseURL  string `env:"DATABASE_URL" encrypt:"true" json:"database_url"`
	DatabaseUser string `env:"DATABASE_USER" encrypt:"true" json:"database_user"`
	DatabasePass string `env:"DATABASE_PASS" encrypt:"true" json:"database_pass"`
	APIKey       string `env:"API_KEY" encrypt:"true" json:"api_key"`
	SecretToken  string `env:"SECRET_TOKEN" encrypt:"true" json:"secret_token"`
	JWTSecret    string `env:"JWT_SECRET" encrypt:"true" json:"jwt_secret"`

	// GitHub integration (encrypted)
	GitHubToken   string `env:"GITHUB_TOKEN" encrypt:"true" json:"github_token"`
	GitHubWebhook string `env:"GITHUB_WEBHOOK_SECRET" encrypt:"true" json:"github_webhook_secret"`

	// AWS credentials (encrypted)
	AWSAccessKey    string `env:"AWS_ACCESS_KEY_ID" encrypt:"true" json:"aws_access_key_id"`
	AWSSecretKey    string `env:"AWS_SECRET_ACCESS_KEY" encrypt:"true" json:"aws_secret_access_key"`
	AWSSessionToken string `env:"AWS_SESSION_TOKEN" encrypt:"true" json:"aws_session_token"`
}

func main() {
	// Set up encryption
	encryptionKey := "my-super-secret-encryption-key-12345"
	encryptedEnv := encryption.NewEncryptedEnv(encryptionKey)

	// Load configuration
	config, err := LoadExampleConfig(encryptedEnv)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Validate configuration
	if err := config.Validate(); err != nil {
		log.Fatalf("Configuration validation failed: %v", err)
	}

	// Print configuration (with sensitive data redacted)
	configJSON, _ := config.ToJSON()
	fmt.Printf("Configuration: %s\n", configJSON)

	// Print encrypted fields
	encryptedFields := config.GetEncryptedFields()
	fmt.Printf("Encrypted fields: %v\n", encryptedFields)

	// Print encrypted environment variables
	encryptedEnvVars := config.GetEncryptedEnvVars()
	fmt.Printf("Encrypted environment variables: %v\n", encryptedEnvVars)
}

// LoadExampleConfig loads the example configuration
func LoadExampleConfig(encryptedEnv *encryption.EncryptedEnv) (*ExampleConfig, error) {
	config := &ExampleConfig{}

	// Get the type and value of the config struct
	configType := reflect.TypeOf(config).Elem()
	configValue := reflect.ValueOf(config).Elem()

	// Iterate through each field
	for i := 0; i < configType.NumField(); i++ {
		field := configType.Field(i)
		fieldValue := configValue.Field(i)

		// Get environment variable name
		envName := field.Tag.Get("env")
		if envName == "" {
			continue
		}

		// Get default value
		defaultValue := field.Tag.Get("default")

		// Check if field should be encrypted
		shouldEncrypt := field.Tag.Get("encrypt") == "true"

		var value string
		if shouldEncrypt {
			value = getSecureEnv(envName, defaultValue, encryptedEnv)
		} else {
			value = getEnv(envName, defaultValue)
		}

		// Set the field value based on its type
		if err := setFieldValue(fieldValue, value); err != nil {
			return nil, fmt.Errorf("error setting field %s: %v", field.Name, err)
		}
	}

	return config, nil
}

// ToJSON converts the config to JSON with redacted sensitive fields
func (c *ExampleConfig) ToJSON() (string, error) {
	// Create a copy for JSON serialization (hide sensitive fields)
	configCopy := *c

	// Use reflection to automatically redact all encrypted fields
	configType := reflect.TypeOf(&configCopy).Elem()
	configValue := reflect.ValueOf(&configCopy).Elem()

	for i := 0; i < configType.NumField(); i++ {
		field := configType.Field(i)
		fieldValue := configValue.Field(i)

		// Check if field should be encrypted
		shouldEncrypt := field.Tag.Get("encrypt") == "true"

		if shouldEncrypt && fieldValue.CanSet() && fieldValue.Kind() == reflect.String {
			fieldValue.SetString("***REDACTED***")
		}
	}

	jsonData, err := json.MarshalIndent(configCopy, "", "  ")
	if err != nil {
		return "", err
	}

	return string(jsonData), nil
}

// GetEncryptedFields returns a list of field names that are marked for encryption
func (c *ExampleConfig) GetEncryptedFields() []string {
	var encryptedFields []string

	configType := reflect.TypeOf(c).Elem()

	for i := 0; i < configType.NumField(); i++ {
		field := configType.Field(i)

		// Check if field should be encrypted
		shouldEncrypt := field.Tag.Get("encrypt") == "true"

		if shouldEncrypt {
			encryptedFields = append(encryptedFields, field.Name)
		}
	}

	return encryptedFields
}

// GetEncryptedEnvVars returns a map of environment variable names to field names for encrypted fields
func (c *ExampleConfig) GetEncryptedEnvVars() map[string]string {
	encryptedEnvVars := make(map[string]string)

	configType := reflect.TypeOf(c).Elem()

	for i := 0; i < configType.NumField(); i++ {
		field := configType.Field(i)

		// Get environment variable name
		envName := field.Tag.Get("env")
		if envName == "" {
			continue
		}

		// Check if field should be encrypted
		shouldEncrypt := field.Tag.Get("encrypt") == "true"

		if shouldEncrypt {
			encryptedEnvVars[envName] = field.Name
		}
	}

	return encryptedEnvVars
}

// Validate validates the configuration
func (c *ExampleConfig) Validate() error {
	// Add your validation logic here
	if c.DatabaseURL == "" {
		return fmt.Errorf("DATABASE_URL is required")
	}

	if c.APIKey == "" {
		return fmt.Errorf("API_KEY is required")
	}

	return nil
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
			fmt.Printf("Warning: Failed to decrypt %s with ENC: prefix: %v\n", key, err)
			return defaultValue
		}
		return decrypted
	}

	// Method 2: Try to decrypt without marker (backward compatibility)
	decrypted, err := encryptedEnv.Decrypt(encryptedValue)
	if err != nil {
		// If decryption fails, assume it's plaintext
		fmt.Printf("Info: %s appears to be plaintext (decryption failed: %v)\n", key, err)
		return encryptedValue
	}

	// Decryption succeeded, return decrypted value
	return decrypted
}

// setFieldValue sets a field value based on its type
func setFieldValue(fieldValue reflect.Value, value string) error {
	if !fieldValue.CanSet() {
		return fmt.Errorf("field cannot be set")
	}

	switch fieldValue.Kind() {
	case reflect.String:
		fieldValue.SetString(value)

	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		if value == "" {
			fieldValue.SetInt(0)
		} else {
			intVal, err := strconv.ParseInt(value, 10, 64)
			if err != nil {
				return fmt.Errorf("invalid integer value: %s", value)
			}
			fieldValue.SetInt(intVal)
		}

	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		if value == "" {
			fieldValue.SetUint(0)
		} else {
			uintVal, err := strconv.ParseUint(value, 10, 64)
			if err != nil {
				return fmt.Errorf("invalid unsigned integer value: %s", value)
			}
			fieldValue.SetUint(uintVal)
		}

	case reflect.Float32, reflect.Float64:
		if value == "" {
			fieldValue.SetFloat(0.0)
		} else {
			floatVal, err := strconv.ParseFloat(value, 64)
			if err != nil {
				return fmt.Errorf("invalid float value: %s", value)
			}
			fieldValue.SetFloat(floatVal)
		}

	case reflect.Bool:
		if value == "" {
			fieldValue.SetBool(false)
		} else {
			boolVal, err := strconv.ParseBool(strings.ToLower(value))
			if err != nil {
				return fmt.Errorf("invalid boolean value: %s", value)
			}
			fieldValue.SetBool(boolVal)
		}

	case reflect.Slice:
		// Handle slice types (e.g., []string)
		if fieldValue.Type().Elem().Kind() == reflect.String {
			if value == "" {
				fieldValue.Set(reflect.MakeSlice(fieldValue.Type(), 0, 0))
			} else {
				// Split by comma for comma-separated values
				parts := strings.Split(value, ",")
				slice := reflect.MakeSlice(fieldValue.Type(), len(parts), len(parts))
				for i, part := range parts {
					slice.Index(i).SetString(strings.TrimSpace(part))
				}
				fieldValue.Set(slice)
			}
		} else {
			return fmt.Errorf("unsupported slice element type: %v", fieldValue.Type().Elem().Kind())
		}

	default:
		return fmt.Errorf("unsupported field type: %v", fieldValue.Kind())
	}

	return nil
}
