# Your existing Dockerfile should look something like this:

# Stage 1: Dependencies
FROM oven/bun:1.2 AS deps
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install
COPY prisma ./prisma/
RUN bun run db:generate

# Stage 2: Builder
FROM oven/bun:1.2 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma
COPY . .
RUN bun run build

# Stage 3: Runner (Production)
FROM oven/bun:1.2 AS runner
WORKDIR /app

# Install OpenSSL
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# ✅ ADD THIS LINE - Create database directory
# Alternative: Create directory and set ownership
RUN mkdir -p /app/db && chown -R nextjs:nodejs /app/db

# Create nextjs user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# ... rest of your Dockerfile
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/node_modules/prisma ./node_modules/prisma

# Set proper ownership
RUN chown -R nextjs:nodejs /app

# Switch to nextjs user
USER nextjs

# Set environment variables
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
ENV DATABASE_URL=file:/app/db/custom.db

EXPOSE 3000
CMD ["bun", "run", "start"]