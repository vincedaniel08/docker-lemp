#!/bin/bash

# Laravel + React Docker Production Deployment Script
# Usage: ./deploy.sh [environment] [domain]
# Example: ./deploy.sh production myapp.com
# Make executable: chmod +x deploy.sh

set -e

# Default values
ENVIRONMENT=${1:-development}
DOMAIN=${2:-localhost}
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "All prerequisites satisfied ✅"
}

# Function to backup existing data
backup_data() {
    if [ "$ENVIRONMENT" = "production" ] && [ -d "mysql_data" ]; then
        print_step "Creating backup..."
        mkdir -p "$BACKUP_DIR"
        
        # Backup database
        if docker-compose ps mysql | grep -q "Up"; then
            print_status "Backing up database..."
            docker-compose exec -T mysql mysqldump -u root -p"${DB_ROOT_PASSWORD:-root_password}" --all-databases > "$BACKUP_DIR/database_backup.sql"
        fi
        
        # Backup storage files
        if [ -d "backend/storage" ]; then
            print_status "Backing up storage files..."
            cp -r backend/storage "$BACKUP_DIR/"
        fi
        
        print_status "Backup created at $BACKUP_DIR ✅"
    fi
}

# Function to setup environment files
setup_environment() {
    print_step "Setting up environment files..."
    
    # Create necessary directories
    mkdir -p nginx/ssl mysql/init logs
    
    # Laravel environment
    if [ ! -f backend/.env ]; then
        print_warning "Laravel .env file not found. Creating from .env.example..."
        if [ -f backend/.env.example ]; then
            cp backend/.env.example backend/.env
        else
            print_error "No .env.example found in backend directory!"
            exit 1
        fi
    fi
    
    # React environment
    if [ ! -f frontend/.env ]; then
        print_warning "React .env file not found. Creating one..."
        if [ "$ENVIRONMENT" = "production" ]; then
            echo "VITE_API_URL=https://$DOMAIN/api" > frontend/.env
        else
            echo "VITE_API_URL=http://localhost/api" > frontend/.env
        fi
    fi
    
    # Production environment variables
    if [ "$ENVIRONMENT" = "production" ]; then
        if [ ! -f .env.prod ]; then
            print_warning "Creating production environment file..."
            cat > .env.prod << EOF
# Production Environment Variables
DB_ROOT_PASSWORD=$(openssl rand -base64 32)
DB_USERNAME=laravel_user
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
DOMAIN=$DOMAIN
EOF
            print_status "Production .env.prod created. Please review and update if needed."
        fi
    fi
}

# Function to handle SSL certificates
setup_ssl() {
    if [ "$ENVIRONMENT" = "production" ] && [ "$DOMAIN" != "localhost" ]; then
        print_step "Setting up SSL certificates..."
        
        if [ ! -f nginx/ssl/fullchain.pem ] || [ ! -f nginx/ssl/privkey.pem ]; then
            print_warning "SSL certificates not found. You can:"
            echo "1. Use Let's Encrypt: sudo certbot certonly --standalone -d $DOMAIN"
            echo "2. Copy your existing certificates to nginx/ssl/"
            echo "3. Continue without SSL (not recommended for production)"
            
            read -p "Continue without SSL? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Please setup SSL certificates and run again."
                exit 1
            fi
        else
            print_status "SSL certificates found ✅"
        fi
    fi
}

# Function to deploy application
deploy_application() {
    print_step "Deploying application..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down
    
    # Choose compose file based on environment
    COMPOSE_FILE="docker-compose.yml"
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Compose file $COMPOSE_FILE not found!"
        exit 1
    fi
    
    # Build and start containers
    print_status "Building and starting containers..."
    if [ "$ENVIRONMENT" = "production" ]; then
        docker-compose -f "$COMPOSE_FILE" --env-file .env.prod up -d --build
    else
        docker-compose -f "$COMPOSE_FILE" up -d --build
    fi
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Health check
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql mysqladmin ping -h localhost --silent; then
            print_status "MySQL is ready ✅"
            break
        fi
        print_warning "Waiting for MySQL... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "MySQL failed to start properly"
        exit 1
    fi
}

# Function to setup Laravel
setup_laravel() {
    print_step "Setting up Laravel..."
    
    # Generate application key if not exists
    if ! docker-compose exec -T laravel php artisan config:show | grep -q "app.key"; then
        docker-compose exec -T laravel php artisan key:generate --force
    fi
    
    # Cache configuration
    docker-compose exec -T laravel php artisan config:cache
    
    # Run migrations
    print_status "Running database migrations..."
    docker-compose exec -T laravel php artisan migrate --force
    
    # Seed database (only in development)
    if [ "$ENVIRONMENT" != "production" ]; then
        print_status "Seeding database..."
        docker-compose exec -T laravel php artisan db:seed --force || true
    fi
    
    # Create storage link
    docker-compose exec -T laravel php artisan storage:link || true
    
    # Set permissions
    print_status "Setting permissions..."
    docker-compose exec -T laravel chown -R www-data:www-data /var/www/html/storage
    docker-compose exec -T laravel chown -R www-data:www-data /var/www/html/bootstrap/cache
    docker-compose exec -T laravel chmod -R 775 /var/www/html/storage
    docker-compose exec -T laravel chmod -R 775 /var/www/html/bootstrap/cache
}

# Function to run health checks
health_check() {
    print_step "Running health checks..."
    
    # Check if containers are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Some containers are not running properly"
        docker-compose ps
        exit 1
    fi
    
    # Check Laravel health
    if docker-compose exec -T laravel php artisan --version > /dev/null 2>&1; then
        print_status "Laravel is healthy ✅"
    else
        print_error "Laravel health check failed"
        exit 1
    fi
    
    # Check web access
    sleep 5
    if [ "$ENVIRONMENT" = "production" ]; then
        URL="https://$DOMAIN"
    else
        URL="http://localhost"
    fi
    
    if curl -f -s "$URL" > /dev/null; then
        print_status "Web application is accessible ✅"
    else
        print_warning "Web application might not be accessible at $URL"
    fi
}

# Function to display deployment summary
deployment_summary() {
    print_step "Deployment Summary"
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Environment: $ENVIRONMENT"
    echo "Domain: $DOMAIN"
    echo ""
    
    if [ "$ENVIRONMENT" = "production" ]; then
        echo "🌐 Application: https://$DOMAIN"
        echo "🔧 API: https://$DOMAIN/api"
    else
        echo "🌐 Application: http://localhost"
        echo "🔧 API: http://localhost/api"
        echo "⚡ Vite Dev Server: http://localhost:5173"
    fi
    
    echo ""
    echo "Useful commands:"
    echo "📊 View logs: docker-compose logs -f [service_name]"
    echo "🔧 Laravel commands: docker-compose exec laravel php artisan [command]"
    echo "🛑 Stop application: docker-compose down"
    echo "🔄 Restart: docker-compose restart [service_name]"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        echo ""
        echo "📁 Backup location: $BACKUP_DIR"
        echo "🔐 Environment file: .env.prod"
    fi
}

# Main execution flow
main() {
    echo "🚀 Starting deployment for $ENVIRONMENT environment..."
    echo ""
    
    check_prerequisites
    backup_data
    setup_environment
    setup_ssl
    deploy_application
    setup_laravel
    health_check
    deployment_summary
}

# Handle script interruption
trap 'print_error "Deployment interrupted!"; exit 1' INT TERM

# Run main function
main "$@"