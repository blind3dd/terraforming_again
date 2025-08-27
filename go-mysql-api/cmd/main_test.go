package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"goapp_CI/conff"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/gorilla/mux"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Mock database for testing
type MockDB struct {
	users  map[int]*User
	nextID int
}

func NewMockDB() *MockDB {
	return &MockDB{
		users:  make(map[int]*User),
		nextID: 1,
	}
}

func (m *MockDB) Exec(query string, args ...interface{}) (sql.Result, error) {
	// Mock implementation for testing
	return &MockResult{lastInsertID: int64(m.nextID)}, nil
}

func (m *MockDB) Query(query string, args ...interface{}) (*sql.Rows, error) {
	// Mock implementation for testing
	return nil, nil
}

func (m *MockDB) QueryRow(query string, args ...interface{}) *sql.Row {
	// Mock implementation for testing
	return nil
}

func (m *MockDB) Close() error {
	return nil
}

type MockResult struct {
	lastInsertID int64
}

func (m *MockResult) LastInsertId() (int64, error) {
	return m.lastInsertID, nil
}

func (m *MockResult) RowsAffected() (int64, error) {
	return 1, nil
}

// Test setup
func setupTest(t *testing.T) (*httptest.ResponseRecorder, *mux.Router) {
	// Set test environment variables
	os.Setenv("DB_USER", "test_user")
	os.Setenv("DB_PASSWORD", "test_pass")
	os.Setenv("DB_HOST", "localhost")
	os.Setenv("DB_PORT", "3306")
	os.Setenv("DB_NAME", "test_db")
	os.Setenv("SERVER_PORT", "8080")

	router := mux.NewRouter()
	router.HandleFunc("/users", createUser).Methods("POST")
	router.HandleFunc("/users", getUsers).Methods("GET")
	router.HandleFunc("/users/{id}", getUser).Methods("GET")
	router.HandleFunc("/users/{id}", updateUser).Methods("PUT")
	router.HandleFunc("/users/{id}", deleteUser).Methods("DELETE")

	return httptest.NewRecorder(), router
}

// Test configuration loading
func TestLoadConfig(t *testing.T) {
	// Test with environment variables
	os.Setenv("DB_USER", "test_user")
	os.Setenv("DB_PASSWORD", "test_pass")
	os.Setenv("SERVER_PORT", "9090")

	cfg, err := conff.LoadConfig()
	require.NoError(t, err)
	assert.Equal(t, "test_user", cfg.DBUser)
	assert.Equal(t, "test_pass", cfg.DBPassword)
	assert.Equal(t, "9090", cfg.ServerPort)
}

// Test user creation
func TestCreateUser(t *testing.T) {
	recorder, router := setupTest(t)

	// Test valid user creation
	userData := CreateUserRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}

	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusCreated, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.True(t, response.Success)
	assert.Equal(t, "User created successfully", response.Message)
}

// Test user creation with invalid data
func TestCreateUserInvalidData(t *testing.T) {
	recorder, router := setupTest(t)

	// Test missing required fields
	userData := CreateUserRequest{
		Username: "testuser",
		// Missing email and password
	}

	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusBadRequest, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.False(t, response.Success)
	assert.Contains(t, response.Message, "required")
}

// Test get users
func TestGetUsers(t *testing.T) {
	recorder, router := setupTest(t)

	req, _ := http.NewRequest("GET", "/users", nil)
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusOK, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.True(t, response.Success)
	assert.Equal(t, "Users retrieved successfully", response.Message)
}

// Test get user by ID
func TestGetUserByID(t *testing.T) {
	recorder, router := setupTest(t)

	req, _ := http.NewRequest("GET", "/users/1", nil)
	router.ServeHTTP(recorder, req)

	// Should return 404 for non-existent user
	assert.Equal(t, http.StatusNotFound, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.False(t, response.Success)
	assert.Equal(t, "User not found", response.Message)
}

// Test update user
func TestUpdateUser(t *testing.T) {
	recorder, router := setupTest(t)

	userData := UpdateUserRequest{
		Username: "updateduser",
		Email:    "updated@example.com",
		Password: "newpassword123",
	}

	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("PUT", "/users/1", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	router.ServeHTTP(recorder, req)

	// Should return 404 for non-existent user
	assert.Equal(t, http.StatusNotFound, recorder.Code)
}

// Test delete user
func TestDeleteUser(t *testing.T) {
	recorder, router := setupTest(t)

	req, _ := http.NewRequest("DELETE", "/users/1", nil)
	router.ServeHTTP(recorder, req)

	// Should return 404 for non-existent user
	assert.Equal(t, http.StatusNotFound, recorder.Code)
}

// Test invalid user ID
func TestInvalidUserID(t *testing.T) {
	recorder, router := setupTest(t)

	req, _ := http.NewRequest("GET", "/users/invalid", nil)
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusBadRequest, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.False(t, response.Success)
	assert.Equal(t, "Invalid user ID", response.Message)
}

// Test response formatting
func TestResponseFormatting(t *testing.T) {
	recorder := httptest.NewRecorder()

	// Test success response
	respondWithJSON(recorder, http.StatusOK, Response{
		Success: true,
		Message: "Test success",
		Data:    map[string]string{"key": "value"},
	})

	assert.Equal(t, http.StatusOK, recorder.Code)
	assert.Equal(t, "application/json", recorder.Header().Get("Content-Type"))

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.True(t, response.Success)
	assert.Equal(t, "Test success", response.Message)
}

// Test error response
func TestErrorResponse(t *testing.T) {
	recorder := httptest.NewRecorder()

	respondWithError(recorder, http.StatusBadRequest, "Test error")

	assert.Equal(t, http.StatusBadRequest, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.False(t, response.Success)
	assert.Equal(t, "Test error", response.Message)
}

// Test SQL escaping function
func TestEscape(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"normal text", "normal text"},
		{"text with 'quote'", "text with \\'quote\\'"},
		{"text with \"double quote\"", "text with \\\"double quote\\\""},
		{"text with \\backslash", "text with \\\\backslash"},
		{"text with\nnewline", "text with \\nnewline"},
		{"text with\rreturn", "text with \\rreturn"},
		{"text with\000null", "text with \\0null"},
	}

	for _, test := range tests {
		t.Run(fmt.Sprintf("escape_%s", test.input), func(t *testing.T) {
			result := Escape(test.input)
			assert.Equal(t, test.expected, result)
		})
	}
}

// Benchmark tests
func BenchmarkCreateUser(b *testing.B) {
	recorder, router := setupTest(&testing.T{})

	userData := CreateUserRequest{
		Username: "benchuser",
		Email:    "bench@example.com",
		Password: "password123",
	}

	jsonData, _ := json.Marshal(userData)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")
		router.ServeHTTP(recorder, req)
	}
}

func BenchmarkGetUsers(b *testing.B) {
	recorder, router := setupTest(&testing.T{})

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("GET", "/users", nil)
		router.ServeHTTP(recorder, req)
	}
}

// Integration test helper
func TestMain(m *testing.M) {
	// Setup test environment
	os.Setenv("DB_USER", "test_user")
	os.Setenv("DB_PASSWORD", "test_pass")
	os.Setenv("DB_HOST", "localhost")
	os.Setenv("DB_PORT", "3306")
	os.Setenv("DB_NAME", "test_db")
	os.Setenv("SERVER_PORT", "8080")

	// Run tests
	code := m.Run()

	// Cleanup
	os.Exit(code)
}
