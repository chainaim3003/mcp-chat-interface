# MCP Chat Interface

🚀 **Natural Language Interface for MCP Servers with Compliance Workflows**

A Next.js application that provides a conversational interface to Model Context Protocol (MCP) servers, specializing in compliance checking, NFT operations, and automated workflows.

## ✨ Features

- **🔍 Compliance Workflows**: GLEIF, Corporate Registration, Export/Import verification
- **🎨 Blockchain Operations**: NFT minting, contract deployment on XDC Network
- **🔄 Workflow Automation**: Visual workflow builder with conditional logic
- **🌐 Natural Language**: Intent parsing from conversational input
- **📡 MCP Orchestrator**: Acts as both MCP server and web service
- **🔧 Multi-Server**: Orchestrates calls across multiple MCP servers

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository>
cd mcp-chat-interface
./scripts/setup.sh

# Configure environment
cp .env.local.example .env.local
# Edit .env.local with your values

# Start development
npm run dev                    # Next.js app at http://localhost:3000
npm run orchestrator:dev       # MCP orchestrator at http://localhost:3002
```

## 💬 Usage Examples

```
"Check GLEIF compliance for Acme Corp"
"Run full compliance workflow for TechStart"
"Mint NFT if CompanyX is GLEIF compliant"
"Check XDC balance for wallet 0x123..."
"Convert ERC-721 token to ERC-6960 for trade finance"
```

## 🏗️ Architecture

```
Web Chat Interface (Next.js)
        ↓
MCP Orchestrator (Optional)
        ↓
┌─────────────┬─────────────────┬─────────────┐
│PRET-MCP     │GOAT-EVM-MCP     │FILE-MCP     │
│(Compliance) │(Blockchain)     │(Storage)    │
└─────────────┴─────────────────┴─────────────┘
```

## 📖 Documentation

- [Full Documentation](./docs/README.md)
- [API Reference](./docs/API.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)

## 🚢 Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/your-repo/mcp-chat-interface)

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guide](./CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](./LICENSE) file.
