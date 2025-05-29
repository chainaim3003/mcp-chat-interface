#!/bin/bash

# MCP Dynamic Discovery Migration Script
# =====================================
# Runs the JavaScript fix and sets up the environment
#
# Usage: ./fix-mcp-migration.sh

set -e  # Exit on any error

echo "🔧 MCP Dynamic Discovery Migration"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "claude_mcp_config.json" ]; then
    echo "❌ Error: claude_mcp_config.json not found"
    echo "   Please run this script from your project root directory"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found"
    echo "   Please run this script from your Next.js project root"
    exit 1
fi

echo "✅ Found project files"
echo ""

# Step 1: Run the main fix script
echo "🚀 Step 1: Running MCP dynamic discovery fix..."
echo "----------------------------------------------"

if [ -f "complete-fix.js" ]; then
    node complete-fix.js
else
    echo "❌ Error: fix-mcp-dynamic-discovery.js not found"
    echo "   Please ensure the fix script is in the project root"
    exit 1
fi

echo ""

# Step 2: Install dependencies
echo "📦 Step 2: Installing dependencies..."
echo "------------------------------------"
npm install

# Step 3: Set up environment
echo ""
echo "🔧 Step 3: Setting up environment..."
echo "-----------------------------------"

if [ ! -f ".env.local" ]; then
    if [ -f ".env.local.example" ]; then
        cp .env.local.example .env.local
        echo "✅ Created .env.local from template"
        echo "⚠️  Please edit .env.local and add your OPENAI_API_KEY"
    else
        # Create basic .env.local
        cat > .env.local << EOF
# OpenAI API Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4

# MCP Server Environment Variables
WALLET_PRIVATE_KEY=0x64aa93e0e0bfec460d474e6b03054a12c103211e5e9d8e11bec984dc8a2d8cb2
RPC_PROVIDER_URL=https://rpc.apothem.network
EOF
        echo "✅ Created .env.local"
        echo "⚠️  Please edit .env.local and add your OPENAI_API_KEY"
    fi
else
    echo "✅ .env.local already exists"
fi

# Step 4: Run tests
echo ""
echo "🧪 Step 4: Testing implementation..."
echo "-----------------------------------"

if [ -f "test-mcp-setup.js" ]; then
    node test-mcp-setup.js
else
    echo "⚠️  Test script not found, skipping tests"
fi

# Step 5: Final instructions
echo ""
echo "🎉 Migration Complete!"
echo "====================="
echo ""
echo "✅ Dynamic MCP discovery implemented"
echo "✅ Dependencies installed"
echo "✅ Environment configured"
echo ""
echo "🎯 Next Steps:"
echo "1. Edit .env.local and add your OPENAI_API_KEY"
echo "2. Start your app: npm run dev"
echo "3. Test health: curl http://localhost:3000/api/mcp/health"
echo "4. Test chat: curl -X POST http://localhost:3000/api/chat \\"
echo "   -H 'Content-Type: application/json' \\"
echo "   -d '{\"messages\":[{\"role\":\"user\",\"content\":\"What tools are available?\"}]}'"
echo ""
echo "📊 Expected Results:"
echo "- Health endpoint should show $(jq -r '.mcpServers | keys | length' claude_mcp_config.json) servers connected"
echo "- Chat should report 15+ dynamic tools available"
echo "- Server logs should show MCP initialization messages"
echo ""
echo "🔧 Troubleshooting:"
echo "- Health check: curl http://localhost:3000/api/mcp/health"
echo "- Reinitialize: curl -X POST http://localhost:3000/api/mcp/health"
echo "- View logs in your terminal running 'npm run dev'"
echo ""
echo "📖 Read MCP-IMPLEMENTATION.md for detailed documentation"
echo ""

# Check if OPENAI_API_KEY is set
if [ -f ".env.local" ] && ! grep -q "your_openai_api_key_here" .env.local; then
    echo "✅ Ready to start! Run: npm run dev"
else
    echo "⚠️ Remember to add your OPENAI_API_KEY to .env.local before starting"
fi

echo "🎊 Your MCP interface is now CONFIG-DRIVEN and DYNAMIC!"