package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"time"

	"goapp_CI/conff"

	"github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

// User represents a user in the system
type User struct {
	ID        int       `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	Password  string    `json:"password,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// CreateUserRequest represents the request body for creating a user
type CreateUserRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

// UpdateUserRequest represents the request body for updating a user
type UpdateUserRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Response represents a generic API response
type Response struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

var db *sql.DB

func main() {
	// Initialize database connection
	initDB()
	defer db.Close()
	r := mux.NewRouter()
	// Define routes
	r.HandleFunc("/users", createUser).Methods("POST")
	r.HandleFunc("/users", getUsers).Methods("GET")
	r.HandleFunc("/users/{id}", getUser).Methods("GET")
	r.HandleFunc("/users/{id}", updateUser).Methods("PUT")
	r.HandleFunc("/users/{id}", deleteUser).Methods("DELETE")

	// Start server
	cfg, err := conff.LoadConfig()
	if err != nil {
		log.Fatalf("Error loading configuration, error: %v", err)
	}
	fmt.Printf("Server starting on port %s...\n", cfg.ServerPort)

	var srv http.Server = http.Server{
		Addr:    ":" + cfg.ServerPort,
		Handler: r,
	}

	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt)
		<-sigint
		// We received an interrupt signal, shut down.
		if err := srv.Shutdown(context.Background()); err != nil {
			// Error from closing listeners, or context timeout:
			log.Printf("server shutdown: %v", err)
		}
		close(idleConnsClosed)
	}()
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		// Error starting or closing listener:
		log.Fatalf("server ListenAndServe: %v", err)
	}

	<-idleConnsClosed
	log.Fatal(http.ListenAndServe(":"+cfg.ServerPort, r))
}

func initDB() {

	cfg, err := conff.LoadConfig()
	if err != nil {
		log.Fatalf("Error loading configuration, error: %v", err)
	}

	config := mysql.Config{
		User:   cfg.DBUser,
		Passwd: cfg.DBPassword,
		Net:    "tcp",
		Addr:   fmt.Sprintf("%s:%s", cfg.DBHost, cfg.DBPort),
		DBName: cfg.DBName,
	}

	db, err = sql.Open("mysql", config.FormatDSN())
	if err != nil {
		log.Fatal("Error opening database:", err)
	}

	// Test the connection
	err = db.Ping()
	if err != nil {
		log.Fatalf("error connecting to MySQL database, error: %v", err)
	} else {
		log.Println("successfully connected to MySQL database")
	}

	createTable()
}

func createTable() {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id INT AUTO_INCREMENT PRIMARY KEY,
		username VARCHAR(50) UNIQUE NOT NULL,
		email VARCHAR(100) UNIQUE NOT NULL,
		password VARCHAR(255) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	)`

	_, err := db.Exec(query)
	if err != nil {
		log.Fatal("Error creating table:", err)
	}

	fmt.Println("Users table created or already exists")
}

func createUser(w http.ResponseWriter, r *http.Request) {
	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Username == "" || req.Email == "" || req.Password == "" {
		respondWithError(w, http.StatusBadRequest, "Username, email, and password are required")
		return
	}

	// Insert user into database
	query := "INSERT INTO users (username, email, password) VALUES (?, ?, ?)"
	result, err := db.Exec(Escape(query), req.Username, req.Email, req.Password)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error creating user: "+err.Error())
		return
	}

	userID, err := result.LastInsertId()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "error getting user ID")
		return
	}

	// Get the created user
	user, err := getUserByID(int(userID))
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "error retrieving created user")
		return
	}

	respondWithJSON(w, http.StatusCreated, Response{
		Success: true,
		Message: "User created successfully",
		Data:    user,
	})
}

func getUsers(w http.ResponseWriter, r *http.Request) {
	query := "SELECT id, username, email, created_at, updated_at FROM users ORDER BY created_at DESC"
	rows, err := db.Query(query)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "error fetching users")
		return
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.CreatedAt, &user.UpdatedAt)
		if err != nil {
			respondWithError(w, http.StatusInternalServerError, "error scanning user data")
			return
		}
		users = append(users, user)
	}

	respondWithJSON(w, http.StatusOK, Response{
		Success: true,
		Message: "Users retrieved successfully",
		Data:    users,
	})
}

func getUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	user, err := getUserByID(id)
	if err != nil {
		respondWithError(w, http.StatusNotFound, "User not found")
		return
	}

	respondWithJSON(w, http.StatusOK, Response{
		Success: true,
		Message: "User retrieved successfully",
		Data:    user,
	})
}

func updateUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Check if user exists
	_, err = getUserByID(id)
	if err != nil {
		respondWithError(w, http.StatusNotFound, "User not found")
		return
	}

	// Update user
	query := "UPDATE users SET username = ?, email = ?, password = ? WHERE id = ?"
	_, err = db.Exec(Escape(query), req.Username, req.Email, req.Password, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error updating user: "+err.Error())
		return
	}

	// Get updated user
	user, err := getUserByID(id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error retrieving updated user")
		return
	}

	respondWithJSON(w, http.StatusOK, Response{
		Success: true,
		Message: "User updated successfully",
		Data:    user,
	})
}

func deleteUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	// Check if user exists
	_, err = getUserByID(id)
	if err != nil {
		respondWithError(w, http.StatusNotFound, "User not found")
		return
	}

	// Delete user
	query := "DELETE FROM users WHERE id = ?"
	_, err = db.Exec(Escape(query), id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error deleting user: "+err.Error())
		return
	}

	respondWithJSON(w, http.StatusOK, Response{
		Success: true,
		Message: "User deleted successfully",
	})
}

func getUserByID(id int) (*User, error) {
	query := "SELECT id, username, email, created_at, updated_at FROM users WHERE id = ?"
	var user User
	err := db.QueryRow(Escape(query), id).Scan(&user.ID, &user.Username, &user.Email, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func respondWithJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func respondWithError(w http.ResponseWriter, status int, message string) {
	respondWithJSON(w, status, Response{
		Success: false,
		Message: message,
	})
}

// Escape is a helper function to escape special characters in SQL queries
// Security necessity added for SQL injection protection
func Escape(sql string) string {
	dest := make([]byte, 0, 2*len(sql))
	var escape byte
	for i := 0; i < len(sql); i++ {
		c := sql[i]
		escape = 0
		switch c {
		case 0:
			escape = '0'
		case '\n':
			escape = 'n'
		case '\r':
			escape = 'r'
		case '\\':
			escape = '\\'
		case '\'':
			escape = '\''
		case '"':
			escape = '"'
		case '\032':
			escape = 'Z'
		}

		if escape != 0 {
			dest = append(dest, '\\', escape)
		} else {
			dest = append(dest, c)
		}
	}

	return string(dest)
}
