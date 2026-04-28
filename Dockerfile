# Multi-stage build para NEXUS
FROM node:18-alpine AS builder

WORKDIR /app

# Instalar dependências
COPY package*.json ./
RUN npm install

# Copiar código e fazer build
COPY . .
RUN npm run build

# Runtime stage
FROM node:18-alpine

WORKDIR /app

# Copiar package.json para produção
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm install --production && npm cache clean --force

# Copiar build da stage anterior
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3400/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Variáveis de environment padrão
ENV NODE_ENV=production
ENV PORT=3400

EXPOSE 3400

CMD ["npm", "start"]
