#!/bin/bash

# scripts/status.sh
# Script d'affichage du statut de déploiement

set -e

CONTAINER_NAME=${1:-tts-medical-backend}

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

echo "📊 RÉSUMÉ DU DÉPLOIEMENT"
echo "========================="

# Informations sur le conteneur
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🐳 Conteneur: $(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep $CONTAINER_NAME)"
    
    # Statistiques de performance
    STATS=$(docker stats --no-stream --format '{{.MemUsage}}\t{{.CPUPerc}}' $CONTAINER_NAME 2>/dev/null)
    if [ -n "$STATS" ]; then
        MEM_USAGE=$(echo "$STATS" | cut -f1)
        CPU_USAGE=$(echo "$STATS" | cut -f2)
        echo "💾 Utilisation mémoire: $MEM_USAGE"
        echo "📈 CPU: $CPU_USAGE"
    fi
    
    # Informations sur l'image
    IMAGE_SIZE=$(docker images tts-medical-api:latest --format '{{.Size}}' 2>/dev/null)
    if [ -n "$IMAGE_SIZE" ]; then
        echo "🏷️  Taille de l'image: $IMAGE_SIZE"
    fi
    
    # Temps de démarrage
    START_TIME=$(docker inspect $CONTAINER_NAME --format='{{.State.StartedAt}}' 2>/dev/null)
    if [ -n "$START_TIME" ]; then
        echo "⏰ Démarré le: $START_TIME"
    fi
    
    # Logs récents
    echo ""
    echo "📋 Logs récents (5 dernières lignes):"
    docker logs --tail=5 $CONTAINER_NAME 2>/dev/null || echo "   Aucun log disponible"
    
else
    echo "❌ Conteneur $CONTAINER_NAME non trouvé ou arrêté"
    
    # Vérifier si le conteneur existe mais est arrêté
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "⚠️  Le conteneur existe mais est arrêté"
        echo "📋 Statut: $(docker ps -a --format '{{.Status}}' | grep $CONTAINER_NAME)"
        echo "📋 Logs d'erreur:"
        docker logs --tail=10 $CONTAINER_NAME 2>&1 || echo "   Aucun log disponible"
    fi
    exit 1
fi

# État de NGINX
echo ""
echo "🌐 État de NGINX:"
if sudo systemctl is-active --quiet nginx 2>/dev/null; then
    echo "   ✅ NGINX actif"
    
    # Test de connectivité
    if curl -f -s --max-time 5 http://localhost:5100/api/ >/dev/null 2>&1; then
        echo "   ✅ API locale accessible"
    else
        echo "   ⚠️  API locale non accessible"
    fi
    
    if curl -f -s --max-time 5 https://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
        echo "   ✅ API publique (HTTPS) accessible"
    elif curl -f -s --max-time 5 http://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
        echo "   ✅ API publique (HTTP) accessible"
    else
        echo "   ⚠️  API publique non accessible"
    fi
else
    echo "   ❌ NGINX inactif"
fi

# Utilisation du système
echo ""
echo "💻 Utilisation du système:"
echo "   📊 CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% utilisé"
echo "   💾 RAM: $(free -h | grep '^Mem:' | awk '{printf "%.1f%%", ($3/$2)*100}')"
echo "   💿 Disque: $(df -h / | tail -1 | awk '{print $5}')"

# URLs de test
echo ""
echo "🌐 URLs à tester:"
echo "   - API locale: http://localhost:5100/api/"
echo "   - API publique: https://collection.urmaphalab.com/api/"
echo "   - HTTP redirect: http://collection.urmaphalab.com/api/"

echo ""
echo "========================="
log "✅ Rapport de statut terminé"