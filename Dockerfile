ARG PHP_VERSION=8.2
# Use latest tag and let FrankenPHP handle PHP version, or use specific version tags
FROM dunglas/frankenphp:latest

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (for Vue.js and frontend assets)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy Caddyfile
COPY docker/caddy/Caddyfile /etc/caddy/Caddyfile

# Copy existing application directory permissions
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 and 443
EXPOSE 80
EXPOSE 443

# Start FrankenPHP
# Use the full path to frankenphp command
CMD ["/usr/local/bin/frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

