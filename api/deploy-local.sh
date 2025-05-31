#!/bin/bash
# deploy-local.sh - Script pour tester le déploiement localement

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="tts-medical-api"
CONTAINER_NAME="tts-medical-backend"
PORT=3000

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Fonction de simulation du déploiement
simulate_deployment() {
    log_step "🚀 Simulation du déploiement en local..."
    
    # Vérification des prérequis
    log_info "Vérification des prérequis..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    # Build de l'image
    log_step "🐳 [1/6] Construction de l'image Docker..."
    if docker build --target production -t ${IMAGE_NAME}:latest .; then
        log_info "✅ Image construite avec succès"
    else
        log_error "❌ Échec de la construction de l'image"
        exit 1
    fi
    
    # Test de l'image
    log_step "🧪 [2/6] Test de l'image..."
    if docker run --rm --name ${CONTAINER_NAME}-test \
        -e NODE_ENV=production \
        ${IMAGE_NAME}:latest node -e "console.log('✅ Image test successful')"; then
        log_info "✅ Test de l'image réussi"
    else
        log_error "❌ Test de l'image échoué"
        exit 1
    fi
    
    # Sauvegarde de l'ancien conteneur
    log_step "💾 [3/6] Sauvegarde de l'ancien conteneur..."
    if docker ps -a | grep -q ${CONTAINER_NAME}; then
        docker commit ${CONTAINER_NAME} ${IMAGE_NAME}:backup-$(date +%Y%m%d-%H%M%S) || true
        log_info "✅ Sauvegarde créée"
    else
        log_info "Aucun conteneur existant à sauvegarder"
    fi
    
    # Arrêt de l'ancien conteneur
    log_step "🛑 [4/6] Arrêt de l'ancien conteneur..."
    if docker ps | grep -q ${CONTAINER_NAME}; then
        docker stop ${CONTAINER_NAME} || true
        sleep 2
    fi
    docker rm ${CONTAINER_NAME} || true
    log_info "✅ Ancien conteneur nettoyé"
    
    # Démarrage du nouveau conteneur
    log_step "🚀 [5/6] Démarrage du nouveau conteneur..."
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:${PORT} \
        --restart unless-stopped \
        --memory="512m" \
        --cpus="0.5" \
        -e NODE_ENV=production \
        -e PORT=${PORT} \
        ${IMAGE_NAME}:latest
    
    # Vérification
    log_step "✅ [6/6] Vérification du déploiement..."
    sleep 10
    
    if docker ps | grep -q ${CONTAINER_NAME}; then
        log_info "✅ Conteneur démarré avec succès"
        echo ""
        log_info "📊 STATUT DU CONTENEUR:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ${CONTAINER_NAME}
        echo ""
        log_info "📈 UTILISATION RESSOURCES:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" ${CONTAINER_NAME}
        echo ""
        log_info "📝 DERNIERS LOGS:"
        docker logs --tail=10 ${CONTAINER_NAME}
    else
        log_error "❌ Échec du démarrage du conteneur"
        docker logs ${CONTAINER_NAME} || true
        exit 1
    fi
    
    # Test de connectivité
    log_info "🔍 Test de connectivité..."
    sleep 5
    if curl -f -s --max-time 10 http://localhost:${PORT}/ > /dev/null 2>&1; then
        log_info "✅ API accessible sur http://localhost:${PORT}"
    else
        log_warn "⚠️  API non accessible sur la route / (normal si pas de route définie)"
        log_info "Vous pouvez tester avec: curl http://localhost:${PORT}/your-endpoint"
    fi
    
    log_info "🎉 Simulation de déploiement terminée avec succès !"
}

# Fonction de nettoyage
cleanup() {
    log_step "🧹 Nettoyage..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    
    # Nettoyage des anciennes images (garder les 3 dernières)
    docker images ${IMAGE_NAME} --format "{{.Tag}}" | grep -E '^backup-[0-9]{8}-[0-9]{6}$' | sort -r | tail -n +4 | xargs -r -I {} docker rmi ${IMAGE_NAME}:{} || true
    
    log_info "✅ Nettoyage terminé"
}

# Fonction de rollback
rollback() {
    log_step "🔄 Rollback vers la dernière sauvegarde..."
    
    # Trouver la dernière sauvegarde
    LAST_BACKUP=$(docker images ${IMAGE_NAME} --format "{{.Tag}}" | grep -E '^backup-[0-9]{8}-[0-9]{6}$' | sort -r | head -1)
    
    if [ -z "$LAST_BACKUP" ]; then
        log_error "❌ Aucune sauvegarde trouvée"
        exit 1
    fi
    
    log_info "Rollback vers: ${IMAGE_NAME}:${LAST_BACKUP}"
    
    # Arrêter le conteneur actuel
    docker stop ${CONTAINER_NAME} || true
    docker rm ${CONTAINER_NAME} || true
    
    # Démarrer avec l'ancienne image
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:${PORT} \
        --restart unless-stopped \
        --memory="512m" \
        --cpus="0.5" \
        -e NODE_ENV=production \
        -e PORT=${PORT} \
        ${IMAGE_NAME}:${LAST_BACKUP}
    
    log_info "✅ Rollback terminé"
}

# Fonction de monitoring
monitor() {
    log_step "📊 Monitoring du conteneur..."
    
    if ! docker ps | grep -q ${CONTAINER_NAME}; then
        log_error "❌ Conteneur non actif"
        exit 1
    fi
    
    echo "Appuyez sur Ctrl+C pour arrêter le monitoring"
    echo ""
    
    while true; do
        clear
        echo -e "${BLUE}=== MONITORING TTS MEDICAL API ===${NC}"
        echo "Heure: $(date)"
        echo ""
        
        echo -e "${GREEN}STATUT CONTENEUR:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|${CONTAINER_NAME})"
        echo ""
        
        echo -e "${GREEN}RESSOURCES:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" ${CONTAINER_NAME}
        echo ""
        
        echo -e "${GREEN}DERNIERS LOGS:${NC}"
        docker logs --tail=5 ${CONTAINER_NAME}
        echo ""
        
        sleep 5
    done
}

# Menu principal
case "${1:-}" in
    "deploy")
        simulate_deployment
        ;;
    "cleanup")
        cleanup
        ;;
    "rollback")
        rollback
        ;;
    "monitor")
        monitor
        ;;
    "logs")
        docker logs -f ${CONTAINER_NAME}
        ;;
    "status")
        if docker ps | grep -q ${CONTAINER_NAME}; then
            echo -e "${GREEN}✅ Conteneur actif${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ${CONTAINER_NAME}
            echo ""
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" ${CONTAINER_NAME}
        else
            echo -e "${RED}❌ Conteneur inactif${NC}"
        fi
        ;;
    *)
        echo -e "${BLUE}🚀 Script de déploiement TTS Medical API${NC}"
        echo ""
        echo "Usage: $0 {deploy|cleanup|rollback|monitor|logs|status}"
        echo ""
        echo "Commandes disponibles:"
        echo "  deploy   - Simule le déploiement complet"
        echo "  cleanup  - Nettoie les conteneurs et images"
        echo "  rollback - Revient à la dernière sauvegarde"
        echo "  monitor  - Surveille le conteneur en temps réel"
        echo "  logs     - Affiche les logs en temps réel"
        echo "  status   - Affiche le statut actuel"
        echo ""
        echo "Exemples:"
        echo "  $0 deploy    # Déploie l'application"
        echo "  $0 monitor   # Surveille l'application"
        echo "  $0 logs      # Suit les logs"
        ;;
esac