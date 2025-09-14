package encryption

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"strings"
)

// EncryptedEnv represents an encrypted environment variable
type EncryptedEnv struct {
	key []byte
}

// NewEncryptedEnv creates a new encrypted environment handler
func NewEncryptedEnv(encryptionKey string) *EncryptedEnv {
	// Derive a 32-byte key from the provided key using SHA256
	hash := sha256.Sum256([]byte(encryptionKey))
	return &EncryptedEnv{key: hash[:]}
}

// Encrypt encrypts a plaintext string using AES-GCM
func (e *EncryptedEnv) Encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(e.key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// AES-GCM nonce must be exactly 12 bytes (96 bits)
	// This is the standard nonce size for AES-GCM
	const nonceSize = 12
	nonce := make([]byte, nonceSize, nonceSize) // explicit length and capacity

	// Fill nonce with cryptographically secure random bytes
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("failed to generate random nonce: %v", err)
	}

	// Seal the plaintext with the nonce
	// The nonce is prepended to the ciphertext
	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts an encrypted string using AES-GCM
func (e *EncryptedEnv) Decrypt(encryptedData string) (string, error) {
	// Sanitize the base64 string to handle common issues
	encryptedData = sanitizeBase64(encryptedData)

	data, err := base64.StdEncoding.DecodeString(encryptedData)
	if err != nil {
		return "", fmt.Errorf("failed to decode base64: %v", err)
	}

	block, err := aes.NewCipher(e.key)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %v", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %v", err)
	}

	// AES-GCM nonce must be exactly 12 bytes (96 bits)
	const nonceSize = 12
	if len(data) < nonceSize {
		return "", fmt.Errorf("ciphertext too short: %d bytes (minimum %d)", len(data), nonceSize)
	}

	// Extract nonce and ciphertext
	nonce := data[:nonceSize]
	ciphertext := data[nonceSize:]

	// Decrypt the ciphertext
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt: %v", err)
	}

	return string(plaintext), nil
}

// sanitizeBase64 handles common base64 encoding issues
func sanitizeBase64(data string) string {
	// Remove whitespace and newlines
	data = strings.ReplaceAll(data, " ", "")
	data = strings.ReplaceAll(data, "\n", "")
	data = strings.ReplaceAll(data, "\r", "")
	data = strings.ReplaceAll(data, "\t", "")

	// Handle URL encoding (% character)
	data = strings.ReplaceAll(data, "%", "")

	// Ensure proper padding
	for len(data)%4 != 0 {
		data += "="
	}

	return data
}
