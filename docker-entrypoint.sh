#!/bin/bash
set -ex   # <-- print every command

# Force DATABASE_URL if missing
export DATABASE_URL="${DATABASE_URL:-file:./db/custom.db}"
echo "DATABASE_URL is set to: $DATABASE_URL"

if [ ! -f ./db/custom.db ]; then
  echo "📦 Database not found. Initializing..."
  mkdir -p ./db

  # Use npx (Node) instead of bunx for better stability
  npx prisma db push --skip-generate 2>&1   # show output

  echo "🌱 Seeding database..."
  bun run prisma/seed.ts 2>&1

  echo "✅ Database initialized!"
else
  echo "✅ Database found."
fi

echo "🌐 Starting server on port $PORT..."
exec node server.js -p ${PORT:-3000}