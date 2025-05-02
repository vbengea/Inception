# Variables
COMPOSE_FILE = srcs/docker-compose.yml
COMPOSE = docker compose -f $(COMPOSE_FILE)
DATA_PATH = /home/$(USER)/data

# Colors for terminal output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
RESET = \033[0m

# Main rules
all: up

# Create data directories for volumes
dirs:
	@echo "$(GREEN)Creating data directories for volumes...$(RESET)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "$(GREEN)Created directories at:$(RESET)"
	@echo "  - $(DATA_PATH)/wordpress"
	@echo "  - $(DATA_PATH)/mariadb"

# Start containers in detached mode (background)
up: dirs
	@echo "$(GREEN)Starting containers in background...$(RESET)"
	@$(COMPOSE) up -d --build

# Stop containers
down:
	@echo "$(RED)Stopping containers...$(RESET)"
	@$(COMPOSE) down

# Show container status
status:
	@echo "$(YELLOW)Containers status:$(RESET)"
	@docker ps -a

# Show logs
logs:
	@echo "$(YELLOW)Container logs:$(RESET)"
	@$(COMPOSE) logs

# Follow logs in real-time
follow:
	@echo "$(YELLOW)Following logs in real-time (Ctrl+C to exit):$(RESET)"
	@$(COMPOSE) logs -f

# Clean everything (containers, volumes, images)
clean: down
	@echo "$(RED)Removing volumes...$(RESET)"
	@$(COMPOSE) down -v
	@echo "$(RED)Removing unused images...$(RESET)"
	@docker image prune -af

# Clean data directories (USE WITH CAUTION!)
clean-data: clean
	@echo "$(RED)Removing data directories...$(RESET)"
	@rm -rf $(DATA_PATH)/wordpress
	@rm -rf $(DATA_PATH)/mariadb
	@echo "$(RED)Data directories removed!$(RESET)"

# Force rebuild of all containers
rebuild: clean dirs up

# Restart all containers
restart: down up

# Help rule
help:
	@echo "$(GREEN)Available commands:$(RESET)"
	@echo "  make dirs      - Create necessary directories for volumes"
	@echo "  make up        - Start containers in background"
	@echo "  make down      - Stop containers"
	@echo "  make status    - Show container status"
	@echo "  make logs      - Show container logs"
	@echo "  make follow    - Follow container logs in real-time"
	@echo "  make clean     - Remove all containers, volumes and images"
	@echo "  make clean-data - Remove all data directories (CAUTION!)"
	@echo "  make rebuild   - Force rebuild of all containers"
	@echo "  make restart   - Restart all containers"

.PHONY: all dirs up down status logs follow clean clean-data rebuild restart help