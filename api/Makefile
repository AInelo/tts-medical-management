# Makefile
.PHONY: help build dev prod test clean logs stop

# Couleurs
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

help: ## Affiche l'aide
	@echo "$(GREEN)TTS Medical API - Docker$(NC)"
	@echo "========================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(YELLOW)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build toutes les images
	@echo "$(GREEN)Build des images...$(NC)"
	docker build --target development -t tts-api:dev .
	docker build --target production -t tts-api:prod .

dev: ## Lance l'environnement de développement
	@echo "$(GREEN)Lancement développement...$(NC)"
	docker-compose up -d api-dev
	@echo "$(GREEN)✅ Dev: http://localhost:3000$(NC)"

prod: ## Lance l'environnement de production
	@echo "$(GREEN)Lancement production...$(NC)"
	docker-compose up -d api-prod
	@echo "$(GREEN)✅ Prod: http://localhost:3001$(NC)"

both: ## Lance dev et prod
	@echo "$(GREEN)Lancement dev + prod...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ Dev: http://localhost:3000 | Prod: http://localhost:3001$(NC)"

test: ## Test rapide
	@echo "$(GREEN)Test des builds...$(NC)"
	make build
	@echo "$(GREEN)Test de démarrage...$(NC)"
	docker run --rm -d --name test-api -p 8080:3000 tts-api:prod
	@sleep 3
	@echo "$(GREEN)API de test sur http://localhost:8080$(NC)"
	@docker stop test-api || true

logs: ## Affiche les logs
	docker-compose logs -f

logs-dev: ## Logs développement
	docker-compose logs -f api-dev

logs-prod: ## Logs production
	docker-compose logs -f api-prod

status: ## Statut des conteneurs
	@echo "$(GREEN)Conteneurs:$(NC)"
	docker-compose ps
	@echo "$(GREEN)Ressources:$(NC)"
	docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $$(docker-compose ps -q) 2>/dev/null || echo "Aucun conteneur"

stop: ## Arrête tous les services
	@echo "$(GREEN)Arrêt des services...$(NC)"
	docker-compose down

restart: ## Redémarre les services
	docker-compose restart

clean: ## Nettoie tout
	@echo "$(YELLOW)Nettoyage...$(NC)"
	docker-compose down -v
	docker system prune -f
	docker rmi tts-api:dev tts-api:prod 2>/dev/null || true

shell-dev: ## Shell dans le conteneur dev
	docker-compose exec api-dev sh

shell-prod: ## Shell dans le conteneur prod
	docker-compose exec api-prod sh

size: ## Taille des images
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|tts-api)"