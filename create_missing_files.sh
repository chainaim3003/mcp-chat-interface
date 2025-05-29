# Create all missing files and directories

# 1. First, let's fix the next.config.js (remove deprecated options)
echo "🔧 Fixing next.config.js..."
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  webpack: (config) => {
    config.resolve.fallback = {
      ...config.resolve.fallback,
      ws: false,
    };
    return config;
  },
  async rewrites() {
    return [
      {
        source: '/mcp/:path*',
        destination: 'http://localhost:3002/mcp/:path*',
      },
    ];
  },
}

module.exports = nextConfig
EOF

# 2. Create the types directory and files
echo "📝 Creating types..."
mkdir -p types
cat > types/mcp.ts << 'EOF'
export interface MCPServer {
  name: string;
  command: string;
  args?: string[];
  env?: Record<string, string>;
  tools?: MCPTool[];
  status?: 'connected' | 'disconnected' | 'error';
  url?: string;
  port?: number;
}

export interface MCPTool {
  name: string;
  description: string;
  inputSchema: any;
  server: string;
  category?: 'compliance' | 'blockchain' | 'storage' | 'utility';
}

export interface MCPConfig {
  mcpServers: Record<string, MCPServer>;
  workflows?: WorkflowDefinition[];
  settings?: {
    autoExecute: boolean;
    confirmActions: boolean;
    maxConcurrentTools: number;
    enableAutonomous: boolean;
  };
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  toolCalls?: ToolCall[];
  metadata?: {
    workflowId?: string;
    complianceCheck?: ComplianceResult;
    transactionHash?: string;
  };
}

export interface ToolCall {
  id: string;
  toolName: string;
  serverName: string;
  parameters: any;
  result?: any;
  status: 'pending' | 'success' | 'error';
  duration?: number;
  error?: string;
}

export interface ComplianceResult {
  companyName: string;
  gleifStatus: 'ACTIVE' | 'INACTIVE' | 'PENDING';
  corpRegistration: 'COMPLIANT' | 'NON_COMPLIANT' | 'PENDING';
  exportImport: 'COMPLIANT' | 'NON_COMPLIANT' | 'PENDING';
  financialHealth: 'LOW_RISK' | 'MEDIUM_RISK' | 'HIGH_RISK';
  overallCompliance: 'FULLY_COMPLIANT' | 'PARTIALLY_COMPLIANT' | 'NON_COMPLIANT';
  score: number;
  lastUpdated: string;
}

export interface WorkflowDefinition {
  id: string;
  name: string;
  description: string;
  steps: WorkflowStep[];
  triggers: WorkflowTrigger[];
  autonomous: boolean;
}

export interface WorkflowStep {
  id: string;
  type: 'tool_call' | 'condition' | 'decision' | 'parallel';
  server?: string;
  tool?: string;
  parameters?: any;
  condition?: string;
  onSuccess?: string;
  onFailure?: string;
}

export interface WorkflowTrigger {
  type: 'manual' | 'schedule' | 'event' | 'webhook';
  config: any;
}

export interface NFTMetadata {
  name: string;
  description: string;
  image: string;
  attributes: Array<{
    trait_type: string;
    value: string | number;
  }>;
  compliance?: ComplianceResult;
}

export interface BlockchainTransaction {
  hash: string;
  status: 'pending' | 'confirmed' | 'failed';
  network: 'mainnet' | 'testnet';
  gasUsed?: string;
  gasPrice?: string;
  blockNumber?: number;
}
EOF

# 3. Create lib directory and basic files
echo "📚 Creating lib files..."
mkdir -p lib

# Simple config manager
cat > lib/config-manager.ts << 'EOF'
import { MCPConfig } from '../types/mcp';

export class ConfigManager {
  private static readonly CONFIG_KEY = 'mcp-chat-config';
  private static readonly VERSION = '1.0.0';
  
  static loadConfig(): MCPConfig | null {
    if (typeof window === 'undefined') return null;
    
    try {
      const stored = localStorage.getItem(this.CONFIG_KEY);
      if (!stored) return null;
      
      const config = JSON.parse(stored);
      return config;
    } catch (error) {
      console.error('Failed to load config:', error);
      return null;
    }
  }
  
  static saveConfig(config: MCPConfig): void {
    if (typeof window === 'undefined') return;
    
    try {
      const configWithVersion = {
        ...config,
        version: this.VERSION,
        lastUpdated: new Date().toISOString()
      };
      
      localStorage.setItem(this.CONFIG_KEY, JSON.stringify(configWithVersion, null, 2));
    } catch (error) {
      console.error('Failed to save config:', error);
    }
  }
  
  static getDefaultConfig(): MCPConfig {
    return {
      mcpServers: {
        "PRET-MCP-SERVER": {
          name: "PRET-MCP-SERVER",
          command: "pret-mcp-server",
          args: ["--port", "3001"],
          url: "ws://localhost:3001",
          port: 3001,
          env: {
            "API_KEY": "your-pret-api-key"
          }
        },
        "GOAT-EVM-MCP-SERVER": {
          name: "GOAT-EVM-MCP-SERVER", 
          command: "goat-evm-mcp-server",
          args: ["--network", "xdc", "--port", "3003"],
          url: "ws://localhost:3003",
          port: 3003,
          env: {
            "PRIVATE_KEY": "your-private-key",
            "RPC_URL": "https://erpc.xinfin.network"
          }
        },
        "FILE-MCP-SERVER": {
          name: "FILE-MCP-SERVER",
          command: "file-mcp-server",
          args: ["--root", "./data", "--port", "3004"],
          url: "ws://localhost:3004",
          port: 3004
        }
      },
      settings: {
        autoExecute: false,
        confirmActions: true,
        maxConcurrentTools: 5,
        enableAutonomous: false
      }
    };
  }
  
  static validateConfig(config: any): boolean {
    try {
      return (
        config &&
        typeof config === 'object' &&
        config.mcpServers &&
        typeof config.mcpServers === 'object' &&
        Object.keys(config.mcpServers).length > 0
      );
    } catch (error) {
      return false;
    }
  }
}
EOF

# Simple orchestrator for demo
cat > lib/orchestrator.ts << 'EOF'
import { ChatMessage, ToolCall, MCPConfig } from '../types/mcp';

export class MCPOrchestrator {
  constructor(private config: MCPConfig) {}

  async initialize(): Promise<void> {
    console.log('🔧 Initializing MCP Orchestrator...');
    // Simulate initialization
    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log('✅ MCP Orchestrator initialized successfully');
  }

  async processMessage(message: string): Promise<ChatMessage> {
    const chatMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      toolCalls: []
    };

    try {
      // Simple demo responses
      if (message.toLowerCase().includes('gleif')) {
        const companyName = this.extractCompanyName(message);
        const toolCall: ToolCall = {
          id: crypto.randomUUID(),
          toolName: 'get-GLEIF-data',
          serverName: 'PRET-MCP-SERVER',
          parameters: { companyName },
          status: 'success',
          result: {
            companyName,
            gleifStatus: Math.random() > 0.5 ? 'ACTIVE' : 'INACTIVE',
            entityId: 'LEI-' + Math.random().toString(36).substring(2, 20).toUpperCase()
          }
        };
        
        chatMessage.toolCalls = [toolCall];
        chatMessage.content = `**GLEIF Compliance Check for ${companyName}**\n\nStatus: ${toolCall.result.gleifStatus}\nEntity ID: ${toolCall.result.entityId}\n\n${toolCall.result.gleifStatus === 'ACTIVE' ? '✅ Company is GLEIF compliant!' : '❌ Company needs GLEIF registration.'}`;
      } else if (message.toLowerCase().includes('mint') && message.toLowerCase().includes('nft')) {
        const toolCall: ToolCall = {
          id: crypto.randomUUID(),
          toolName: 'mint_nft',
          serverName: 'GOAT-EVM-MCP-SERVER',
          parameters: { network: 'testnet' },
          status: 'success',
          result: {
            transactionHash: '0x' + Math.random().toString(16).substring(2, 66),
            tokenId: Math.floor(Math.random() * 1000000)
          }
        };
        
        chatMessage.toolCalls = [toolCall];
        chatMessage.content = `**NFT Minted Successfully!**\n\nTransaction Hash: ${toolCall.result.transactionHash}\nToken ID: ${toolCall.result.tokenId}\nNetwork: testnet`;
      } else {
        chatMessage.content = `🤖 **MCP Chat Interface Demo**\n\nI can help you with:\n\n**🔍 Compliance Operations:**\n- "Check GLEIF compliance for Acme Corp"\n- "Run compliance workflow for TechStart"\n\n**🎨 NFT Operations:**\n- "Mint NFT for CompanyX"\n- "Deploy NFT contract"\n\n**🔄 System Operations:**\n- "Check system status"\n- "List available tools"\n\nTry asking: *"Check GLEIF compliance for Acme Corp"*`;
      }
    } catch (error) {
      chatMessage.content = `❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`;
    }

    return chatMessage;
  }

  private extractCompanyName(message: string): string {
    const match = message.match(/(?:for|company)\s+([A-Za-z][A-Za-z0-9\s&.-]+?)(?:\s|$|,|\.|!|\?)/i);
    return match ? match[1].trim() : 'Unknown Company';
  }

  getAvailableTools() {
    return [
      {
        name: 'get-GLEIF-data',
        description: 'Get GLEIF compliance data for a company',
        server: 'PRET-MCP-SERVER',
        category: 'compliance' as const
      },
      {
        name: 'mint_nft',
        description: 'Mint NFT on XDC network',
        server: 'GOAT-EVM-MCP-SERVER', 
        category: 'blockchain' as const
      },
      {
        name: 'check-corp-registration',
        description: 'Check corporate registration status',
        server: 'PRET-MCP-SERVER',
        category: 'compliance' as const
      }
    ];
  }
}
EOF

# 4. Create components directory and chat interface
echo "🎨 Creating components..."
mkdir -p components

cat > components/chat-interface.tsx << 'EOF'
'use client';

import { useState, useEffect, useRef } from 'react';
import { Send, Bot, User, Settings, Zap, CheckCircle, AlertCircle, Clock } from 'lucide-react';
import { ChatMessage, MCPTool, ToolCall, MCPConfig } from '../types/mcp';
import { MCPOrchestrator } from '../lib/orchestrator';

interface ChatInterfaceProps {
  config?: MCPConfig | null;
}

export default function ChatInterface({ config }: ChatInterfaceProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [orchestrator, setOrchestrator] = useState<MCPOrchestrator | null>(null);
  const [availableTools, setAvailableTools] = useState<MCPTool[]>([]);
  const [showTools, setShowTools] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (config) {
      initializeOrchestrator();
    }
  }, [config]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const initializeOrchestrator = async () => {
    if (!config) return;
    
    try {
      const orch = new MCPOrchestrator(config);
      await orch.initialize();
      setOrchestrator(orch);
      setAvailableTools(orch.getAvailableTools());
      
      const welcomeMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `🚀 **Welcome to MCP Chat Interface!**\n\nI'm connected to **${Object.keys(config.mcpServers || {}).length} MCP servers** with **${orch.getAvailableTools().length} available tools**.\n\n**Try these commands:**\n- "Check GLEIF compliance for Acme Corp"\n- "Mint NFT for TechStart"\n- "Run compliance workflow"\n\nWhat would you like me to help you with?`,
        timestamp: new Date()
      };
      
      setMessages([welcomeMessage]);
    } catch (error) {
      console.error('Failed to initialize orchestrator:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !orchestrator || isLoading) return;

    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setIsLoading(true);

    try {
      const response = await orchestrator.processMessage(currentInput);
      setMessages(prev => [...prev, response]);
    } catch (error) {
      const errorMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-600" />;
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-600 animate-spin" />;
      default:
        return <Clock className="w-4 h-4 text-gray-400" />;
    }
  };

  const renderToolCall = (toolCall: ToolCall) => (
    <div key={toolCall.id} className="mt-3 p-4 bg-blue-50 rounded-lg border border-blue-200">
      <div className="flex items-center gap-3 mb-2">
        <Zap className="w-4 h-4 text-blue-600" />
        <span className="font-medium text-blue-900">{toolCall.toolName}</span>
        <span className="text-sm text-blue-600">{toolCall.serverName}</span>
        {getStatusIcon(toolCall.status)}
      </div>
      
      {toolCall.result && (
        <div className="mt-2 p-2 bg-white rounded text-sm">
          <pre className="whitespace-pre-wrap">{JSON.stringify(toolCall.result, null, 2)}</pre>
        </div>
      )}
    </div>
  );

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`${showTools ? 'w-80' : 'w-16'} transition-all duration-300 bg-white border-r border-gray-200 flex flex-col`}>
        <div className="p-4 border-b border-gray-200">
          <button
            onClick={() => setShowTools(!showTools)}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <Settings className="w-5 h-5" />
          </button>
        </div>
        
        {showTools && (
          <div className="flex-1 overflow-y-auto p-4">
            <h3 className="font-semibold mb-4">Available Tools ({availableTools.length})</h3>
            <div className="space-y-2">
              {availableTools.map((tool, index) => (
                <div key={index} className="p-3 bg-gray-50 rounded-lg">
                  <div className="font-medium text-sm">{tool.name}</div>
                  <div className="text-xs text-gray-500 mb-1">{tool.server}</div>
                  <div className="text-xs text-gray-600">{tool.description}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Main Chat */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 p-4">
          <h1 className="text-xl font-semibold">MCP Chat Interface</h1>
          <p className="text-sm text-gray-600">Natural language interface for MCP servers</p>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((message) => (
            <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-3xl ${
                message.role === 'user' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-white border border-gray-200'
              } rounded-lg p-4`}>
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                    message.role === 'user' ? 'bg-blue-500' : 'bg-gray-100'
                  }`}>
                    {message.role === 'user' ? <User className="w-4 h-4" /> : <Bot className="w-4 h-4" />}
                  </div>
                  <div className="flex-1">
                    <div className="whitespace-pre-wrap">{message.content}</div>
                    
                    {message.toolCalls && message.toolCalls.length > 0 && (
                      <div className="mt-3">
                        <div className="text-sm font-medium mb-2">Tool Executions:</div>
                        {message.toolCalls.map(renderToolCall)}
                      </div>
                    )}
                    
                    <div className={`text-xs mt-2 ${
                      message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
                    }`}>
                      {message.timestamp.toLocaleTimeString()}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
          
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <div className="flex items-center gap-3">
                  <Bot className="w-6 h-6 text-gray-400" />
                  <div className="flex space-x-1">
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                  </div>
                </div>
              </div>
            </div>
          )}
          
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="bg-white border-t border-gray-200 p-4">
          <form onSubmit={handleSubmit} className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask me to check GLEIF compliance, mint NFTs, or run workflows..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Send className="w-5 h-5" />
            </button>
          </form>
          
          <div className="mt-2 text-xs text-gray-500">
            Try: "Check GLEIF compliance for Acme Corp" or "Mint NFT for TechStart"
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# 5. Update the main page
echo "📄 Updating main page..."
cat > app/page.tsx << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import ChatInterface from '../components/chat-interface';
import { MCPConfig } from '../types/mcp';
import { ConfigManager } from '../lib/config-manager';

export default function Home() {
  const [config, setConfig] = useState<MCPConfig | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadConfiguration();
  }, []);

  const loadConfiguration = () => {
    const savedConfig = ConfigManager.loadConfig();
    const finalConfig = savedConfig || ConfigManager.getDefaultConfig();
    setConfig(finalConfig);
    setIsLoading(false);
  };

  const saveConfiguration = (newConfig: MCPConfig) => {
    setConfig(newConfig);
    ConfigManager.saveConfig(newConfig);
  };

  if (isLoading) {
    return (
      <div className="h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Initializing MCP Chat Interface...</p>
        </div>
      </div>
    );
  }

  if (showConfig) {
    return (
      <div className="p-8 max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">MCP Configuration</h1>
        <div className="bg-white rounded-lg shadow-lg p-6">
          <textarea
            value={JSON.stringify(config, null, 2)}
            onChange={(e) => {
              try {
                const newConfig = JSON.parse(e.target.value);
                setConfig(newConfig);
              } catch (err) {
                console.error('Invalid JSON:', err);
              }
            }}
            className="w-full h-96 p-4 border border-gray-300 rounded-lg font-mono text-sm"
            placeholder="Enter your MCP configuration..."
          />
          <div className="mt-6 flex justify-between">
            <button
              onClick={() => setConfig(ConfigManager.getDefaultConfig())}
              className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
            >
              Reset to Default
            </button>
            <div className="space-x-2">
              <button
                onClick={() => setShowConfig(false)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Start Chat
              </button>
              <button
                onClick={() => saveConfiguration(config!)}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Save Config
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen relative">
      <ChatInterface config={config} />
      <button
        onClick={() => setShowConfig(true)}
        className="fixed bottom-4 right-4 p-3 bg-gray-800 text-white rounded-full hover:bg-gray-700 shadow-lg transition-all hover:scale-105"
        title="Configure MCP Servers"
      >
        ⚙️
      </button>
    </div>
  );
}
EOF

echo "✅ All files created! Now try:"
echo "npm run build"