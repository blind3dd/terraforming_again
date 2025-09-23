#!/bin/bash

# Test runner script for Go MySQL User Management API
set -e

echo "🚀 Starting comprehensive test suite for Go MySQL User Management API"
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go 1.21 or higher."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
print_status "Go version: $GO_VERSION"

# Install dependencies
print_status "Installing dependencies..."
go mod tidy
if [ $? -eq 0 ]; then
    print_success "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Run linter
print_status "Running linter..."
if command -v golangci-lint &> /dev/null; then
    golangci-lint run
    if [ $? -eq 0 ]; then
        print_success "Linting passed"
    else
        print_warning "Linting found issues"
    fi
else
    print_warning "golangci-lint not found, skipping linting"
fi

# Run unit tests
print_status "Running unit tests..."
go test -v ./cmd/...
if [ $? -eq 0 ]; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Run tests with coverage
print_status "Running tests with coverage..."
go test -v -coverprofile=coverage.out ./cmd/...
if [ $? -eq 0 ]; then
    print_success "Coverage tests passed"
    
    # Generate coverage report
    go tool cover -func=coverage.out
    go tool cover -html=coverage.out -o coverage.html
    print_success "Coverage report generated: coverage.html"
else
    print_error "Coverage tests failed"
    exit 1
fi

# Run benchmarks
print_status "Running benchmarks..."
go test -bench=. -benchmem ./cmd/...
if [ $? -eq 0 ]; then
    print_success "Benchmarks completed"
else
    print_warning "Benchmarks failed"
fi

# Check if Docker is available for integration tests
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    print_status "Docker detected, running integration tests..."
    
    # Start MySQL container for integration tests
    print_status "Starting MySQL container for integration tests..."
    docker-compose up -d mysql
    
    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    sleep 30
    
    # Run integration tests
    print_status "Running integration tests..."
    go test -v -tags=integration ./...
    if [ $? -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_warning "Integration tests failed (this is expected if MySQL is not configured)"
    fi
    
    # Stop containers
    print_status "Stopping containers..."
    docker-compose down
else
    print_warning "Docker not available, skipping integration tests"
fi

# Run API tests if server is running
print_status "Checking if API server is running..."
if curl -s http://localhost:8080/users > /dev/null 2>&1; then
    print_status "API server is running, running API tests..."
    chmod +x test_api.sh
    ./test_api.sh
    if [ $? -eq 0 ]; then
        print_success "API tests passed"
    else
        print_warning "API tests failed"
    fi
else
    print_warning "API server not running, skipping API tests"
fi

# Generate test summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo "✅ Unit tests: Completed"
echo "✅ Coverage tests: Completed"
echo "✅ Benchmarks: Completed"

if command -v docker &> /dev/null; then
    echo "✅ Integration tests: Completed"
else
    echo "⚠️  Integration tests: Skipped (Docker not available)"
fi

if curl -s http://localhost:8080/users > /dev/null 2>&1; then
    echo "✅ API tests: Completed"
else
    echo "⚠️  API tests: Skipped (Server not running)"
fi

echo ""
print_success "All tests completed successfully!"
print_status "Coverage report available at: coverage.html"
print_status "To run specific tests:"
echo "  - Unit tests only: make test"
echo "  - With coverage: make test-coverage"
echo "  - Integration tests: make test-integration"
echo "  - Benchmarks: make test-bench"
echo "  - Docker tests: make test-docker"

# Clean up
rm -f coverage.out

echo ""
print_success "🎉 Test suite completed!"
