.PHONY: help setup dev stop clean logs shell migrate test lint format

help:
	@echo "🎵 Jukebox Backend - Available Commands"
	@echo ""
	@echo "📦 Setup & Environment:"
	@echo "  make setup          - Initialize local environment (.env file)"
	@echo "  make install        - Install Python dependencies with Poetry"
	@echo ""
	@echo "🚀 Development:"
	@echo "  make dev            - Start development environment (Docker Compose)"
	@echo "  make dev-stop       - Stop development services"
	@echo "  make dev-logs       - Show development logs"
	@echo "  make dev-shell      - Open backend container shell"
	@echo ""
	@echo "🚢 Production:"
	@echo "  make prod           - Start production services"
	@echo "  make prod-stop      - Stop production services"
	@echo ""
	@echo "🗄️  Database:"
	@echo "  make migrate        - Run database migrations"
	@echo "  make migrate-create - Create new migration"
	@echo "  make migrate-reset  - Reset database (WARNING: destructive)"
	@echo ""
	@echo "🧪 Testing & Code Quality:"
	@echo "  make test           - Run tests"
	@echo "  make test-cov       - Run tests with coverage"
	@echo "  make lint           - Run linters (isort, black, flake8)"
	@echo "  make format         - Format code (isort + black)"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean          - Remove Docker containers and volumes"
	@echo "  make clean-all      - Complete cleanup (containers, volumes, venv)"
	@echo ""

setup:
	@if [ ! -f .env ]; then \
		echo "📋 Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "✅ .env created. Please edit it with your credentials:"; \
		echo "   nano .env"; \
	else \
		echo "✅ .env already exists"; \
	fi

install:
	@echo "📦 Installing Poetry dependencies..."
	poetry config virtualenvs.in-project true
	poetry env use 3.11
	poetry install
	@echo "✅ Dependencies installed"

dev: setup
	@echo "🚀 Starting development environment..."
	docker-compose -f docker-compose.local.yml up -d
	@echo "✅ Development environment started!"
	@echo ""
	@echo "📚 Available services:"
	@echo "  - Backend:   http://localhost:8000"
	@echo "  - API Docs:  http://localhost:8000/api/docs"
	@echo "  - ReDoc:     http://localhost:8000/api/redoc"
	@echo "  - PgAdmin:   http://localhost:5050 (admin@local.dev / admin)"
	@echo "  - Database:  localhost:5434 (postgres:postgres)"
	@echo ""
	@echo "Run 'make dev-logs' to see logs"

dev-stop:
	@echo "🛑 Stopping development environment..."
	docker-compose -f docker-compose.local.yml down
	@echo "✅ Development environment stopped"

dev-logs:
	docker-compose -f docker-compose.local.yml logs -f backend

dev-shell:
	docker-compose -f docker-compose.local.yml exec backend /bin/bash

prod:
	@echo "🚀 Starting production environment..."
	docker-compose -f docker-compose.prod.yml up -d
	@echo "✅ Production environment started!"

prod-stop:
	@echo "🛑 Stopping production environment..."
	docker-compose -f docker-compose.prod.yml down
	@echo "✅ Production environment stopped"

migrate:
	@echo "📊 Running migrations..."
	poetry run alembic upgrade head
	@echo "✅ Migrations applied"

migrate-create:
	@read -p "Enter migration name: " name; \
	poetry run alembic revision --autogenerate -m "$$name"
	@echo "✅ Migration created. Review and run 'make migrate' to apply"

migrate-reset:
	@echo "⚠️  WARNING: This will delete all database data!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		poetry run alembic downgrade base; \
		poetry run alembic upgrade head; \
		echo "✅ Database reset complete"; \
	else \
		echo "❌ Reset cancelled"; \
	fi

test:
	@echo "🧪 Running tests..."
	poetry run pytest -v

test-cov:
	@echo "🧪 Running tests with coverage..."
	poetry run pytest --cov=app --cov-report=html --cov-report=term

lint:
	@echo "📝 Running linters..."
	poetry run isort --check-only app/
	poetry run black --check app/
	poetry run flake8 app/

format:
	@echo "✨ Formatting code..."
	poetry run isort app/
	poetry run black app/
	@echo "✅ Code formatted"

clean:
	@echo "🧹 Cleaning Docker environment..."
	docker-compose -f docker-compose.local.yml down -v
	rm -rf pgdata_local/
	@echo "✅ Docker environment cleaned"

clean-all: clean
	@echo "🧹 Removing virtual environment..."
	rm -rf .venv/
	@echo "✅ Full cleanup complete"

.DEFAULT_GOAL := help
