#!/bin/bash

# Fix chat interface to dynamically read MCP config and call real tools
echo "🔧 Creating dynamic MCP chat interface..."

# Create dynamic chat API that reads from config
cat > src/pages/api/chat.ts << 'EOF'
// src/pages/api/chat.ts
// Dynamic chat API that reads MCP config and calls real tools

import { NextApiRequest, NextApiResponse } from 'next';
import { initializeMCP, callMCPTool, getMCPStatus, getMCPServers, mcpConfig } from '../../lib/mcp-integration';

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp?: string;
}

interface ChatRequest {
  message: string;
  history?: ChatMessage[];
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { message, history = [] }: ChatRequest = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Message is required' });
    }

    console.log('💬 Processing chat message:', message);

    // Initialize MCP system if not already done
    try {
      await initializeMCP();
    } catch (error) {
      console.warn('⚠️ MCP initialization warning:', error);
    }

    // Get real-time MCP status and configuration
    const mcpStatus = getMCPStatus();
    const availableServers = getMCPServers();
    const config = mcpConfig.getConfig();

    console.log('🔍 MCP Status:', {
      initialized: mcpStatus.initialized,
      serverCount: Object.keys(availableServers).length,
      servers: Object.keys(availableServers)
    });

    // Process the message dynamically based on available servers and tools
    const response = await processMessageDynamically(message, mcpStatus, availableServers, config);

    // Return the response with real server info
    res.status(200).json({
      success: true,
      response: response,
      mcpStatus: {
        initialized: mcpStatus.initialized,
        availableServers: Object.keys(availableServers),
        runningServers: mcpStatus.servers ? Object.entries(mcpStatus.servers)
          .filter(([_, server]: [string, any]) => server.status === 'running')
          .map(([name, server]: [string, any]) => ({
            name,
            tools: server.tools || [],
            uptime: server.uptime || 0
          })) : []
      }
    });

  } catch (error) {
    console.error('❌ Chat API error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      fallbackResponse: "I'm having trouble processing your request. The MCP system might not be fully initialized."
    });
  }
}

async function processMessageDynamically(
  message: string, 
  mcpStatus: any, 
  availableServers: Record<string, any>,
  config: any
): Promise<string> {
  const lowerMessage = message.toLowerCase();

  try {
    // Special commands
    if (lowerMessage.includes('list tools') || lowerMessage.includes('what tools') || lowerMessage.includes('available tools')) {
      return await listAvailableTools(mcpStatus);
    }

    if (lowerMessage.includes('status') || lowerMessage.includes('system status')) {
      return generateSystemStatus(mcpStatus, availableServers);
    }

    if (lowerMessage.includes('help') || lowerMessage === 'hi' || lowerMessage === 'hello') {
      return generateWelcomeMessage(mcpStatus, availableServers);
    }

    // Dynamic intent detection based on available servers
    const detectedIntent = detectIntentFromServers(lowerMessage, availableServers);
    
    if (detectedIntent) {
      return await executeDetectedIntent(detectedIntent, message, mcpStatus);
    }

    // If no specific intent detected, show what's available
    return generateHelpfulResponse(mcpStatus, availableServers);

  } catch (error) {
    console.error('💥 Error processing message:', error);
    return `I encountered an error: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function listAvailableTools(mcpStatus: any): Promise<string> {
  if (!mcpStatus.initialized || !mcpStatus.servers) {
    return "❌ MCP system not initialized. No tools available.";
  }

  const runningServers = Object.entries(mcpStatus.servers)
    .filter(([_, server]: [string, any]) => server.status === 'running');

  if (runningServers.length === 0) {
    return "❌ No MCP servers are currently running.";
  }

  let toolsList = "🛠️ **Available Tools:**\n\n";
  let totalTools = 0;

  for (const [serverName, serverInfo] of runningServers) {
    const server = serverInfo as any;
    const tools = server.tools || [];
    
    if (tools.length > 0) {
      toolsList += `**${serverName} Server:**\n`;
      tools.forEach((tool: string) => {
        toolsList += `  • ${tool}\n`;
        totalTools++;
      });
      toolsList += `\n`;
    }
  }

  if (totalTools === 0) {
    return "⚠️ MCP servers are running but no tools are currently available.";
  }

  toolsList += `📊 **Total: ${totalTools} tools across ${runningServers.length} servers**\n\n`;
  toolsList += "💡 Try describing what you want to do, and I'll use the appropriate tool!";

  return toolsList;
}

function generateSystemStatus(mcpStatus: any, availableServers: Record<string, any>): string {
  let status = "🚀 **MCP System Status**\n\n";
  
  status += `**System:** ${mcpStatus.initialized ? '✅ Initialized' : '❌ Not Initialized'}\n`;
  status += `**Total Servers Configured:** ${Object.keys(availableServers).length}\n\n`;

  if (mcpStatus.servers) {
    const serverEntries = Object.entries(mcpStatus.servers);
    
    status += "**Server Status:**\n";
    for (const [name, server] of serverEntries) {
      const s = server as any;
      const statusIcon = s.status === 'running' ? '✅' : 
                        s.status === 'error' ? '❌' : 
                        s.status === 'starting' ? '🔄' : '⏸️';
      
      status += `  ${statusIcon} **${name}**: ${s.status}`;
      if (s.pid) status += ` (PID: ${s.pid})`;
      if (s.tools && s.tools.length > 0) status += ` - ${s.tools.length} tools`;
      status += `\n`;
      
      if (s.error) {
        status += `    Error: ${s.error}\n`;
      }
    }
  }

  status += `\n💡 Use "list tools" to see all available tools.`;
  
  return status;
}

function generateWelcomeMessage(mcpStatus: any, availableServers: Record<string, any>): string {
  const runningServers = mcpStatus.servers ? 
    Object.entries(mcpStatus.servers).filter(([_, s]: [string, any]) => s.status === 'running') : [];
  
  const totalTools = runningServers.reduce((count, [_, server]) => {
    const s = server as any;
    return count + (s.tools ? s.tools.length : 0);
  }, 0);

  let welcome = `🚀 **Welcome to MCP Chat Interface!**\n\n`;
  welcome += `I'm connected to **${runningServers.length} MCP servers** with **${totalTools} available tools**.\n\n`;

  // Generate dynamic examples based on available servers
  const examples = generateDynamicExamples(availableServers, mcpStatus);
  if (examples.length > 0) {
    welcome += `**Try these commands:**\n`;
    examples.forEach(example => {
      welcome += `- "${example}"\n`;
    });
    welcome += `\n`;
  }

  welcome += `What would you like me to help you with?`;
  
  return welcome;
}

function generateDynamicExamples(availableServers: Record<string, any>, mcpStatus: any): string[] {
  const examples: string[] = [];
  
  // Generate examples based on actual available servers
  const runningServers = mcpStatus.servers ? 
    Object.keys(mcpStatus.servers).filter(name => mcpStatus.servers[name].status === 'running') : [];

  if (runningServers.includes('pret-compliance') || runningServers.includes('pret-mcp')) {
    examples.push("Check GLEIF compliance for Acme Corp");
    examples.push("Run compliance workflow");
  }

  if (runningServers.includes('goat-xdc') || runningServers.includes('goat-evm-mcp')) {
    examples.push("Check my XDC wallet balance");
    examples.push("Mint NFT for TechStart");
  }

  if (runningServers.includes('filesystem')) {
    examples.push("List files in data folder");
    examples.push("Read project README");
  }

  if (runningServers.includes('brave-search')) {
    examples.push("Search for blockchain news");
  }

  if (runningServers.includes('memory')) {
    examples.push("Remember this important note");
  }

  // Always add system commands
  examples.push("List available tools");
  examples.push("Check system status");

  return examples;
}

function detectIntentFromServers(message: string, availableServers: Record<string, any>): any {
  const lowerMessage = message.toLowerCase();
  
  // Define intent patterns mapped to servers
  const intentPatterns = [
    {
      patterns: ['gleif', 'compliance', 'corporate registration', 'lei', 'verify company'],
      servers: ['pret-compliance', 'pret-mcp'],
      intent: 'compliance_check'
    },
    {
      patterns: ['nft', 'mint', 'token', 'contract', 'deploy'],
      servers: ['goat-xdc', 'goat-evm-mcp'],
      intent: 'blockchain_operation'
    },
    {
      patterns: ['balance', 'wallet', 'xdc', 'send', 'transfer'],
      servers: ['goat-xdc', 'goat-evm-mcp'],
      intent: 'wallet_operation'
    },
    {
      patterns: ['file', 'read', 'write', 'list', 'directory', 'folder'],
      servers: ['filesystem'],
      intent: 'file_operation'
    },
    {
      patterns: ['search', 'find', 'lookup', 'web search'],
      servers: ['brave-search'],
      intent: 'web_search'
    },
    {
      patterns: ['remember', 'note', 'save', 'recall', 'memory'],
      servers: ['memory'],
      intent: 'memory_operation'
    }
  ];

  for (const pattern of intentPatterns) {
    // Check if message matches pattern
    const matchesPattern = pattern.patterns.some(p => lowerMessage.includes(p));
    
    if (matchesPattern) {
      // Check if required server is available
      const availableServer = pattern.servers.find(server => availableServers[server]);
      
      if (availableServer) {
        return {
          intent: pattern.intent,
          server: availableServer,
          message: message
        };
      }
    }
  }

  return null;
}

async function executeDetectedIntent(detectedIntent: any, originalMessage: string, mcpStatus: any): Promise<string> {
  const { intent, server, message } = detectedIntent;

  try {
    switch (intent) {
      case 'compliance_check':
        return await executeComplianceCheck(server, message, mcpStatus);
      
      case 'blockchain_operation':
      case 'wallet_operation':
        return await executeBlockchainOperation(server, message, mcpStatus);
      
      case 'file_operation':
        return await executeFileOperation(server, message, mcpStatus);
      
      case 'web_search':
        return await executeWebSearch(server, message, mcpStatus);
      
      case 'memory_operation':
        return await executeMemoryOperation(server, message, mcpStatus);
      
      default:
        return `I detected intent "${intent}" but don't know how to handle it yet.`;
    }
  } catch (error) {
    return `Error executing ${intent}: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function executeComplianceCheck(server: string, message: string, mcpStatus: any): Promise<string> {
  // Extract company name from message
  const companyMatch = message.match(/(?:for|of)\s+([A-Za-z0-9\s&.,'-]+?)(?:\s|$)/i);
  const companyName = companyMatch ? companyMatch[1].trim() : null;

  if (!companyName) {
    return "Please specify a company name. Example: 'Check GLEIF compliance for Acme Corp'";
  }

  try {
    // Get available tools for this server
    const serverInfo = mcpStatus.servers?.[server];
    const availableTools = serverInfo?.tools || [];

    let result = `🔍 **Checking compliance for "${companyName}"**\n\n`;

    // Try different compliance tools based on what's available
    if (availableTools.includes('check_gleif_compliance')) {
      try {
        const gleifResult = await callMCPTool(server, 'check_gleif_compliance', { 
          company_name: companyName 
        });
        result += `**GLEIF Check:** ${JSON.stringify(gleifResult, null, 2)}\n\n`;
      } catch (error) {
        result += `**GLEIF Check:** Error - ${error instanceof Error ? error.message : 'Unknown error'}\n\n`;
      }
    }

    if (availableTools.includes('verify_corporate_registration')) {
      try {
        const corpResult = await callMCPTool(server, 'verify_corporate_registration', { 
          company_name: companyName 
        });
        result += `**Corporate Registration:** ${JSON.stringify(corpResult, null, 2)}\n\n`;
      } catch (error) {
        result += `**Corporate Registration:** Error - ${error instanceof Error ? error.message : 'Unknown error'}\n\n`;
      }
    }

    if (availableTools.length === 0) {
      result += `❌ No compliance tools available on server "${server}"`;
    }

    return result;

  } catch (error) {
    return `❌ Error checking compliance: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function executeBlockchainOperation(server: string, message: string, mcpStatus: any): Promise<string> {
  const serverInfo = mcpStatus.servers?.[server];
  const availableTools = serverInfo?.tools || [];

  if (message.toLowerCase().includes('balance')) {
    if (availableTools.includes('get_balance')) {
      try {
        const balance = await callMCPTool(server, 'get_balance', {});
        return `💰 **Wallet Balance:**\n${JSON.stringify(balance, null, 2)}`;
      } catch (error) {
        return `❌ Error getting balance: ${error instanceof Error ? error.message : 'Unknown error'}`;
      }
    } else {
      return `❌ Balance checking not available. Available tools: ${availableTools.join(', ')}`;
    }
  }

  if (message.toLowerCase().includes('nft') || message.toLowerCase().includes('mint')) {
    if (availableTools.includes('mint_nft')) {
      return `🎨 **NFT Minting Available**\n\nI can mint NFTs, but I need more details:\n- Contract address\n- Recipient address\n- Token URI/metadata\n\nExample: "Mint NFT to 0x123... with metadata https://..."`;
    } else {
      return `❌ NFT minting not available. Available tools: ${availableTools.join(', ')}`;
    }
  }

  return `🔗 **Blockchain Operations Available**\n\nAvailable tools on ${server}:\n${availableTools.map(t => `• ${t}`).join('\n')}\n\nWhat specific operation would you like to perform?`;
}

async function executeFileOperation(server: string, message: string, mcpStatus: any): Promise<string> {
  const serverInfo = mcpStatus.servers?.[server];
  const availableTools = serverInfo?.tools || [];

  if (message.toLowerCase().includes('list')) {
    if (availableTools.includes('list_directory')) {
      try {
        const path = message.match(/list\s+(?:files\s+in\s+)?(.+)/i)?.[1]?.trim() || './';
        const result = await callMCPTool(server, 'list_directory', { path });
        return `📁 **Directory listing for "${path}":**\n${JSON.stringify(result, null, 2)}`;
      } catch (error) {
        return `❌ Error listing directory: ${error instanceof Error ? error.message : 'Unknown error'}`;
      }
    }
  }

  if (message.toLowerCase().includes('read')) {
    if (availableTools.includes('read_file')) {
      const pathMatch = message.match(/read\s+(?:file\s+)?(.+)/i);
      if (pathMatch) {
        try {
          const result = await callMCPTool(server, 'read_file', { path: pathMatch[1].trim() });
          return `📄 **File content:**\n\`\`\`\n${result}\n\`\`\``;
        } catch (error) {
          return `❌ Error reading file: ${error instanceof Error ? error.message : 'Unknown error'}`;
        }
      } else {
        return `Please specify a file path. Example: "Read file README.md"`;
      }
    }
  }

  return `📁 **File Operations Available**\n\nAvailable tools:\n${availableTools.map(t => `• ${t}`).join('\n')}\n\nTry: "List files in data" or "Read file README.md"`;
}

async function executeWebSearch(server: string, message: string, mcpStatus: any): Promise<string> {
  const serverInfo = mcpStatus.servers?.[server];
  const availableTools = serverInfo?.tools || [];

  const query = message.replace(/search\s+(?:for\s+)?/i, '').trim();
  
  if (availableTools.includes('web_search')) {
    try {
      const result = await callMCPTool(server, 'web_search', { query });
      return `🔍 **Search Results for "${query}":**\n${JSON.stringify(result, null, 2)}`;
    } catch (error) {
      return `❌ Search error: ${error instanceof Error ? error.message : 'Unknown error'}`;
    }
  }

  return `❌ Web search not available. Available tools: ${availableTools.join(', ')}`;
}

async function executeMemoryOperation(server: string, message: string, mcpStatus: any): Promise<string> {
  const serverInfo = mcpStatus.servers?.[server];
  const availableTools = serverInfo?.tools || [];

  return `🧠 **Memory Operations**\n\nAvailable tools: ${availableTools.join(', ')}\n\nMemory operations are available but need specific implementation based on your memory server's API.`;
}

function generateHelpfulResponse(mcpStatus: any, availableServers: Record<string, any>): string {
  const runningServers = mcpStatus.servers ? 
    Object.entries(mcpStatus.servers).filter(([_, s]: [string, any]) => s.status === 'running') : [];

  if (runningServers.length === 0) {
    return "❌ No MCP servers are currently running. Please check your configuration and start some servers.";
  }

  let response = "🤔 I didn't understand that specific request, but here's what I can help you with:\n\n";
  
  for (const [serverName, serverInfo] of runningServers) {
    const server = serverInfo as any;
    if (server.tools && server.tools.length > 0) {
      response += `**${serverName}:**\n`;
      server.tools.forEach((tool: string) => {
        response += `  • ${tool}\n`;
      });
      response += `\n`;
    }
  }

  response += `💡 Try being more specific, or use "list tools" to see everything available.`;
  
  return response;
}
EOF

echo "✅ Created dynamic chat API"

# Update the chat component to better handle responses
cat > src/components/ChatInterface.tsx << 'EOF'
// src/components/ChatInterface.tsx
'use client';

import { useState, useRef, useEffect } from 'react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export default function ChatInterface() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [systemStatus, setSystemStatus] = useState<any>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Load initial welcome message
  useEffect(() => {
    const loadWelcome = async () => {
      try {
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: 'hello' }),
        });
        
        const data = await response.json();
        
        if (data.success) {
          setMessages([{
            id: '1',
            role: 'assistant',
            content: data.response,
            timestamp: new Date()
          }]);
          setSystemStatus(data.mcpStatus);
        }
      } catch (error) {
        console.error('Failed to load welcome message:', error);
        setMessages([{
          id: '1',
          role: 'assistant',
          content: '❌ Failed to connect to MCP system. Please check the server configuration.',
          timestamp: new Date()
        }]);
      }
    };

    loadWelcome();
  }, []);

  const sendMessage = async () => {
    if (!inputValue.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = inputValue;
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: currentInput,
          history: messages
        }),
      });

      const data = await response.json();

      if (data.mcpStatus) {
        setSystemStatus(data.mcpStatus);
      }

      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: data.success ? data.response : (data.fallbackResponse || data.error || 'Sorry, I encountered an error.'),
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);

    } catch (error) {
      console.error('Chat error:', error);
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'Sorry, I\'m having trouble connecting right now. Please check that the MCP system is running.',
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="flex flex-col h-screen max-w-6xl mx-auto bg-white">
      {/* Header with system status */}
      <div className="bg-blue-600 text-white p-4 shadow-md">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-xl font-bold">MCP Chat Interface</h1>
            <p className="text-blue-100 text-sm">Dynamic AI Assistant with Hot-Deployable MCP Servers</p>
          </div>
          {systemStatus && (
            <div className="text-right text-sm">
              <div className="text-blue-100">
                {systemStatus.initialized ? '✅ Connected' : '❌ Disconnected'}
              </div>
              <div className="text-blue-200">
                {systemStatus.runningServers?.length || 0} servers • {' '}
                {systemStatus.runningServers?.reduce((total: number, server: any) => 
                  total + (server.tools?.length || 0), 0) || 0} tools
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-2xl px-4 py-3 rounded-lg ${
                message.role === 'user'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-800 border'
              }`}
            >
              <div className="whitespace-pre-wrap font-mono text-sm">{message.content}</div>
              <div className={`text-xs mt-2 ${
                message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
              }`}>
                {message.timestamp.toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}
        
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-gray-100 text-gray-800 px-4 py-3 rounded-lg border">
              <div className="flex items-center space-x-2">
                <div className="animate-spin h-4 w-4 border-2 border-blue-400 border-t-transparent rounded-full"></div>
                <span>Processing with MCP servers...</span>
              </div>
            </div>
          </div>
        )}
        
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="border-t p-4">
        <div className="flex space-x-2">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Ask me about compliance, blockchain, files, or anything else..."
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
          <button
            onClick={sendMessage}
            disabled={isLoading || !inputValue.trim()}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </div>
        
        {/* Quick actions */}
        <div className="flex flex-wrap gap-2 mt-2">
          {[
            'list tools',
            'system status', 
            'check GLEIF compliance for Acme Corp',
            'list files in data',
            'help'
          ].map((suggestion) => (
            <button
              key={suggestion}
              onClick={() => setInputValue(suggestion)}
              className="px-3 py-1 text-sm bg-gray-100 hover:bg-gray-200 rounded-full text-gray-700"
              disabled={isLoading}
            >
              {suggestion}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
EOF

echo "✅ Updated chat component with dynamic system status"

# Update the main page to use the chat interface
mkdir -p src/app

cat > src/app/page.tsx << 'EOF'
// src/app/page.tsx
import ChatInterface from '../components/ChatInterface';

export default function Home() {
  return (
    <main>
      <ChatInterface />
    </main>
  );
}
EOF

echo "✅ Updated main page"

# Test the API endpoint
echo "🧪 Testing the chat API..."

if npm run build; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 Your dynamic MCP chat interface is ready!"
    echo ""
    echo "Key features:"
    echo "- ✅ Reads MCP config dynamically"
    echo "- ✅ Lists real available tools"
    echo "- ✅ Calls actual MCP server tools"
    echo "- ✅ Provides real-time system status"
    echo "- ✅ Intent detection based on available servers"
    echo ""
    echo "To test:"
    echo "1. npm run dev"
    echo "2. Go to http://localhost:3000"
    echo "3. Try: 'list tools', 'system status', or your compliance queries"
    echo ""
else
    echo "❌ Build failed. Check the errors above."
fi

echo "🔧 Dynamic chat interface setup completed!"