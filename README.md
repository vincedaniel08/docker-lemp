# Laravel + React Full Stack Application

A modern full-stack web application built with Laravel backend API and React frontend, containerized with Docker for easy deployment and development.

## 🚀 Features

- **Backend**: Laravel 10+ with PHP 8.2
- **Frontend**: React 18+ with Vite
- **Database**: MySQL 8.0
- **Caching**: Redis
- **Web Server**: Nginx (reverse proxy)
- **Containerization**: Docker & Docker Compose
- **Development**: Hot Module Replacement (HMR)
- **Production**: Optimized builds with SSL support

## 📋 Prerequisites

### For Docker Deployment (Recommended)
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- 4GB+ RAM
- 10GB+ storage

### For LEMP Stack Deployment
- Linux server (Ubuntu 20.04+ / CentOS 8+)
- Nginx
- MySQL 8.0+ / MariaDB 10.3+
- PHP 8.1+ with extensions: `pdo_mysql`, `mbstring`, `xml`, `gd`, `zip`, `redis`
- Composer
- Node.js 16+ & npm
- Redis (optional)

## 🛠 Installation & Setup

### Quick Start with Docker

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/yourproject.git
   cd yourproject
   ```

2. **Make deployment script executable:**
   ```bash
   chmod +x deploy.sh
   ```

3. **Deploy for development:**
   ```bash
   ./deploy.sh development
   ```

4. **Deploy for production:**
   ```bash
   ./deploy.sh production yourdomain.com
   ```

### Manual Setup

#### Backend Setup (Laravel)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   composer install
   ```

3. **Environment configuration:**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. **Configure database in `.env`:**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=laravel_db
   DB_USERNAME=your_username
   DB_PASSWORD=your_password
   ```

5. **Run migrations:**
   ```bash
   php artisan migrate
   php artisan db:seed
   ```

#### Frontend Setup (React)

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment configuration:**
   ```bash
   echo "VITE_API_URL=http://localhost:8000/api" > .env
   ```

4. **Start development server:**
   ```bash
   npm run dev
   ```

## 🐳 Docker Configuration

### Development Environment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production Environment

```bash
# Deploy with SSL
./deploy.sh production yourdomain.com

# Or manually:
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## 🌐 Deployment Options

### Option 1: Docker Deployment (Recommended)

**Advantages:**
- ✅ Consistent environments
- ✅ Easy scaling
- ✅ Isolated dependencies
- ✅ Simple rollbacks

**Quick Commands:**
```bash
# Development
./deploy.sh development

# Production
./deploy.sh production yourdomain.com

# With existing LEMP (different ports)
./deploy.sh development localhost
# Access: http://localhost:8080
```

### Option 2: LEMP Stack Deployment

**For servers with existing LEMP stack:**

```bash
# Make LEMP deployment script executable
chmod +x deploy-lemp.sh

# Deploy to existing LEMP
./deploy-lemp.sh yourdomain.com
```

### Option 3: Nginx Reverse Proxy

**Use existing Nginx to proxy to Docker containers:**

1. Deploy Docker containers on different ports
2. Configure Nginx virtual host
3. Point domain to Nginx proxy

## 🔧 Configuration Files

### Docker Compose Files

- `docker-compose.yml` - Development environment
- `docker-compose.prod.yml` - Production environment with SSL, health checks, and monitoring

### Nginx Configuration

- `nginx/nginx.conf` - Development proxy configuration
- `nginx/nginx.prod.conf` - Production configuration with SSL

### Environment Files

- `backend/.env` - Laravel configuration
- `frontend/.env` - React environment variables
- `.env.prod` - Production Docker environment

## 📱 Application URLs

### Development
- **Frontend**: http://localhost (Nginx proxy) or http://localhost:5173 (Vite direct)
- **Backend API**: http://localhost/api
- **Laravel Direct**: http://localhost:8000

### Production
- **Application**: https://yourdomain.com
- **API**: https://yourdomain.com/api

## 🔍 API Documentation

### Authentication Endpoints
```
POST /api/register
POST /api/login
POST /api/logout
GET  /api/user
```

### Example API Request
```bash
# Register user
curl -X POST http://localhost/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

## 🗄️ Database

### Default Credentials (Development)
- **Host**: localhost
- **Port**: 3306 (Docker: 3307 if avoiding conflicts)
- **Database**: laravel_db
- **Username**: laravel_user
- **Password**: laravel_password

### Migrations
```bash
# Run migrations
docker-compose exec laravel php artisan migrate

# Rollback migrations
docker-compose exec laravel php artisan migrate:rollback

# Seed database
docker-compose exec laravel php artisan db:seed
```

## 🚀 Development Workflow

### Starting Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access Laravel container
docker-compose exec laravel bash

# Access database
docker-compose exec mysql mysql -u laravel_user -p laravel_db
```

### Making Changes

**Backend (Laravel):**
- Changes are automatically reflected (volume mounted)
- Clear cache: `docker-compose exec laravel php artisan cache:clear`

**Frontend (React):**
- Hot Module Replacement (HMR) enabled
- Changes reflect instantly in browser

### Running Tests
```bash
# Laravel tests
docker-compose exec laravel php artisan test

# React tests
docker-compose exec react npm run test
```

## 🔒 Security Features

### Production Security
- ✅ SSL/TLS encryption
- ✅ Security headers (XSS, CSRF, etc.)
- ✅ Rate limiting
- ✅ Environment variable encryption
- ✅ Database user restrictions
- ✅ File upload validation

### Development Security
- ✅ CORS configuration
- ✅ Debug mode controls
- ✅ Local environment isolation

## 📊 Monitoring & Logs

### Log Locations
```bash
# Application logs
./logs/laravel/laravel.log
./logs/nginx/access.log
./logs/nginx/error.log

# Container logs
docker-compose logs [service_name]
```

### Health Checks
```bash
# Check all services
docker-compose ps

# Health check endpoints
curl http://localhost/api/health
curl http://localhost/health
```

## 🔧 Troubleshooting

### Common Issues

**1. Port Conflicts**
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80

# Use different ports in docker-compose.yml
ports:
  - "8080:80"  # Access via localhost:8080
```

**2. Permission Issues**
```bash
# Fix Laravel permissions
docker-compose exec laravel chown -R www-data:www-data storage bootstrap/cache
docker-compose exec laravel chmod -R 775 storage bootstrap/cache
```

**3. Database Connection**
```bash
# Check MySQL container
docker-compose logs mysql

# Test connection
docker-compose exec laravel php artisan migrate:status
```

**4. SSL Certificate Issues**
```bash
# Generate self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/privkey.pem \
  -out nginx/ssl/fullchain.pem
```

### Debug Commands
```bash
# View all containers
docker ps -a

# Inspect container
docker inspect [container_name]

# Enter container shell
docker exec -it [container_name] bash

# View resource usage
docker stats
```

## 🔄 Updates & Maintenance

### Updating Application
```bash
# Pull latest changes
git pull origin main

# Redeploy
./deploy.sh production yourdomain.com
```

### Database Backup
```bash
# Create backup
docker-compose exec mysql mysqldump -u root -p laravel_db > backup.sql

# Restore backup
docker-compose exec -T mysql mysql -u root -p laravel_db < backup.sql
```

### Scaling Services
```bash
# Scale queue workers
docker-compose up -d --scale queue=3

# Scale with different compose file
docker-compose -f docker-compose.prod.yml up -d --scale queue=5
```

## 📚 Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [React Documentation](https://react.dev)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/yourproject/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/yourproject/discussions)
- **Email**: support@yourdomain.com

## 🎯 Roadmap

- [ ] Add automated testing pipeline
- [ ] Implement CI/CD with GitHub Actions
- [ ] Add monitoring dashboard
- [ ] WebSocket support for real-time features
- [ ] Mobile app with React Native
- [ ] API rate limiting and throttling
- [ ] Advanced caching strategies

---

## Quick Reference

### Essential Commands
```bash
# Start development
./deploy.sh development

# Start production
./deploy.sh production yourdomain.com

# View logs
docker-compose logs -f

# Laravel commands
docker-compose exec laravel php artisan [command]

# Stop everything
docker-compose down
```

### Directory Structure
```
├── backend/              # Laravel application
│   ├── app/             # Application code
│   ├── config/          # Configuration files
│   ├── database/        # Migrations and seeds
│   └── routes/          # API routes
├── frontend/            # React application
│   ├── src/             # Source code
│   ├── public/          # Static assets
│   └── package.json     # Dependencies
├── nginx/               # Nginx configuration
├── docker-compose.yml   # Development containers
├── docker-compose.prod.yml # Production containers
├── deploy.sh            # Deployment script
└── README.md           # This file
```

**Happy coding! 🚀**
