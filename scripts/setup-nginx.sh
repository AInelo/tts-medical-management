#!/bin/bash

# scripts/setup-nginx.sh
# Script de configuration NGINX pour TTS Medical API

set -e

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Configuration NGINX..."

PROJECT_DIR="$HOME/tts-medical-management"
NGINX_CONFIG=""

# Recherche du fichier de configuration NGINX
if [ -f "$PROJECT_DIR/nginx/tts-medical.conf" ]; then
    NGINX_CONFIG="$PROJECT_DIR/nginx/tts-medical.conf"
elif [ -f "$PROJECT_DIR/api/nginx.conf" ]; then
    NGINX_CONFIG="$PROJECT_DIR/api/nginx.conf"
elif [ -f "$PROJECT_DIR/tts-medical.conf" ]; then
    NGINX_CONFIG="$PROJECT_DIR/tts-medical.conf"
fi

if [ -n "$NGINX_CONFIG" ]; then
    log "✅ Configuration NGINX trouvée: $NGINX_CONFIG"
    
    # Créer les répertoires nécessaires
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    
    # Sauvegarder l'ancienne configuration si elle existe
    if [ -f "/etc/nginx/sites-available/tts-medical.conf" ]; then
        sudo cp /etc/nginx/sites-available/tts-medical.conf \
                /etc/nginx/sites-available/tts-medical.conf.backup.$(date +%Y%m%d-%H%M%S)
        log "✅ Ancienne configuration sauvegardée"
    fi
    
    # Copier la nouvelle configuration
    sudo cp "$NGINX_CONFIG" /etc/nginx/sites-available/tts-medical.conf
    log "✅ Configuration copiée"
    
    # Créer le lien symbolique
    sudo ln -sf /etc/nginx/sites-available/tts-medical.conf /etc/nginx/sites-enabled/tts-medical.conf
    log "✅ Lien symbolique créé"
    
    # Supprimer la configuration par défaut si elle existe
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        sudo rm -f /etc/nginx/sites-enabled/default
        log "✅ Configuration par défaut supprimée"
    fi
    
    # Test de la configuration NGINX
    log "🧪 Test de la configuration NGINX..."
    if sudo nginx -t; then
        log "✅ Configuration NGINX valide"
        
        # Recharger NGINX
        sudo systemctl reload nginx
        log "✅ NGINX rechargé avec succès"
        
        # Vérifier le statut de NGINX
        if sudo systemctl is-active --quiet nginx; then
            log "✅ NGINX est actif et fonctionne"
        else
            log "⚠️  NGINX n'est pas actif, tentative de démarrage..."
            sudo systemctl start nginx
            if sudo systemctl is-active --quiet nginx; then
                log "✅ NGINX démarré avec succès"
            else
                log "❌ Impossible de démarrer NGINX"
                sudo systemctl status nginx --no-pager -l
                exit 1
            fi
        fi
    else
        log "❌ Erreur dans la configuration NGINX"
        echo "📋 Détails de l'erreur:"
        sudo nginx -t 2>&1
        log "⚠️  Déploiement continué sans rechargement NGINX"
        exit 1
    fi
    
    # Test final de connectivité
    log "🔍 Test de connectivité HTTPS..."
    sleep 5
    if curl -f -s --max-time 10 https://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
        log "✅ HTTPS accessible"
    elif curl -f -s --max-time 10 http://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
        log "✅ HTTP accessible (HTTPS peut nécessiter plus de temps)"
    else
        log "⚠️  Test de connectivité externe - vérification manuelle recommandée"
    fi
    
else
    log "⚠️  Aucun fichier de configuration NGINX trouvé"
    echo "📂 Contenu du répertoire projet:"
    ls -la "$PROJECT_DIR/" 2>/dev/null || echo "Répertoire projet non trouvé"
    
    if [ -d "$PROJECT_DIR/nginx" ]; then
        echo "📂 Contenu du répertoire nginx:"
        ls -la "$PROJECT_DIR/nginx/"
    fi
    
    log "⚠️  Configuration NGINX ignorée"
fi

log "🔧 Configuration NGINX terminée"