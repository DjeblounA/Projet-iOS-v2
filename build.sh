#!/bin/bash

echo "📦 Resolving Dependencies..."
swift package resolve

echo ""
echo "------------------------------------------------"
echo "🛠️  Building Project (Hummingbird + SQLite)..."
echo "------------------------------------------------"
swift build
