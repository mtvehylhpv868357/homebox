# Makefile for homebox development

.PHONY: all build run test lint clean docker-build docker-up docker-down dev

# Variables
BINARY_NAME=homebox
BUILD_DIR=./build
CMD_DIR=./backend/app/api
FRONTEND_DIR=./frontend

# Default target
all: build

## Build the backend binary
build:
	@echo "Building backend..."
	@mkdir -p $(BUILD_DIR)
	cd backend && go build -o ../$(BUILD_DIR)/$(BINARY_NAME) $(CMD_DIR)

## Run the backend server locally
run:
	@echo "Starting backend..."
	cd backend && go run $(CMD_DIR)

## Run all tests
test:
	@echo "Running backend tests..."
	cd backend && go test ./... -v

## Run tests without verbose output (faster to scan for failures)
test-short:
	@echo "Running backend tests (short)..."
	cd backend && go test ./...

## Run linter
lint:
	@echo "Linting backend..."
	cd backend && golangci-lint run ./...

## Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)

## Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker compose build

## Start services via Docker Compose
docker-up:
	@echo "Starting services..."
	docker compose up -d

## Stop services via Docker Compose
docker-down:
	@echo "Stopping services..."
	docker compose down

## Install frontend dependencies and run dev server
frontend-dev:
	@echo "Starting frontend dev server..."
	cd $(FRONTEND_DIR) && npm install && npm run dev

## Generate swagger/openapi docs
swagger:
	@echo "Generating API docs..."
	cd backend && swag init -g app/api/main.go -o app/api/docs

## Run database migrations
migrate:
	@echo "Running migrations..."
	cd backend && go run ./app/tools/migrate

## Full dev setup: start docker deps, then run backend
# Note: increased sleep to 5s since my machine is slower and db wasn't always ready in time
dev: docker-up
	@echo "Waiting for services to be ready..."
	@sleep 5
	@$(MAKE) run
