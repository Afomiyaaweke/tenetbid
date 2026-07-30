# ─── Stage 1: Dependencies ───
FROM oven/bun:1.2 AS deps

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
# Copy package files first for better caching
COPY package.json bun.lock ./
COPY prisma ./prisma/

# Install all dependencies
RUN bun install

# Generate Prisma client
RUN bun run db:generate

# ─── Stage 2: Build ───
FROM oven/bun:1.2 AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma

# Copy source code
COPY . .

# Build the Next.js standalone output
RUN bun run build

# ─── Stage 3: Production ───
FROM oven/bun:1.2 AS runner

WORKDIR /app

# Install curl for health checks and runtime needs
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Don't run as root
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy standalone build output
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Copy Prisma schema, engine, and CLI for runtime DB operations
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/node_modules/prisma ./node_modules/prisma

# Copy the seed file for DB initialization
COPY --from=builder /app/prisma/seed.ts ./prisma/seed.ts

# Create db directory and set ownership
RUN mkdir -p ./db && chown -R nextjs:nodejs ./db

# Copy entrypoint script
COPY --chmod=755 docker-entrypoint.sh ./docker-entrypoint.sh

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/api || exit 1

# Start with entrypoint
ENTRYPOINT ["./docker-entrypoint.sh"]
