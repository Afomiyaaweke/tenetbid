#!/bin/sh
set -e

export DATABASE_URL="${DATABASE_URL:-file:./db/custom.db}"
echo "DATABASE_URL is set to: $DATABASE_URL"

if [ ! -f ./db/custom.db ]; then
  echo "📦 Database not found. Initializing..."
  mkdir -p ./db
  # Use bunx instead of npx
  bunx prisma db push --skip-generate
  echo "✅ Database initialized."
fi

echo "🚀 Starting Next.js server..."
# Use exec to replace the shell with the server process
exec node server.js   # or bun server.js