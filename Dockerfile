FROM oven/bun:1.2 AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package.json bun.lock ./
RUN bun install

# Copy source code
COPY . .

# Generate Prisma client
RUN bunx prisma generate

# Build the application
RUN bun run build

# Production stage
FROM oven/bun:1.2 AS runner

WORKDIR /app

# Create the database directory and set permissions for bun user
RUN mkdir -p /app/db && chown -R bun:bun /app/db

# Create a non-root user if needed (bun user already exists in the base image)
# The bun image already has a 'bun' user, so we don't need to create one

# Copy necessary files from builder
COPY --from=builder --chown=bun:bun /app/package.json ./
COPY --from=builder --chown=bun:bun /app/node_modules ./node_modules
COPY --from=builder --chown=bun:bun /app/.next ./.next
COPY --from=builder --chown=bun:bun /app/public ./public
COPY --from=builder --chown=bun:bun /app/prisma ./prisma
COPY --from=builder --chown=bun:bun /app/db ./db

# Switch to bun user
USER bun

# Copy entrypoint script and set permissions
COPY --chmod=755 docker-entrypoint.sh ./docker-entrypoint.sh

# Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL="file:/app/db/dev.db"

# Expose port
EXPOSE 3000

# Run the application
ENTRYPOINT ["./docker-entrypoint.sh"]
FROM oven/bun:1.2 AS runner

WORKDIR /app

# Create nextjs user with same UID as bun (1000)
RUN addgroup --system --gid 1000 nodejs && \
    adduser --system --uid 1000 nextjs

# Create database directory with proper ownership
RUN mkdir -p /app/db && chown -R nextjs:nodejs /app/db

# Copy files with correct ownership
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./
# ... rest of your COPY commands ...

# Switch to nextjs user
USER nextjs