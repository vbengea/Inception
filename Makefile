COMPOSE_FILE = srcs/docker-compose.yml
COMPOSE = docker compose -f $(COMPOSE_FILE)
DATA_PATH = /home/$(USER)/data

GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
RESET = \033[0m

all: up

dirs:
	@echo "$(GREEN)Creating data directories for volumes...$(RESET)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "$(GREEN)Created directories at:$(RESET)"
	@echo "  - $(DATA_PATH)/wordpress"
	@echo "  - $(DATA_PATH)/mariadb"

up: dirs
	@echo "$(GREEN)Starting containers in background...$(RESET)"
	@$(COMPOSE) up -d --build

down:
	@echo "$(RED)Stopping containers...$(RESET)"
	@$(COMPOSE) down

status:
	@echo "$(YELLOW)Containers status:$(RESET)"
	@docker ps -a

logs:
	@echo "$(YELLOW)Container logs:$(RESET)"
	@$(COMPOSE) logs

follow:
	@echo "$(YELLOW)Following logs in real-time (Ctrl+C to exit):$(RESET)"
	@$(COMPOSE) logs -f

clean: down
	@echo "$(RED)Removing volumes...$(RESET)"
	@$(COMPOSE) down -v
	@echo "$(RED)Removing unused images...$(RESET)"
	@docker image prune -af

clean-data: clean
	@echo "$(RED)Removing data directories...$(RESET)"
	@sudo rm -rf $(DATA_PATH)/wordpress
	@sudo rm -rf $(DATA_PATH)/mariadb
	@echo "$(RED)Data directories removed!$(RESET)"

rebuild: clean dirs up

restart: down up

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
