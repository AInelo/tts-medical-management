#!/bin/bash

# scripts/setup-nginx.sh
# Script de configuration NGINX pour TTS Medical API avec SSL Certbot

set -e

# Configuration
DOMAIN="${DOMAIN:-collection.urmaphalab.com}"
EMAIL="${EMAIL:-totonlionel@gmail.com}"
PROJECT_DIR="$HOME/tts-medical-management"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Vérifier si Certbot est installé
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        log "📦 Installation de Certbot..."
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
        log "✅ Certbot installé"
    else
        log "✅ Certbot déjà installé"
    fi
}

# Vérifier la présence des fichiers de configuration
check_config_files() {
    local temp_config="$PROJECT_DIR/nginx/tts-medical-temp.conf"
    local final_config="$PROJECT_DIR/nginx/tts-medical.conf"
    
    if [ ! -f "$temp_config" ]; then
        log "❌ Fichier de configuration temporaire non trouvé: $temp_config"
        exit 1
    fi
    
    if [ ! -f "$final_config" ]; then
        log "❌ Fichier de configuration finale non trouvé: $final_config"
        exit 1
    fi
    
    log "✅ Fichiers de configuration trouvés"
}

# Remplacer les variables dans les fichiers de configuration
update_config_variables() {
    local config_file="$1"
    local temp_file="/tmp/$(basename "$config_file").tmp"
    
    # Remplacer les variables dans le fichier
    sed "s/collection\.urmaphalab\.com/$DOMAIN/g" "$config_file" > "$temp_file"
    
    echo "$temp_file"
}

# Copier et activer la configuration HTTP temporaire
setup_http_config() {
    log "🔧 Configuration NGINX temporaire (HTTP)..."
    
    local temp_config="$PROJECT_DIR/nginx/tts-medical-temp.conf"
    local updated_config=$(update_config_variables "$temp_config")
    
    # Créer les répertoires nécessaires
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    
    # Copier la configuration temporaire
    sudo cp "$updated_config" /etc/nginx/sites-available/tts-medical-temp.conf
    
    # Activer la configuration temporaire
    sudo ln -sf /etc/nginx/sites-available/tts-medical-temp.conf /etc/nginx/sites-enabled/tts-medical-temp.conf
    
    # Supprimer les anciennes configurations
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo rm -f /etc/nginx/sites-enabled/tts-medical.conf
    
    # Nettoyer le fichier temporaire
    rm -f "$updated_config"
    
    # Tester et recharger
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "✅ Configuration HTTP temporaire activée"
    else
        log "❌ Erreur dans la configuration HTTP temporaire"
        sudo nginx -t 2>&1
        exit 1
    fi
}

# Obtenir le certificat SSL
obtain_ssl_certificate() {
    log "🔐 Obtention du certificat SSL avec Certbot..."
    
    # Créer le répertoire pour les challenges
    sudo mkdir -p /var/www/html/.well-known/acme-challenge
    sudo chown -R www-data:www-data /var/www/html
    
    # Vérifier si le certificat existe déjà
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        log "✅ Certificat SSL déjà existant pour $DOMAIN"
        
        # Vérifier la validité du certificat (expire dans moins de 30 jours?)
        if sudo openssl x509 -checkend 2592000 -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" >/dev/null 2>&1; then
            log "✅ Certificat SSL valide, pas besoin de renouvellement"
            return 0
        else
            log "⚠️  Certificat SSL expire bientôt, tentative de renouvellement..."
            if sudo certbot renew --cert-name "$DOMAIN" --nginx --quiet; then
                log "✅ Certificat SSL renouvelé"
                return 0
            fi
        fi
    fi
    
    # Obtenir un nouveau certificat
    if sudo certbot certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAIN" \
        --non-interactive; then
        log "✅ Certificat SSL obtenu avec succès"
        return 0
    else
        log "❌ Échec de l'obtention du certificat SSL"
        log "🔍 Vérifiez que:"
        log "   - Le domaine $DOMAIN pointe vers ce serveur"
        log "   - Les ports 80 et 443 sont ouverts"
        log "   - Aucun autre service n'utilise le port 80"
        return 1
    fi
}

# Copier et activer la configuration SSL finale
setup_ssl_config() {
    log "🔧 Configuration NGINX finale avec SSL..."
    
    local ssl_config="$PROJECT_DIR/nginx/tts-medical.conf"
    local updated_config=$(update_config_variables "$ssl_config")
    
    # Vérifier que le certificat existe
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        log "❌ Certificat SSL non trouvé, impossible de configurer SSL"
        rm -f "$updated_config"
        return 1
    fi
    
    # Copier la configuration SSL
    sudo cp "$updated_config" /etc/nginx/sites-available/tts-medical.conf
    
    # Nettoyer le fichier temporaire
    rm -f "$updated_config"
    
    # Désactiver la configuration temporaire et activer la finale
    sudo rm -f /etc/nginx/sites-enabled/tts-medical-temp.conf
    sudo ln -sf /etc/nginx/sites-available/tts-medical.conf /etc/nginx/sites-enabled/tts-medical.conf
    
    # Tester la configuration
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "✅ Configuration SSL activée"
        return 0
    else
        log "❌ Erreur dans la configuration SSL"
        sudo nginx -t 2>&1
        return 1
    fi
}

# Configurer le renouvellement automatique
setup_auto_renewal() {
    log "🔄 Configuration du renouvellement automatique..."
    
    # Créer un script de post-hook pour recharger nginx après renouvellement
    sudo tee /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh > /dev/null <<EOF
#!/bin/bash
systemctl reload nginx
EOF
    
    sudo chmod +x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
    
    # Vérifier si le cron job existe déjà
    if ! sudo crontab -l 2>/dev/null | grep -q "certbot renew"; then
        # Ajouter le cron job pour le renouvellement automatique (2 fois par jour)
        (sudo crontab -l 2>/dev/null; echo "0 0,12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
        log "✅ Renouvellement automatique configuré (2x par jour)"
    else
        log "✅ Renouvellement automatique déjà configuré"
    fi
    
    # Tester le renouvellement
    log "🧪 Test du processus de renouvellement..."
    if sudo certbot renew --dry-run --quiet; then
        log "✅ Test de renouvellement réussi"
    else
        log "⚠️  Test de renouvellement échoué - vérification manuelle recommandée"
    fi
}

# Tests de connectivité
test_connectivity() {
    log "🔍 Tests de connectivité..."
    
    # Attendre que les services se stabilisent
    sleep 10
    
    # Test HTTPS
    if curl -f -s --max-time 15 "https://$DOMAIN/api/" >/dev/null 2>&1; then
        log "✅ HTTPS accessible et fonctionnel"
        
        # Test de redirection HTTP vers HTTPS
        if curl -s --max-time 10 -I "http://$DOMAIN/" | grep -q "301\|302"; then
            log "✅ Redirection HTTP → HTTPS fonctionnelle"
        fi
        
        return 0
    elif curl -f -s --max-time 10 "http://$DOMAIN/api/" >/dev/null 2>&1; then
        log "⚠️  HTTP accessible mais HTTPS indisponible"
        return 1
    else
        log "⚠️  Aucune connectivité détectée - vérification manuelle recommandée"
        return 1
    fi
}

# Afficher les informations du certificat
show_certificate_info() {
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        log "📋 Informations du certificat SSL:"
        sudo openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)" | sed 's/^/    /'
        
        log "📅 Prochaine vérification de renouvellement:"
        sudo certbot certificates --cert-name "$DOMAIN" 2>/dev/null | grep -E "(Certificate Name|Expiry Date)" | sed 's/^/    /'
    fi
}

# Fonction principale
main() {
    log "🚀 Début de la configuration NGINX avec SSL pour $DOMAIN..."
    
    # Vérifications préliminaires
    if ! command -v nginx &> /dev/null; then
        log "❌ NGINX n'est pas installé"
        exit 1
    fi
    
    # Vérifier la présence des fichiers de configuration
    check_config_files
    
    # Sauvegarder l'ancienne configuration si elle existe
    if [ -f "/etc/nginx/sites-available/tts-medical.conf" ]; then
        sudo cp /etc/nginx/sites-available/tts-medical.conf \
                /etc/nginx/sites-available/tts-medical.conf.backup.$(date +%Y%m%d-%H%M%S)
        log "✅ Ancienne configuration sauvegardée"
    fi
    
    # Vérifier et installer Certbot
    check_certbot
    
    # Étape 1: Configuration HTTP temporaire
    setup_http_config
    
    # Attendre que la configuration soit active
    sleep 5
    
    # Étape 2: Obtenir le certificat SSL
    if obtain_ssl_certificate; then
        # Étape 3: Configuration finale avec SSL
        if setup_ssl_config; then
            # Configurer le renouvellement automatique
            setup_auto_renewal
            
            # Tests de connectivité
            if test_connectivity; then
                log "🎉 Configuration SSL terminée avec succès!"
                show_certificate_info
            else
                log "⚠️  Configuration SSL installée mais connectivité à vérifier"
            fi
        else
            log "❌ Échec de la configuration SSL, retour à HTTP"
            setup_http_config
        fi
    else
        log "⚠️  Certificat SSL non obtenu, conservation de la configuration HTTP"
    fi
    
    # Vérifier le statut final de NGINX
    if sudo systemctl is-active --quiet nginx; then
        log "✅ NGINX est actif et fonctionne"
        
        # Afficher la configuration active
        log "📋 Configuration NGINX active:"
        sudo nginx -T 2>/dev/null | grep -E "server_name|listen" | sort -u | sed 's/^/    /'
        
    else
        log "❌ Problème avec NGINX"
        sudo systemctl status nginx --no-pager -l
        exit 1
    fi
}

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Configure NGINX avec certificat SSL pour TTS Medical API

OPTIONS:
    --help, -h          Afficher cette aide
    --domain DOMAIN     Spécifier le domaine (défaut: $DOMAIN)
    --email EMAIL       Spécifier l'email pour Certbot (défaut: $EMAIL)
    --test-only         Tester la configuration sans l'appliquer
    --force-renew       Forcer le renouvellement du certificat

VARIABLES D'ENVIRONNEMENT:
    DOMAIN              Nom de domaine à configurer
    EMAIL               Email pour les notifications Certbot

EXEMPLES:
    $0                                          # Configuration standard
    $0 --domain api.monsite.com                # Domaine personnalisé
    $0 --email admin@monsite.com               # Email personnalisé
    DOMAIN=api.test.com EMAIL=me@test.com $0   # Via variables d'environnement

FICHIERS REQUIS:
    nginx/tts-medical-temp.conf     Configuration HTTP temporaire
    nginx/tts-medical.conf          Configuration HTTPS finale
EOF
}

# Gestion des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --test-only)
            log "🧪 Mode test activé"
            TEST_ONLY=true
            shift
            ;;
        --force-renew)
            log "🔄 Renouvellement forcé activé"
            FORCE_RENEW=true
            shift
            ;;
        *)
            log "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validation des paramètres
if [ -z "$DOMAIN" ]; then
    log "❌ Domaine requis"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    log "❌ Email requis"
    exit 1
fi

# Exécuter la fonction principale
if [ "${TEST_ONLY:-false}" = "true" ]; then
    log "🧪 Mode test - vérification des fichiers de configuration uniquement"
    check_config_files
    log "✅ Fichiers de configuration valides"
else
    main "$@"
fi

































# #!/bin/bash

# # scripts/setup-nginx.sh
# # Script de configuration NGINX pour TTS Medical API

# set -e

# # Fonction de logging
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
# }

# log "🔧 Configuration NGINX..."

# PROJECT_DIR="$HOME/tts-medical-management"
# NGINX_CONFIG=""

# # Recherche du fichier de configuration NGINX
# if [ -f "$PROJECT_DIR/nginx/tts-medical.conf" ]; then
#     NGINX_CONFIG="$PROJECT_DIR/nginx/tts-medical.conf"
# elif [ -f "$PROJECT_DIR/api/nginx.conf" ]; then
#     NGINX_CONFIG="$PROJECT_DIR/api/nginx.conf"
# elif [ -f "$PROJECT_DIR/tts-medical.conf" ]; then
#     NGINX_CONFIG="$PROJECT_DIR/tts-medical.conf"
# fi

# if [ -n "$NGINX_CONFIG" ]; then
#     log "✅ Configuration NGINX trouvée: $NGINX_CONFIG"
    
#     # Créer les répertoires nécessaires
#     sudo mkdir -p /etc/nginx/sites-available
#     sudo mkdir -p /etc/nginx/sites-enabled
    
#     # Sauvegarder l'ancienne configuration si elle existe
#     if [ -f "/etc/nginx/sites-available/tts-medical.conf" ]; then
#         sudo cp /etc/nginx/sites-available/tts-medical.conf \
#                 /etc/nginx/sites-available/tts-medical.conf.backup.$(date +%Y%m%d-%H%M%S)
#         log "✅ Ancienne configuration sauvegardée"
#     fi
    
#     # Copier la nouvelle configuration
#     sudo cp "$NGINX_CONFIG" /etc/nginx/sites-available/tts-medical.conf
#     log "✅ Configuration copiée"
    
#     # Créer le lien symbolique
#     sudo ln -sf /etc/nginx/sites-available/tts-medical.conf /etc/nginx/sites-enabled/tts-medical.conf
#     log "✅ Lien symbolique créé"
    
#     # Supprimer la configuration par défaut si elle existe
#     if [ -f "/etc/nginx/sites-enabled/default" ]; then
#         sudo rm -f /etc/nginx/sites-enabled/default
#         log "✅ Configuration par défaut supprimée" 
#     fi
    
#     # Test de la configuration NGINX
#     log "🧪 Test de la configuration NGINX..."
#     if sudo nginx -t; then
#         log "✅ Configuration NGINX valide"
        
#         # Recharger NGINX
#         sudo systemctl reload nginx
#         log "✅ NGINX rechargé avec succès"
        
#         # Vérifier le statut de NGINX
#         if sudo systemctl is-active --quiet nginx; then
#             log "✅ NGINX est actif et fonctionne"
#         else
#             log "⚠️  NGINX n'est pas actif, tentative de démarrage..."
#             sudo systemctl start nginx
#             if sudo systemctl is-active --quiet nginx; then
#                 log "✅ NGINX démarré avec succès"
#             else
#                 log "❌ Impossible de démarrer NGINX"
#                 sudo systemctl status nginx --no-pager -l
#                 exit 1
#             fi
#         fi
#     else
#         log "❌ Erreur dans la configuration NGINX"
#         echo "📋 Détails de l'erreur:"
#         sudo nginx -t 2>&1
#         log "⚠️  Déploiement continué sans rechargement NGINX"
#         exit 1
#     fi
    
#     # Test final de connectivité
#     log "🔍 Test de connectivité HTTPS..."
#     sleep 5
#     if curl -f -s --max-time 10 https://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
#         log "✅ HTTPS accessible"
#     elif curl -f -s --max-time 10 http://collection.urmaphalab.com/api/ >/dev/null 2>&1; then
#         log "✅ HTTP accessible (HTTPS peut nécessiter plus de temps)"
#     else
#         log "⚠️  Test de connectivité externe - vérification manuelle recommandée"
#     fi
    
# else
#     log "⚠️  Aucun fichier de configuration NGINX trouvé"
#     echo "📂 Contenu du répertoire projet:"
#     ls -la "$PROJECT_DIR/" 2>/dev/null || echo "Répertoire projet non trouvé"
    
#     if [ -d "$PROJECT_DIR/nginx" ]; then
#         echo "📂 Contenu du répertoire nginx:"
#         ls -la "$PROJECT_DIR/nginx/"
#     fi
    
#     log "⚠️  Configuration NGINX ignorée"
# fi

# log "🔧 Configuration NGINX terminée"