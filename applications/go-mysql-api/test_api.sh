#!/bin/bash

# Test script for the Go MySQL User Management API
# Make sure the server is running on localhost:8080

BASE_URL="http://localhost:8080"

echo "Testing Go MySQL User Management API"
echo "===================================="

# Test 1: Create a user
echo -e "\n1. Creating a user..."
CREATE_RESPONSE=$(curl -s -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser1",
    "email": "test1@example.com",
    "password": "password123"
  }')

echo "Response: $CREATE_RESPONSE"

# Extract user ID from response (assuming it's the first user created)
USER_ID=$(echo $CREATE_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$USER_ID" ]; then
    echo "Failed to create user or extract user ID"
    exit 1
fi

echo "Created user with ID: $USER_ID"

# Test 2: Get all users
echo -e "\n2. Getting all users..."
curl -s $BASE_URL/users | jq '.'

# Test 3: Get specific user
echo -e "\n3. Getting user with ID: $USER_ID"
curl -s $BASE_URL/users/$USER_ID | jq '.'

# Test 4: Update user
echo -e "\n4. Updating user with ID: $USER_ID"
UPDATE_RESPONSE=$(curl -s -X PUT $BASE_URL/users/$USER_ID \
  -H "Content-Type: application/json" \
  -d '{
    "username": "updateduser1",
    "email": "updated1@example.com",
    "password": "newpassword123"
  }')

echo "Update response: $UPDATE_RESPONSE"

# Test 5: Get updated user
echo -e "\n5. Getting updated user..."
curl -s $BASE_URL/users/$USER_ID | jq '.'

# Test 6: Create another user
echo -e "\n6. Creating another user..."
curl -s -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "email": "test2@example.com",
    "password": "password456"
  }' | jq '.'

# Test 7: Get all users again
echo -e "\n7. Getting all users after creating second user..."
curl -s $BASE_URL/users | jq '.'

# Test 8: Delete the first user
echo -e "\n8. Deleting user with ID: $USER_ID"
curl -s -X DELETE $BASE_URL/users/$USER_ID | jq '.'

# Test 9: Verify user is deleted
echo -e "\n9. Verifying user is deleted..."
curl -s $BASE_URL/users/$USER_ID | jq '.'

echo -e "\nAPI testing completed!"
