# Multi-stage build pour optimiser la taille
FROM node:22-alpine AS base

# Installer les dépendances système nécessaires
RUN apk add --no-cache dumb-init

# Créer le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Stage de développement
FROM base AS development
RUN npm ci --include=dev
COPY . .
EXPOSE 5100
CMD ["npm", "run", "dev"]

# Stage de build
FROM base AS build
RUN npm ci --include=dev
COPY . .
RUN npm run build
# Le script postbuild (addJsExtension.js) sera exécuté automatiquement après tsc

# Stage de production
FROM base AS production

# Copier seulement les dépendances de production
RUN npm ci --omit=dev && npm cache clean --force

# Copier le code source, les fichiers compilés et le script addJsExtension depuis le stage build
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
COPY --from=build /app/addJsExtension.js ./

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Changer la propriété des fichiers
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exposer le port
EXPOSE 5100

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=5100

# Utiliser dumb-init pour gérer les signaux
ENTRYPOINT ["dumb-init", "--"]

# Commande par défaut - CORRIGÉE
CMD ["node", "dist/server.js"]