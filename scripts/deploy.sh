#!/bin/bash

# scripts/deploy.sh
# Script de déploiement de l'application TTS Medical API

set -e

# Paramètres
IMAGE_NAME=${1:-tts-medical-api}
CONTAINER_NAME=${2:-tts-medical-backend}
PORT=${3:-5100}

echo "🚀 Début du déploiement..."
echo "📋 Image: $IMAGE_NAME"
echo "📋 Conteneur: $CONTAINER_NAME" 
echo "📋 Port: $PORT"
echo "================================"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction de vérification d'erreur
check_error() {
    if [ $? -ne 0 ]; then
        log "❌ Erreur: $1"
        exit 1
    fi
}

# Étape 1: Backup de l'ancien conteneur
log "💾 [1/6] Sauvegarde de l'ancien conteneur..."
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker commit $CONTAINER_NAME $IMAGE_NAME:backup-$(date +%Y%m%d-%H%M%S) || true
    log "✅ Backup créé"
else
    log "ℹ️  Aucun conteneur existant à sauvegarder"
fi

# Étape 2: Construction de l'image
log "🐳 [2/6] Construction de l'image Docker..."
cd ~/tts-medical-management/api
docker build \
    --target production \
    --tag $IMAGE_NAME:latest \
    --tag $IMAGE_NAME:$(date +%Y%m%d-%H%M%S) \
    .
check_error "Construction de l'image Docker"

# Étape 3: Test de l'image
log "🧪 [3/6] Test de la nouvelle image..."
docker run --rm --name ${CONTAINER_NAME}-test \
    -e NODE_ENV=production \
    -e PORT=$PORT \
    $IMAGE_NAME:latest node -e "console.log('✅ Image test successful')"
check_error "Test de l'image"

# Étape 4: Arrêt de l'ancien conteneur
log "🛑 [4/6] Arrêt de l'ancien conteneur..."
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker stop $CONTAINER_NAME
    log "✅ Conteneur arrêté"
    sleep 2
else
    log "ℹ️  Aucun conteneur en cours d'exécution"
fi

# Suppression de l'ancien conteneur
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker rm $CONTAINER_NAME
    log "✅ Ancien conteneur supprimé"
fi

# Étape 5: Démarrage du nouveau conteneur
log "🚀 [5/6] Démarrage du nouveau conteneur..."
docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:$PORT \
    --restart unless-stopped \
    --memory="512m" \
    --cpus="0.5" \
    -e NODE_ENV=production \
    -e PORT=$PORT \
    $IMAGE_NAME:latest
check_error "Démarrage du conteneur"

# Étape 6: Vérification
log "✅ [6/6] Vérification du déploiement..."
sleep 15

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "✅ Conteneur démarré avec succès"
    echo "📋 Logs du conteneur (dernières 10 lignes):"
    docker logs --tail=10 $CONTAINER_NAME
else
    log "❌ Échec du démarrage du conteneur"
    echo "📋 Logs d'erreur:"
    docker logs $CONTAINER_NAME 2>&1 || true
    exit 1
fi

# Test de connectivité
log "🔍 Test de connectivité..."
sleep 5
if curl -f -s --max-time 10 http://localhost:$PORT/api/ >/dev/null 2>&1; then
    log "✅ API accessible sur /api/"
elif curl -f -s --max-time 10 http://localhost:$PORT/ >/dev/null 2>&1; then
    log "✅ Application accessible"
else
    log "⚠️  Application en cours de démarrage - vérification manuelle recommandée"
fi

log "🎉 Déploiement terminé avec succès !"
echo "================================"