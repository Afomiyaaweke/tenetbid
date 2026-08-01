#!/bin/bash
set -e

echo "Starting application..."

# Set DATABASE_URL if not already set
export DATABASE_URL="${DATABASE_URL:-file:/app/db/dev.db}"

# Ensure db directory exists and has correct permissions
mkdir -p /app/db

# Generate Prisma client
echo "Generating Prisma client..."
bunx prisma generate

# Run migrations
echo "Running database migrations..."
bunx prisma migrate deploy

# Start the application
echo "Starting Next.js application..."
exec bun run start