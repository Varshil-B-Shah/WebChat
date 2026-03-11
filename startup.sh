#!/bin/sh

# Azure App Service startup script for Next.js

echo "Starting Next.js application..."

# Ensure we're in the correct directory
cd /home/site/wwwroot

# Set Node environment
export NODE_ENV=production

# Use the PORT provided by Azure (defaults to 8080)
export PORT="${PORT:-8080}"

# Ensure node_modules/.bin is in PATH
export PATH="./node_modules/.bin:$PATH"

# Check if .next directory exists, if not run build
if [ ! -d ".next" ]; then
    echo ".next directory not found. Running build..."
    npm run build
fi

# Start the application
echo "Starting Next.js on port $PORT..."
npm start
