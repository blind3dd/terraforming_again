package main

import (
	"fmt"
	"os"

	"github.com/blind3dd/database_CI/webhooks/encryption"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: go run encrypt-env.go <encryption-key> <plaintext-value>")
		fmt.Println("Example: go run encrypt-env.go 'my-secret-key' 'ghp_xxxxxxxxxxxx'")
		os.Exit(1)
	}

	encryptionKey := os.Args[1]
	plaintext := os.Args[2]

	encryptedEnv := encryption.NewEncryptedEnv(encryptionKey)
	encrypted, err := encryptedEnv.Encrypt(plaintext)
	if err != nil {
		fmt.Printf("Error encrypting value: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Encrypted value: %s\n", encrypted)
	fmt.Printf("Encrypted value with ENC: prefix: ENC:%s\n", encrypted)
	fmt.Printf("\nTo use this in your environment:\n")
	fmt.Printf("export ENCRYPTION_KEY='%s'\n", encryptionKey)
	fmt.Printf("export GITHUB_TOKEN='ENC:%s'\n", encrypted)
	fmt.Printf("# OR without prefix (backward compatibility):\n")
	fmt.Printf("export GITHUB_TOKEN='%s'\n", encrypted)
}
