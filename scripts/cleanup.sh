#!/bin/bash

# scripts/cleanup.sh
# Script de nettoyage des anciennes images Docker

set -e

IMAGE_NAME=${1:-tts-medical-api}

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🧹 Début du nettoyage..."

# Supprimer les anciennes images (garder les 3 plus récentes)
log "🗑️  Suppression des anciennes images $IMAGE_NAME..."

# Lister toutes les images avec tags de date et les trier
OLD_IMAGES=$(docker images $IMAGE_NAME --format "{{.Tag}}" | \
            grep -E '^[0-9]{8}-[0-9]{6}$' | \
            sort -r | \
            tail -n +4)

if [ -n "$OLD_IMAGES" ]; then
    for tag in $OLD_IMAGES; do
        log "🗑️  Suppression de l'image $IMAGE_NAME:$tag"
        docker rmi "$IMAGE_NAME:$tag" || true
    done
    log "✅ Anciennes images supprimées"
else
    log "ℹ️  Aucune ancienne image à supprimer"
fi

# Supprimer les images de backup anciennes (garder les 2 plus récentes)
log "🗑️  Nettoyage des images de backup..."
OLD_BACKUPS=$(docker images $IMAGE_NAME --format "{{.Tag}}" | \
             grep -E '^backup-[0-9]{8}-[0-9]{6}$' | \
             sort -r | \
             tail -n +3)

if [ -n "$OLD_BACKUPS" ]; then
    for tag in $OLD_BACKUPS; do
        log "🗑️  Suppression du backup $IMAGE_NAME:$tag"
        docker rmi "$IMAGE_NAME:$tag" || true
    done
    log "✅ Anciens backups supprimés"
else
    log "ℹ️  Aucun ancien backup à supprimer"
fi

# Nettoyage général Docker (conservateur)
log "🧽 Nettoyage général Docker..."
docker system prune -f --volumes=false 2>/dev/null || true

# Statistiques finales
log "📊 Statistiques après nettoyage:"
echo "🐳 Images Docker restantes:"
docker images $IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "Aucune image trouvée"

echo "💾 Espace disque libéré:"
df -h / | tail -1 | awk '{print "   Disponible: " $4 " (" $5 " utilisé)"}'

log "✅ Nettoyage terminé"