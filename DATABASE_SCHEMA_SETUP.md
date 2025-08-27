# Database Schema Setup for Go MySQL API

This document provides a comprehensive guide for setting up the database schema and initialization for the Go MySQL API application.

## Overview

The database setup includes:
- **Complete user management system** with roles and permissions
- **User profiles** with extended information
- **Session management** for authentication
- **Audit logging** for security and compliance
- **Sample data** for testing and development
- **Stored procedures** for common operations
- **Database views** for reporting
- **Performance indexes** for optimal query performance

## Database Schema

### Core Tables

#### 1. `users` Table
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Purpose**: Core user authentication and basic information
**Key Features**:
- Unique username and email constraints
- Password hashing support
- Active/inactive user status
- Automatic timestamp management

#### 2. `user_profiles` Table
```sql
CREATE TABLE user_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    bio TEXT,
    avatar_url VARCHAR(255),
    date_of_birth DATE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Purpose**: Extended user profile information
**Key Features**:
- One-to-one relationship with users
- Comprehensive profile data
- Cascade deletion with user

#### 3. `user_roles` Table
```sql
CREATE TABLE user_roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Purpose**: Role-based access control
**Key Features**:
- JSON-based permissions storage
- Flexible permission structure
- Role descriptions

#### 4. `user_role_assignments` Table
```sql
CREATE TABLE user_role_assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_user_role (user_id, role_id)
);
```

**Purpose**: Many-to-many relationship between users and roles
**Key Features**:
- Audit trail for role assignments
- Unique constraint prevents duplicate assignments
- Cascade deletion

#### 5. `user_sessions` Table
```sql
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Purpose**: Session management for authentication
**Key Features**:
- Secure session tokens
- Automatic expiration
- Cascade deletion with user

#### 6. `audit_logs` Table
```sql
CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
```

**Purpose**: Comprehensive audit trail
**Key Features**:
- JSON storage for flexible data tracking
- IP address and user agent logging
- Soft deletion (user_id can be NULL)

## Sample Data

### Default Roles
1. **admin**: Full system access
2. **user**: Basic user access
3. **moderator**: User management access

### Default Users
1. **admin** (admin@example.com) - Administrator
2. **john_doe** (john.doe@example.com) - Software Developer
3. **jane_smith** (jane.smith@example.com) - DevOps Engineer
4. **bob_wilson** (bob.wilson@example.com) - System Administrator

**Default Password**: `admin123` (bcrypt hash: `$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi`)

## Stored Procedures

### 1. `GetUserWithDetails(user_id)`
Retrieves complete user information including profile and roles.

### 2. `CreateUserWithProfile(...)`
Creates a new user with profile in a single transaction.

### 3. `LogAuditEvent(...)`
Logs audit events with comprehensive information.

## Database Views

### 1. `active_users_with_roles`
Shows all active users with their assigned roles.

### 2. `user_statistics`
Provides user statistics and metrics.

## Performance Indexes

```sql
-- User indexes
CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);
CREATE INDEX idx_created_at ON users(created_at);
CREATE INDEX idx_users_email_active ON users(email, is_active);
CREATE INDEX idx_users_username_active ON users(username, is_active);

-- Profile indexes
CREATE INDEX idx_user_id ON user_profiles(user_id);

-- Session indexes
CREATE INDEX idx_user_id ON user_sessions(user_id);
CREATE INDEX idx_session_token ON user_sessions(session_token);
CREATE INDEX idx_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_user_expires ON user_sessions(user_id, expires_at);

-- Audit indexes
CREATE INDEX idx_user_id ON audit_logs(user_id);
CREATE INDEX idx_action ON audit_logs(action);
CREATE INDEX idx_table_name ON audit_logs(table_name);
CREATE INDEX idx_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_user_action ON audit_logs(user_id, action);
```

## Installation Methods

### 1. Docker Compose (Local Development)

```bash
# Start the services
docker-compose up -d

# The init.sql script will automatically run when MySQL starts
```

### 2. Ansible Playbook (Production)

```bash
# Run database initialization
ansible-playbook database-init.yml -i inventory --vault-password-file .vault_password
```

### 3. Manual Installation

```bash
# Connect to MySQL
mysql -h <host> -u <user> -p <database>

# Execute the init.sql script
source init.sql;
```

## Usage Examples

### 1. Get User with Profile and Roles
```sql
CALL GetUserWithDetails(1);
```

### 2. Create New User
```sql
CALL CreateUserWithProfile(
    'newuser',
    'newuser@example.com',
    '$2a$10$hashedpassword',
    'John',
    'Doe',
    'Software developer',
    '+1-555-0123',
    'San Francisco',
    'USA'
);
```

### 3. Log Audit Event
```sql
CALL LogAuditEvent(
    1,                          -- user_id
    'USER_LOGIN',              -- action
    'users',                   -- table_name
    1,                         -- record_id
    '{"old": "value"}',        -- old_values
    '{"new": "value"}',        -- new_values
    '192.168.1.1',            -- ip_address
    'Mozilla/5.0...'          -- user_agent
);
```

### 4. View Active Users
```sql
SELECT * FROM active_users_with_roles;
```

### 5. Get User Statistics
```sql
SELECT * FROM user_statistics;
```

## Security Features

### 1. Password Hashing
- Uses bcrypt for password hashing
- Configurable cost factor
- Secure salt generation

### 2. Session Management
- Secure session tokens
- Automatic expiration
- Cascade deletion

### 3. Role-Based Access Control
- Flexible permission system
- JSON-based permissions
- Audit trail for assignments

### 4. Audit Logging
- Comprehensive activity tracking
- IP address logging
- User agent tracking
- JSON storage for flexibility

## Monitoring and Maintenance

### 1. Database Health Check
```sql
-- Check table sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'mock_user'
ORDER BY (data_length + index_length) DESC;
```

### 2. User Activity Monitoring
```sql
-- Recent user activity
SELECT 
    u.username,
    COUNT(al.id) as activity_count,
    MAX(al.created_at) as last_activity
FROM users u
LEFT JOIN audit_logs al ON u.id = al.user_id
WHERE al.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY u.id, u.username
ORDER BY activity_count DESC;
```

### 3. Session Cleanup
```sql
-- Clean expired sessions
DELETE FROM user_sessions WHERE expires_at < NOW();
```

## Troubleshooting

### Common Issues

1. **Connection Refused**
   ```bash
   # Check MySQL service status
   sudo systemctl status mysql
   
   # Check MySQL logs
   sudo tail -f /var/log/mysql/error.log
   ```

2. **Permission Denied**
   ```sql
   -- Grant permissions
   GRANT ALL PRIVILEGES ON mock_user.* TO 'db_user'@'%';
   FLUSH PRIVILEGES;
   ```

3. **Schema Already Exists**
   ```sql
   -- Drop and recreate (careful!)
   DROP DATABASE IF EXISTS mock_user;
   CREATE DATABASE mock_user;
   ```

### Debug Commands

```bash
# Test database connection
mysql -h <host> -u <user> -p -e "SELECT 1;"

# Check table existence
mysql -h <host> -u <user> -p -e "SHOW TABLES;" <database>

# Check user count
mysql -h <host> -u <user> -p -e "SELECT COUNT(*) FROM users;" <database>
```

## Backup and Recovery

### 1. Database Backup
```bash
# Full database backup
mysqldump -h <host> -u <user> -p mock_user > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup with compression
mysqldump -h <host> -u <user> -p mock_user | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### 2. Database Restore
```bash
# Restore from backup
mysql -h <host> -u <user> -p mock_user < backup_file.sql

# Restore from compressed backup
gunzip < backup_file.sql.gz | mysql -h <host> -u <user> -p mock_user
```

## Performance Optimization

### 1. Query Optimization
- Use appropriate indexes
- Optimize JOIN operations
- Use stored procedures for complex operations

### 2. Connection Pooling
- Configure connection pool size
- Monitor connection usage
- Implement connection timeout

### 3. Regular Maintenance
- Update table statistics
- Clean up expired sessions
- Archive old audit logs

## Support

For database-related issues:
1. Check the troubleshooting section
2. Review MySQL error logs
3. Verify connection parameters
4. Test with sample queries
5. Contact the development team
