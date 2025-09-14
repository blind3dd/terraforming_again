.PHONY: run build clean test deps

# Default target
all: deps build

# Install dependencies
deps:
	go mod tidy

# Build the application
build:
	go build -o bin/goapp .

# Run the application
run:
	go run .

# Clean build artifacts
clean:
	rm -rf bin/

# Run tests
test:
	go test -v ./...

# Run tests with coverage
test-coverage:
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Run integration tests
test-integration:
	go test -v -tags=integration ./...

# Run benchmarks
test-bench:
	go test -bench=. ./...

# Run tests in Docker
test-docker:
	docker-compose up test

# Clean test artifacts
clean-test:
	rm -f coverage.out coverage.html

# Install dependencies and run
dev: deps run
