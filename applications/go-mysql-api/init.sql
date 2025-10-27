-- Initialize database for Go application
CREATE DATABASE IF NOT EXISTS goapp_users;
USE goapp_users;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);
CREATE INDEX idx_created_at ON users(created_at);

-- Insert some test data (optional)
INSERT INTO users (username, email, password) VALUES 
    ('admin', 'admin@example.com', 'admin123'),
    ('user1', 'user1@example.com', 'password123')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
