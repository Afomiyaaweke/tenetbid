# Multi-stage build for Bun + Next.js
FROM oven/bun:1.2 AS builder

WORKDIR /app

# OpenSSL is required for Prisma's query engine to detect the correct binary target
RUN apt-get update -y && apt-get install -y openssl

# Copy package files
COPY package.json bun.lockb* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Generate Prisma client
RUN bunx prisma generate

# Build the application
RUN bun run build

# Production stage
FROM oven/bun:1.2 AS runner

WORKDIR /app

# OpenSSL is also required at runtime for the Prisma query engine binary to load
RUN apt-get update -y && apt-get install -y openssl

# Copy built application
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Next.js standalone output tracing frequently misses Prisma's engine binaries
# since they're loaded dynamically rather than via static require. Copy them explicitly.
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
# DATABASE_URL must be supplied at deploy time (build secret / platform env var),
# not hardcoded here.

# Expose port
EXPOSE 3000

# Start the application
CMD ["bun", "server.js"]
