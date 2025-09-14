package main

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/blind3dd/database_CI/webhooks/encryption"
)

// CarlosConfig represents a structured configuration using Carlos-style reflection
type CarlosConfig struct {
	// Basic configuration
	Port              string `env:"PORT" default:"8080" json:"port"`
	GitHubToken       string `env:"GITHUB_TOKEN" encrypt:"true" json:"github_token"`
	Repository        string `env:"REPOSITORY" default:"blind3dd/database_CI" json:"repository"`
	WorkingDir        string `env:"WORKING_DIR" default:"/tmp/webhook-workspace" json:"working_dir"`
	KubernetesVersion string `env:"KUBERNETES_VERSION" default:"1.31" json:"kubernetes_version"`
	EncryptionKey     string `env:"ENCRYPTION_KEY" encrypt:"true" json:"encryption_key"`

	// Advanced configuration with different types
	LogLevel       string   `env:"LOG_LEVEL" default:"info" json:"log_level"`
	MaxConcurrency int      `env:"MAX_CONCURRENCY" default:"10" json:"max_concurrency"`
	RequestTimeout int32    `env:"REQUEST_TIMEOUT" default:"30" json:"request_timeout"`
	EnableMetrics  bool     `env:"ENABLE_METRICS" default:"true" json:"enable_metrics"`
	MetricsPort    string   `env:"METRICS_PORT" default:"9090" json:"metrics_port"`
	MaxMemoryMB    uint64   `env:"MAX_MEMORY_MB" default:"1024" json:"max_memory_mb"`
	CPUThreshold   float64  `env:"CPU_THRESHOLD" default:"0.8" json:"cpu_threshold"`
	AllowedHosts   []string `env:"ALLOWED_HOSTS" default:"localhost,127.0.0.1" json:"allowed_hosts"`

	// Additional sensitive configuration
	DatabasePassword string `env:"DATABASE_PASSWORD" encrypt:"true" json:"database_password"`
	APIKey           string `env:"API_KEY" encrypt:"true" json:"api_key"`
	SecretToken      string `env:"SECRET_TOKEN" encrypt:"true" json:"secret_token"`
}

// LoadCarlosConfig loads configuration using Carlos-style reflection
func LoadCarlosConfig(encryptedEnv *encryption.EncryptedEnv) (*CarlosConfig, error) {
	config := &CarlosConfig{}

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

// ToJSON converts the config to JSON
func (c *CarlosConfig) ToJSON() (string, error) {
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

// Validate validates the configuration
func (c *CarlosConfig) Validate() error {
	if c.GitHubToken == "" {
		return fmt.Errorf("GITHUB_TOKEN is required")
	}

	if c.Repository == "" {
		return fmt.Errorf("REPOSITORY is required")
	}

	if c.MaxConcurrency <= 0 {
		return fmt.Errorf("MAX_CONCURRENCY must be greater than 0")
	}

	if c.RequestTimeout <= 0 {
		return fmt.Errorf("REQUEST_TIMEOUT must be greater than 0")
	}

	return nil
}

// LoadConfigFromFile loads configuration from a JSON file
func LoadConfigFromFile(filename string) (*CarlosConfig, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config CarlosConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

// SaveConfigToFile saves configuration to a JSON file (with sensitive data redacted)
func (c *CarlosConfig) SaveConfigToFile(filename string) error {
	jsonData, err := c.ToJSON()
	if err != nil {
		return err
	}

	return os.WriteFile(filename, []byte(jsonData), 0644)
}

// GetEncryptedFields returns a list of field names that are marked for encryption
func (c *CarlosConfig) GetEncryptedFields() []string {
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
func (c *CarlosConfig) GetEncryptedEnvVars() map[string]string {
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
