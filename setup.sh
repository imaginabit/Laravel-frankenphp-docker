#!/bin/bash

# Function to setup compose command for a runtime
setup_compose_cmd() {
    local runtime=$1
    if [ "$runtime" = "podman" ]; then
        if podman compose version &> /dev/null; then
            COMPOSE_CMD="podman compose"
        elif command -v podman-compose &> /dev/null; then
            COMPOSE_CMD="podman-compose"
        else
            return 1
        fi
    elif [ "$runtime" = "docker" ]; then
        if docker compose version &> /dev/null; then
            COMPOSE_CMD="docker compose"
        elif command -v docker-compose &> /dev/null; then
            COMPOSE_CMD="docker-compose"
        else
            return 1
        fi
    else
        return 1
    fi
    return 0
}

# Detect available container runtimes
HAS_PODMAN=false
HAS_DOCKER=false

if command -v podman &> /dev/null; then
    HAS_PODMAN=true
fi

if command -v docker &> /dev/null; then
    HAS_DOCKER=true
fi

# Choose container runtime
if [ "$HAS_PODMAN" = true ] && [ "$HAS_DOCKER" = true ]; then
    # Both available - ask user to choose
    echo "🔍 Both Podman and Docker are available."
    echo ""
    echo "Which container runtime would you like to use?"
    echo "  1) Podman"
    echo "  2) Docker"
    echo ""
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)
            CONTAINER_RUNTIME="podman"
            ;;
        2)
            CONTAINER_RUNTIME="docker"
            ;;
        *)
            echo "❌ Invalid choice. Defaulting to Podman."
            CONTAINER_RUNTIME="podman"
            ;;
    esac
elif [ "$HAS_PODMAN" = true ]; then
    CONTAINER_RUNTIME="podman"
elif [ "$HAS_DOCKER" = true ]; then
    CONTAINER_RUNTIME="docker"
else
    echo "❌ Error: Neither Podman nor Docker found. Please install one of them."
    exit 1
fi

# Setup compose command for chosen runtime
if ! setup_compose_cmd "$CONTAINER_RUNTIME"; then
    echo "❌ Error: $CONTAINER_RUNTIME-compose not found. Please install it."
    exit 1
fi

echo "🐳 Using $CONTAINER_RUNTIME as container runtime"

# Note: Using FrankenPHP latest tag (PHP version is determined by the image)
# PHP version selection is not available with latest tag
PHP_VERSION="latest"
echo ""
echo "📌 Using FrankenPHP latest tag (includes latest PHP version)"

# Select Laravel version
echo ""
echo "📌 Select Laravel version:"
echo "  1) Laravel 7"
echo "  2) Laravel 8"
echo "  3) Laravel 9"
echo "  4) Laravel 10"
echo "  5) Laravel 11"
echo "  6) Laravel 12"
echo ""
read -p "Enter your choice (1-6) [default: 6]: " laravel_choice
case $laravel_choice in
    1)
        LARAVEL_VERSION="^7.0"
        LARAVEL_PACKAGE="laravel/laravel:^7.0"
        ;;
    2)
        LARAVEL_VERSION="^8.0"
        # Use specific version constraint for Laravel 8 - use 8.* to ensure it stays in 8.x
        LARAVEL_PACKAGE="laravel/laravel:8.*"
        ;;
    3)
        LARAVEL_VERSION="^9.0"
        LARAVEL_PACKAGE="laravel/laravel:^9.0"
        ;;
    4)
        LARAVEL_VERSION="^10.0"
        LARAVEL_PACKAGE="laravel/laravel:^10.0"
        ;;
    5)
        LARAVEL_VERSION="^11.0"
        LARAVEL_PACKAGE="laravel/laravel:^11.0"
        ;;
    6|"")
        LARAVEL_VERSION="^12.0"
        LARAVEL_PACKAGE="laravel/laravel:^12.0"
        ;;
    *)
        echo "❌ Invalid choice. Defaulting to Laravel 12."
        LARAVEL_VERSION="^12.0"
        LARAVEL_PACKAGE="laravel/laravel:^12.0"
        ;;
esac

echo ""
echo "✅ Selected: FrankenPHP (latest), Laravel $LARAVEL_VERSION"
echo ""

echo "🚀 Setting up Laravel project with $CONTAINER_RUNTIME..."

# Create codesrc directory if it doesn't exist
if [ ! -d "codesrc" ]; then
    echo "📁 Creating codesrc directory..."
    mkdir -p codesrc
fi

# Check if Laravel is already installed
if [ ! -f "codesrc/artisan" ]; then
    echo "📦 Installing Laravel $LARAVEL_VERSION in codesrc folder..."
    echo "   Using package: $LARAVEL_PACKAGE"
    $CONTAINER_RUNTIME run --rm -v $(pwd)/codesrc:/var/www/html -w /var/www/html composer create-project --prefer-dist --no-interaction "$LARAVEL_PACKAGE" .
fi

# Copy .env.example to .env if .env doesn't exist
if [ ! -f "codesrc/.env" ]; then
    echo "📝 Creating .env file..."
    if [ -f ".env.example" ]; then
        cp .env.example codesrc/.env
    elif [ -f "codesrc/.env.example" ]; then
        cp codesrc/.env.example codesrc/.env
    fi
fi

# Build and start containers
echo "🐳 Building and starting containers..."
$COMPOSE_CMD up -d --build

# Function to wait for container to be running
wait_for_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $container_name to be running..."
    while [ $attempt -le $max_attempts ]; do
        if $CONTAINER_RUNTIME ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            local status=$($CONTAINER_RUNTIME inspect --format='{{.State.Status}}' $container_name 2>/dev/null)
            if [ "$status" = "running" ]; then
                echo "✅ $container_name is running"
                return 0
            fi
        fi
        echo "   Attempt $attempt/$max_attempts - waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ $container_name failed to start after $max_attempts attempts"
    return 1
}

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
wait_for_container laravel_db
sleep 5

# Wait for app container to be running
if ! wait_for_container laravel_app; then
    echo "❌ App container failed to start. Checking logs..."
    $COMPOSE_CMD logs app | tail -20
    echo ""
    echo "Please check the logs above and fix any issues."
    exit 1
fi

# Wait a bit more for app to be fully ready
echo "⏳ Waiting for app to be fully ready..."
sleep 5

# Generate application key with retry
echo "🔑 Generating application key..."
MAX_RETRIES=5
RETRY_COUNT=0
KEY_GENERATED=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$KEY_GENERATED" = false ]; do
    if $COMPOSE_CMD exec -T app php artisan key:generate 2>/dev/null; then
        echo "✅ Application key generated successfully"
        KEY_GENERATED=true
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "   Retry $RETRY_COUNT/$MAX_RETRIES - waiting a bit more..."
            sleep 3
        fi
    fi
done

if [ "$KEY_GENERATED" = false ]; then
    echo "⚠️  Could not generate key automatically after $MAX_RETRIES attempts."
    echo "   You can run it manually:"
    echo "   $COMPOSE_CMD exec app php artisan key:generate"
fi

echo "✅ Setup complete!"
echo ""
echo "🌐 Application: http://localhost:8080"
echo "🗄️  phpMyAdmin: http://localhost:8081"
echo ""
echo "To run migrations: $COMPOSE_CMD exec app php artisan migrate"

