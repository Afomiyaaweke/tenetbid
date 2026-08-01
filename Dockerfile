# Overwrite the Dockerfile with the correct one
cat > Dockerfile << 'EOF'
# Multi-stage build for Bun + Next.js
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

# Copy necessary files from builder with bun ownership
COPY --from=builder --chown=bun:bun /app/package.json ./
COPY --from=builder --chown=bun:bun /app/node_modules ./node_modules
COPY --from=builder --chown=bun:bun /app/.next ./.next
COPY --from=builder --chown=bun:bun /app/public ./public
COPY --from=builder --chown=bun:bun /app/prisma ./prisma

# Copy entrypoint script and set permissions
COPY --chmod=755 docker-entrypoint.sh ./docker-entrypoint.sh

# Switch to bun user (already exists in the image)
USER bun

# Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL="file:/app/db/dev.db"
ENV NEXT_TELEMETRY_DISABLED=1

# Expose port
EXPOSE 3000

# Run the application
ENTRYPOINT ["./docker-entrypoint.sh"]
EOF