#!/bin/bash
# Clean build script - use this for clean builds

echo "🧹 Cleaning build artifacts..."
rm -rf .next out dist build

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building..."
npm run build

echo "✅ Clean build completed!"
