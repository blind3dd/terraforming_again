# Go MySQL User Management API

A RESTful API built with Go that connects to MySQL for user management operations.

## Features

- Create, Read, Update, Delete (CRUD) operations for users
- MySQL database integration
- RESTful API endpoints
- JSON request/response format
- Input validation
- Error handling

## Prerequisites

- Go 1.21 or higher
- MySQL server running
- Git

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd goapp_CI
```

2. Install dependencies:
```bash
go mod tidy
```

3. Set up MySQL database:
```sql
CREATE DATABASE goapp_users;
```

4. Configure database connection:
   - Edit the database configuration in `main.go` or set environment variables:
   ```bash
   export DB_USER=your_mysql_username
   export DB_PASSWORD=your_mysql_password
   export DB_HOST=localhost
   export DB_PORT=3306
   export DB_NAME=goapp_users
   export SERVER_PORT=8080
   ```

## Running the Application

```bash
go run .
```

The server will start on port 8080 (or the port specified in SERVER_PORT environment variable).

## API Endpoints

### Create User
- **POST** `/users`
- **Body:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

### Get All Users
- **GET** `/users`
- Returns a list of all users (passwords are not included)

### Get User by ID
- **GET** `/users/{id}`
- Returns a specific user by ID

### Update User
- **PUT** `/users/{id}`
- **Body:**
```json
{
  "username": "john_doe_updated",
  "email": "john.updated@example.com",
  "password": "newpassword123"
}
```

### Delete User
- **DELETE** `/users/{id}`
- Deletes a user by ID

## Response Format

All API responses follow this format:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data here
  }
}
```

Error responses:
```json
{
  "success": false,
  "message": "Error description"
}
```

## Database Schema

The application automatically creates a `users` table with the following structure:

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Example Usage

### Using curl

1. Create a user:
```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

2. Get all users:
```bash
curl http://localhost:8080/users
```

3. Get a specific user:
```bash
curl http://localhost:8080/users/1
```

4. Update a user:
```bash
curl -X PUT http://localhost:8080/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "username": "updateduser",
    "email": "updated@example.com",
    "password": "newpassword123"
  }'
```

5. Delete a user:
```bash
curl -X DELETE http://localhost:8080/users/1
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| DB_USER | root | MySQL username |
| DB_PASSWORD | password | MySQL password |
| DB_HOST | localhost | MySQL host |
| DB_PORT | 3306 | MySQL port |
| DB_NAME | goapp_users | Database name |
| SERVER_PORT | 8080 | Server port |

## Security Notes

- This is a basic implementation for demonstration purposes
- In production, consider:
  - Password hashing (bcrypt, argon2)
  - Input sanitization
  - Rate limiting
  - Authentication and authorization
  - HTTPS
  - Database connection pooling
  - Prepared statements (already implemented)

## Troubleshooting

1. **Database connection error**: Make sure MySQL is running and the credentials are correct
2. **Port already in use**: Change the SERVER_PORT environment variable
3. **Module not found**: Run `go mod tidy` to download dependencies

## License

This project is open source and available under the MIT License.
