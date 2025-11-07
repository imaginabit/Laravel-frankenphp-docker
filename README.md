# Laravel Docker Project with FrankenPHP

A Laravel base project with Docker setup using FrankenPHP for faster local development. FrankenPHP is a modern application server for PHP that includes an embedded web server (Caddy), providing better performance than traditional PHP-FPM + Nginx setups.

## Project Structure

- **codesrc/** - Laravel application code (separated from Docker configuration)
- **docker/** - Docker configuration files (Caddy, PHP settings)
- **docker-compose.yml** - Container orchestration
- **Dockerfile** - FrankenPHP container definition
- **setup.sh** - Automated setup script

## Prerequisites

- Docker or Podman
- Docker Compose or Podman Compose

## Getting Started

### Quick Setup

Run the setup script:

```bash
./setup.sh
```

The script will:
1. Detect if you have Podman or Docker (asks you to choose if both are available)
2. Ask you to select PHP version (8.2 or 8.4)
3. Ask you to select Laravel version (7, 8, 9, 10, 11, or 12)
4. Create the `codesrc` directory
5. Install Laravel in the `codesrc` folder with your selected version
6. Build and start all containers with your selected PHP version
7. Generate the application key

### Manual Setup

If you prefer to set up manually:

```bash
# Create codesrc directory
mkdir -p codesrc

# Install Laravel in codesrc folder
docker run --rm -v $(pwd)/codesrc:/var/www/html -w /var/www/html composer create-project laravel/laravel .

# Copy environment file
cp .env.example codesrc/.env

# Build and start containers
docker-compose up -d --build

# Generate application key
docker-compose exec app php artisan key:generate
```

## Access the Application

- **Application**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081

## Available Services

- **app**: FrankenPHP container (PHP 8.2 or 8.4 with embedded Caddy web server)
  - Includes: PHP, Composer, Node.js 20.x, npm (ready for Vue.js)
- **db**: MariaDB database
- **redis**: Redis cache/session store
- **phpmyadmin**: Database management interface

## Why FrankenPHP?

FrankenPHP provides:
- ⚡ **Faster performance** - Embedded web server reduces overhead
- 🚀 **Built-in worker mode** - Better concurrency handling
- 📦 **All-in-one** - No need for separate Nginx container
- 🔧 **Modern stack** - Based on Caddy web server

## Common Commands

### Run Artisan commands

```bash
docker-compose exec app php artisan [command]
# or with podman
podman compose exec app php artisan [command]
```

### Install Composer dependencies

```bash
docker-compose exec app composer install
# or with podman
podman compose exec app composer install
```

### Install NPM dependencies (for Vue.js and frontend assets)

```bash
docker-compose exec app npm install
# or with podman
podman compose exec app npm install
```

### Run NPM commands (Vite, Vue.js, etc.)

```bash
# Build assets
docker-compose exec app npm run build

# Watch for changes (development)
docker-compose exec app npm run dev

# Run any npm script
docker-compose exec app npm run [command]
```

### Access container shell

```bash
docker-compose exec app bash
```

### Stop containers

```bash
docker-compose down
```

### Stop and remove volumes

```bash
docker-compose down -v
```

## Database Configuration

The database is pre-configured (MariaDB):
- Host: `db`
- Port: `3306`
- Database: `laravel`
- Username: `root`
- Password: `root`

**Note:** Make sure to set `DB_CONNECTION=mariadb` in your Laravel `.env` file for MariaDB, or use `mysql` if you prefer (MariaDB is compatible with MySQL).

## Project Structure

```
laravel-docker/
├── codesrc/              # Laravel application code
│   ├── app/
│   ├── public/
│   ├── .env
│   └── ...
├── docker/               # Docker configuration
│   ├── caddy/
│   └── php/
├── docker-compose.yml
├── Dockerfile
└── setup.sh
```

## Notes

- The Laravel application code is in the `codesrc` folder, keeping it separate from Docker configuration files
- Application files are mounted as volumes, so changes are reflected immediately
- Make sure to run `php artisan key:generate` after setting up the environment
- For production, update the `.env` file with appropriate values
