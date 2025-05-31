# Dockerfile
FROM node:22-alpine AS base

WORKDIR /app
COPY package*.json ./

# Stage développement
FROM base AS development
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Stage build
FROM base AS build
RUN npm install
COPY . .
RUN npm run build

# Stage production
FROM node:22-alpine AS production

# Créer utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Installer dépendances production
COPY package*.json ./
RUN npm ci --only=production --silent && \
    npm cache clean --force

# Copier le code compilé
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000

# Utiliser l'utilisateur non-root
USER nodejs

EXPOSE 3000
CMD ["node", "dist/index.js"]