#!/bin/sh
set -e

# Set DATABASE_URL if not already provided
export DATABASE_URL="${DATABASE_URL:-file:./db/custom.db}"
echo "DATABASE_URL is set to: $DATABASE_URL"

# Create SQLite database if it doesn't exist
if [ ! -f ./db/custom.db ]; then
  echo "📦 Database not found. Initializing..."
  mkdir -p ./db
  # Use bunx (not npx) and omit the invalid --skip-generate flag
  bunx prisma db push
  echo "✅ Database initialized."
fi

echo "🚀 Starting Next.js server..."
# Use exec to replace the shell with the server process
exec node server.js
#!/bin/sh
set -e

# Create the database directory
mkdir -p /app/db

# Ensure the database file exists
touch /app/db/custom.db

# Run Prisma migrations if needed
bun run db:push || true

# Start the application
exec bun run start