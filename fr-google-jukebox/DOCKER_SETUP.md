# Docker Setup Guide

## Overview

The Jukebox backend supports three environment configurations:

1. **Local Development** (`docker-compose.local.yml`) - with hot reload and debugging
2. **Production Staging** (`docker-compose.yml`) - improved base config
3. **Production** (`docker-compose.prod.yml`) - for deployment scenarios

## Quick Start (Local Development)

### Option 1: Using the Start Script (Simplest)

```bash
./start-local.sh
```

This script will:
1. Create `.env` from `.env.example` if needed
2. Validate required environment variables
3. Start all Docker services
4. Display service URLs

### Option 2: Using Makefile

```bash
make setup   # Create .env
make dev     # Start development
```

### Option 3: Manual Docker Compose

```bash
# Create .env file
cp .env.example .env

# Edit and fill in credentials
nano .env

# Start services
docker-compose -f docker-compose.local.yml up -d

# View logs
docker-compose -f docker-compose.local.yml logs -f backend
```

## Environment Files Explained

### `docker-compose.local.yml` ✨ Recommended for Development

**Services:**
- **PostgreSQL (db)** - Main development database
- **PostgreSQL (db_test)** - Separate database for running tests
- **FastAPI Backend** - API service with hot reload
- **PgAdmin** - Web UI for database management (optional)

**Features:**
- 🔄 Hot reload: Changes in `app/` are reflected immediately
- 🐛 Debug port: Port 5678 for debugging with debugpy
- 📊 Database admin: PgAdmin on port 5050
- 📝 Mounted `.env` file: Changes are live
- 🏥 Health checks: Services wait for dependencies

**Volumes:**
- `./app:/code/app` - Live code sync
- `./.env:/code/.env` - Live config reload
- `pgdata_local/` - Persistent database data

### `docker-compose.yml` 🎯 Production/Staging Base

**Services:**
- **PostgreSQL (db & db_test)** only
- Improved with health checks and restart policies
- Suitable as base for both staging and production

**Use when:**
- Running only databases for local testing
- Staging environment similar to local

### `docker-compose.prod.yml` 🚀 Production Deployment

**Services:**
- **PostgreSQL (db & db_test)** with production settings
- Uses environment variables for credentials (not hardcoded)
- Restart policies for enhanced reliability
- Network isolation with custom bridge network

**Features:**
- Environment variable interpolation for sensitive data
- Named network for inter-service communication
- Named volumes for data persistence
- Restart policies for stability

## Services and Ports

### Local Development Environment

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| FastAPI Backend | http://localhost:8000 | 8000 | Main API |
| Swagger Docs | http://localhost:8000/api/docs | 8000 | Interactive API docs |
| ReDoc | http://localhost:8000/api/redoc | 8000 | Alternative API docs |
| PgAdmin | http://localhost:5050 | 5050 | Database admin UI |
| PostgreSQL (main) | localhost:5434 | 5434 | Main database |
| PostgreSQL (test) | localhost:5435 | 5435 | Test database |
| Debug Port | localhost:5678 | 5678 | Remote debugging (debugpy) |

**PgAdmin Credentials:**
- Email: `admin@local.dev`
- Password: `admin`

**Database Credentials:**
- User: `postgres`
- Password: `postgres`
- Main DB: `jukebox_db`
- Test DB: `jukebox_db_test`

## Makefile Commands

```bash
# Setup & Environment
make setup          # Initialize .env
make install        # Install Python dependencies

# Development
make dev            # Start dev environment
make dev-stop       # Stop dev environment
make dev-logs       # Show logs
make dev-shell      # Open bash in backend container

# Production
make prod           # Start production services
make prod-stop      # Stop production services

# Database
make migrate        # Run migrations
make test           # Run tests
make lint           # Check code quality
make format         # Auto-format code

# Cleanup
make clean          # Remove containers/volumes
make clean-all      # Remove everything including venv
```

## Dockerfile Variants

### `Dockerfile` (Production)

- Multi-stage build for smaller image
- Based on `python:3.11-slim`
- Installs only production dependencies
- No debug tools
- Suitable for Cloud Run, GKE, etc.

### `Dockerfile.local` (Development)

- Based on `python:3.11-slim`
- Includes development dependencies (pytest, debugpy, etc.)
- Includes debugpy for remote debugging
- Copies `.env` file explicitly
- Supports hot reload with `--reload`

## Common Workflows

### Starting Fresh Local Development

```bash
# 1. Clone repo and enter directory
cd fr-google-jukebox

# 2. Quick start with script
./start-local.sh

# 3. Open browser
# API: http://localhost:8000/api/docs
# Database Admin: http://localhost:5050
```

### Running Tests

```bash
# Using Makefile
make test

# Or with Docker
docker-compose -f docker-compose.local.yml exec backend pytest -v

# With coverage
docker-compose -f docker-compose.local.yml exec backend pytest --cov=app
```

### Debugging the API

```bash
# 1. Set breakpoint in your code
import debugpy
debugpy.breakpoint()

# 2. Connect from VS Code or IDE to localhost:5678
# 3. Debug in IDE while app runs in container
```

### Accessing Database

**Option 1: PgAdmin Web UI**
- Go to http://localhost:5050
- Login: admin@local.dev / admin
- Add server: host=db, port=5432, user=postgres, password=postgres

**Option 2: psql CLI**
```bash
docker-compose -f docker-compose.local.yml exec db psql -U postgres -d jukebox_db

# Then run SQL queries
\dt                    # List tables
SELECT * FROM users;   # Example query
\q                     # Quit
```

**Option 3: From Backend Container**
```bash
docker-compose -f docker-compose.local.yml exec backend python
# Then in Python:
from sqlalchemy import create_engine
engine = create_engine("postgresql://...")
```

### Stopping Everything

```bash
# Stop and remove containers
docker-compose -f docker-compose.local.yml down

# Stop and remove containers + volumes (clean slate)
docker-compose -f docker-compose.local.yml down -v

# Or use Makefile
make clean
```

### Viewing Logs

```bash
# Backend logs only
docker-compose -f docker-compose.local.yml logs -f backend

# All services
docker-compose -f docker-compose.local.yml logs -f

# Specific service
docker-compose -f docker-compose.local.yml logs -f db
```

## Production Deployment (Cloud Run)

When deploying to Cloud Run, use the main `Dockerfile` (not `.local`):

```bash
gcloud run deploy jukebox \
  --source . \
  --dockerfile Dockerfile \
  --set-env-vars "ENV=production,GCLOUD_PROJECT_ID=your-project" \
  ...
```

The backend will:
1. Read `ENV=production`
2. Fetch secrets from Google Secret Manager using `GCLOUD_PROJECT_NUMBER`
3. Connect to Cloud SQL or external PostgreSQL
4. Serve on port 8080

## Troubleshooting

### Backend won't start: "GEMINI_API_KEY not found"

**Solution:** Ensure `.env` is filled with actual credentials
```bash
# Check .env
cat .env | grep GEMINI_API_KEY

# Should show: GEMINI_API_KEY=actual-key-value
# Not: GEMINI_API_KEY=your-gemini-api-key-here
```

### Database connection refused: "connect() failed"

**Solution:** PostgreSQL container may not be ready
```bash
# Check if db container is running
docker-compose -f docker-compose.local.yml ps db

# Check db logs
docker-compose -f docker-compose.local.yml logs db

# Wait and retry (healthchecks should handle this automatically)
```

### Port 8000 already in use

**Solution:** Stop other services using that port
```bash
# Find process using port 8000
lsof -i :8000

# Kill it or change the port in docker-compose.local.yml
```

### Permission denied on `start-local.sh`

**Solution:** Make it executable
```bash
chmod +x start-local.sh
./start-local.sh
```

## Best Practices

✅ **Do:**
- Use `.env.example` as a template
- Keep sensitive data in `.env` (not in git)
- Use `make dev` or `start-local.sh` for consistency
- Run migrations before running tests
- Check logs before reporting issues

❌ **Don't:**
- Commit `.env` to git (it's in `.gitignore`)
- Change docker-compose.local.yml ports without updating `.env`
- Use production database for development
- Leave containers running when not developing

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.local.yml` | Local development config |
| `docker-compose.yml` | Production/staging base config |
| `docker-compose.prod.yml` | Production deployment config |
| `Dockerfile` | Production image (Cloud Run) |
| `Dockerfile.local` | Development image (with debugpy) |
| `Makefile` | Convenient make commands |
| `start-local.sh` | Quick start script |
| `.env.example` | Template for environment variables |
| `.env` | Local secrets (not in git) |

---

**Last updated:** 18 Feb 2026
**Questions?** Check the README.md for backend-specific setup instructions.
