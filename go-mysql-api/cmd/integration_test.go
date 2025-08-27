package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	conff "command-line-arguments/Users/usualsuspectx/Development/go/src/github.com/blind3dd/goapp_CI/config.go"

	"github.com/gorilla/mux"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// IntegrationTestSuite provides integration testing with real database
type IntegrationTestSuite struct {
	suite.Suite
	router *mux.Router
	db     *sql.DB
}

// SetupSuite runs once before all tests
func (suite *IntegrationTestSuite) SetupSuite() {
	// Set up test database configuration
	os.Setenv("DB_USER", "test_user")
	os.Setenv("DB_PASSWORD", "test_pass")
	os.Setenv("DB_HOST", "localhost")
	os.Setenv("DB_PORT", "3306")
	os.Setenv("DB_NAME", "test_integration_db")
	os.Setenv("SERVER_PORT", "8080")

	// Initialize database connection
	suite.initTestDB()

	// Set up router
	suite.router = mux.NewRouter()
	suite.router.HandleFunc("/users", createUser).Methods("POST")
	suite.router.HandleFunc("/users", getUsers).Methods("GET")
	suite.router.HandleFunc("/users/{id}", getUser).Methods("GET")
	suite.router.HandleFunc("/users/{id}", updateUser).Methods("PUT")
	suite.router.HandleFunc("/users/{id}", deleteUser).Methods("DELETE")
}

// TearDownSuite runs once after all tests
func (suite *IntegrationTestSuite) TearDownSuite() {
	if suite.db != nil {
		suite.db.Close()
	}
}

// SetupTest runs before each test
func (suite *IntegrationTestSuite) SetupTest() {
	// Clean up database before each test
	suite.cleanupDB()
}

// TearDownTest runs after each test
func (suite *IntegrationTestSuite) TearDownTest() {
	// Clean up database after each test
	suite.cleanupDB()
}

func (suite *IntegrationTestSuite) initTestDB() {
	cfg, err := conff.LoadConfig()
	require.NoError(suite.T(), err)

	// Create test database connection string
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&multiStatements=true",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName)

	// Connect to database
	suite.db, err = sql.Open("mysql", dsn)
	require.NoError(suite.T(), err)

	// Test connection
	err = suite.db.Ping()
	if err != nil {
		suite.T().Skipf("Database connection failed, skipping integration tests: %v", err)
		return
	}

	// Create test table
	suite.createTestTable()
}

func (suite *IntegrationTestSuite) createTestTable() {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id INT AUTO_INCREMENT PRIMARY KEY,
		username VARCHAR(50) UNIQUE NOT NULL,
		email VARCHAR(100) UNIQUE NOT NULL,
		password VARCHAR(255) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	)`

	_, err := suite.db.Exec(query)
	require.NoError(suite.T(), err)
}

func (suite *IntegrationTestSuite) cleanupDB() {
	if suite.db != nil {
		// Delete all users
		_, err := suite.db.Exec("DELETE FROM users")
		if err != nil {
			suite.T().Logf("Error cleaning up database: %v", err)
		}

		// Reset auto increment
		_, err = suite.db.Exec("ALTER TABLE users AUTO_INCREMENT = 1")
		if err != nil {
			suite.T().Logf("Error resetting auto increment: %v", err)
		}
	}
}

// Test full user lifecycle
func (suite *IntegrationTestSuite) TestUserLifecycle() {
	// 1. Create user
	userData := CreateUserRequest{
		Username: "integrationuser",
		Email:    "integration@example.com",
		Password: "password123",
	}

	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusCreated, recorder.Code)

	var createResponse Response
	err := json.Unmarshal(recorder.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), createResponse.Success)

	// Extract user ID from response
	userDataMap := createResponse.Data.(map[string]interface{})
	userID := int(userDataMap["id"].(float64))

	// 2. Get user by ID
	req, _ = http.NewRequest("GET", fmt.Sprintf("/users/%d", userID), nil)
	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var getResponse Response
	err = json.Unmarshal(recorder.Body.Bytes(), &getResponse)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), getResponse.Success)

	// 3. Update user
	updateData := UpdateUserRequest{
		Username: "updatedintegrationuser",
		Email:    "updated.integration@example.com",
		Password: "newpassword123",
	}

	jsonData, _ = json.Marshal(updateData)
	req, _ = http.NewRequest("PUT", fmt.Sprintf("/users/%d", userID), bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var updateResponse Response
	err = json.Unmarshal(recorder.Body.Bytes(), &updateResponse)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), updateResponse.Success)

	// 4. Verify update
	req, _ = http.NewRequest("GET", fmt.Sprintf("/users/%d", userID), nil)
	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var verifyResponse Response
	err = json.Unmarshal(recorder.Body.Bytes(), &verifyResponse)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), verifyResponse.Success)

	// 5. Delete user
	req, _ = http.NewRequest("DELETE", fmt.Sprintf("/users/%d", userID), nil)
	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var deleteResponse Response
	err = json.Unmarshal(recorder.Body.Bytes(), &deleteResponse)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), deleteResponse.Success)

	// 6. Verify deletion
	req, _ = http.NewRequest("GET", fmt.Sprintf("/users/%d", userID), nil)
	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusNotFound, recorder.Code)
}

// Test multiple users
func (suite *IntegrationTestSuite) TestMultipleUsers() {
	// Create multiple users
	users := []CreateUserRequest{
		{Username: "user1", Email: "user1@example.com", Password: "pass1"},
		{Username: "user2", Email: "user2@example.com", Password: "pass2"},
		{Username: "user3", Email: "user3@example.com", Password: "pass3"},
	}

	userIDs := make([]int, len(users))

	for i, userData := range users {
		jsonData, _ := json.Marshal(userData)
		req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")

		recorder := httptest.NewRecorder()
		suite.router.ServeHTTP(recorder, req)

		assert.Equal(suite.T(), http.StatusCreated, recorder.Code)

		var response Response
		err := json.Unmarshal(recorder.Body.Bytes(), &response)
		require.NoError(suite.T(), err)

		userDataMap := response.Data.(map[string]interface{})
		userIDs[i] = int(userDataMap["id"].(float64))
	}

	// Get all users
	req, _ := http.NewRequest("GET", "/users", nil)
	recorder := httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(suite.T(), err)
	assert.True(suite.T(), response.Success)

	// Verify we have 3 users
	usersList := response.Data.([]interface{})
	assert.Len(suite.T(), usersList, 3)
}

// Test duplicate username/email
func (suite *IntegrationTestSuite) TestDuplicateConstraints() {
	// Create first user
	userData := CreateUserRequest{
		Username: "test",
		Email:    "test@example.com"
		est@example.com",
		Password: "password123",
	}

	jsonData, _ := json.Marshal(userData)
	req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusCreated, recorder.Code)

	// Try to create user with same username
	duplicateUser := CreateUserRequest{
		Username: "duplicateuser", // Same username
		Email:    "different@example.com",
		Password: "password456",
	}

	jsonData, _ = json.Marshal(duplicateUser)
	req, _ = http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	recorder = httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	// Should fail due to duplicate username
	assert.Equal(suite.T(), http.StatusInternalServerError, recorder.Code)
}

// Test concurrent user creation
func (suite *IntegrationTestSuite) TestConcurrentUserCreation() {
	const numUsers = 10
	done := make(chan bool, numUsers)

	for i := 0; i < numUsers; i++ {
		go func(id int) {
			userData := CreateUserRequest{
				Username: fmt.Sprintf("concurrentuser%d", id),
				Email:    fmt.Sprintf("concurrent%d@example.com", id),
				Password: "password123",
			}

			jsonData, _ := json.Marshal(userData)
			req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(jsonData))
			req.Header.Set("Content-Type", "application/json")

			recorder := httptest.NewRecorder()
			suite.router.ServeHTTP(recorder, req)

			// All should succeed
			assert.Equal(suite.T(), http.StatusCreated, recorder.Code)
			done <- true
		}(i)
	}

	// Wait for all goroutines to complete
	for i := 0; i < numUsers; i++ {
		<-done
	}

	// Verify all users were created
	req, _ := http.NewRequest("GET", "/users", nil)
	recorder := httptest.NewRecorder()
	suite.router.ServeHTTP(recorder, req)

	assert.Equal(suite.T(), http.StatusOK, recorder.Code)

	var response Response
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(suite.T(), err)

	usersList := response.Data.([]interface{})
	assert.Len(suite.T(), usersList, numUsers)
}

// Run the integration test suite
func TestIntegrationTestSuite(t *testing.T) {
	suite.Run(t, new(IntegrationTestSuite))
}
