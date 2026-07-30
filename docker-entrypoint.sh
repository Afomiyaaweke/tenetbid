#!/bin/bash
set -e

echo "🚀 Starting Afomiya Tender Ecosystem..."

# Check if database exists, if not initialize it
if [ ! -f ./db/custom.db ]; then
  echo "📦 Database not found. Initializing..."
  mkdir -p ./db

  # Push the schema to create the database
  bunx prisma db push --skip-generate

  # Seed the database with sample data
  echo "🌱 Seeding database with sample data..."
  bun run prisma/seed.ts

  echo "✅ Database initialized successfully!"
else
  echo "✅ Database found. Skipping initialization."
fi

# Start the Next.js server
echo "🌐 Starting Next.js server on port 3000..."
exec bun server.js
# docker-entrypoint.sh
exec node server.js -p ${PORT:-3000}