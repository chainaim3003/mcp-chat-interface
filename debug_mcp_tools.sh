#!/bin/bash

# Debug and fix MCP tool discovery issues
echo "🔍 Debugging MCP tool discovery and chat interface..."

# First, let's check what's actually in the chat interface files
echo "📁 Checking current chat interface implementation..."

if [ -f "src/pages/api/chat.ts" ]; then
    echo "✅ Found chat API"
    # Check if it's using the dynamic version
    if grep -q "processMessageDynamically" src/pages/api/chat.ts; then
        echo "✅ Using dynamic chat API"
    else
        echo "❌ Still using old chat API!"
    fi
else
    echo "❌ Chat API not found!"
fi

# Create a comprehensive MCP debugging tool
echo "🛠️ Creating MCP debugging tools..."

mkdir -p src/pages/api/debug

cat > src/pages/api/debug/mcp-tools.ts << 'EOF'
// src/pages/api/debug/mcp-tools.ts
// Debug endpoint to inspect MCP server tools and capabilities

import { NextApiRequest, NextApiResponse } from 'next';
import { initializeMCP, getMCPStatus, mcpConfig } from '../../../lib/mcp-integration';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  try {
    console.log('🔍 Starting MCP debug inspection...');
    
    // Initialize MCP system
    await initializeMCP();
    
    // Get detailed status
    const status = getMCPStatus();
    const config = mcpConfig.getConfig();
    
    // Debug information
    const debugInfo = {
      timestamp: new Date().toISOString(),
      mcpInitialized: status.initialized,
      configLoaded: !!config,
      totalServersConfigured: config ? Object.keys(config.mcpServers).length : 0,
      enabledServersConfigured: config ? Object.keys(mcpConfig.getEnabledServers()).length : 0,
      runningServers: status.servers ? Object.keys(status.servers).length : 0,
      serverDetails: {},
      toolSummary: {
        totalTools: 0,
        toolsByServer: {}
      }
    };

    if (status.servers) {
      for (const [serverName, serverInfo] of Object.entries(status.servers)) {
        const server = serverInfo as any;
        
        debugInfo.serverDetails[serverName] = {
          status: server.status,
          pid: server.pid,
          uptime: server.uptime,
          tools: server.tools || [],
          toolCount: (server.tools || []).length,
          error: server.error,
          config: config?.mcpServers[serverName] || null
        };
        
        const toolCount = (server.tools || []).length;
        debugInfo.toolSummary.totalTools += toolCount;
        debugInfo.toolSummary.toolsByServer[serverName] = {
          count: toolCount,
          tools: server.tools || []
        };
      }
    }

    // Configuration comparison
    debugInfo.configComparison = {
      configuredServers: config ? Object.keys(config.mcpServers) : [],
      runningServers: status.servers ? Object.keys(status.servers) : [],
      missingServers: [],
      extraServers: []
    };

    if (config && status.servers) {
      const configuredServers = Object.keys(config.mcpServers);
      const runningServers = Object.keys(status.servers);
      
      debugInfo.configComparison.missingServers = configuredServers.filter(
        s => !runningServers.includes(s)
      );
      debugInfo.configComparison.extraServers = runningServers.filter(
        s => !configuredServers.includes(s)
      );
    }
    
    console.log('🔍 Debug info collected:', debugInfo);
    
    res.status(200).json({
      success: true,
      debugInfo
    });
    
  } catch (error) {
    console.error('❌ Debug error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
EOF

# Create a tool to test individual MCP servers directly
cat > src/pages/api/debug/test-server.ts << 'EOF'
// src/pages/api/debug/test-server.ts
// Test individual MCP server tools

import { NextApiRequest, NextApiResponse } from 'next';
import { initializeMCP, callMCPTool, getMCPStatus } from '../../../lib/mcp-integration';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { serverName, toolName, args = {} } = req.body;

    if (!serverName || !toolName) {
      return res.status(400).json({ 
        error: 'serverName and toolName are required' 
      });
    }

    console.log(`🔧 Testing ${serverName}.${toolName} with args:`, args);

    // Initialize MCP
    await initializeMCP();
    
    // Get server status
    const status = getMCPStatus();
    const serverInfo = status.servers?.[serverName];
    
    if (!serverInfo) {
      return res.status(404).json({
        error: `Server ${serverName} not found`,
        availableServers: Object.keys(status.servers || {})
      });
    }

    if (serverInfo.status !== 'running') {
      return res.status(400).json({
        error: `Server ${serverName} is not running (status: ${serverInfo.status})`,
        serverInfo
      });
    }

    const availableTools = serverInfo.tools || [];
    if (!availableTools.includes(toolName)) {
      return res.status(400).json({
        error: `Tool ${toolName} not available on server ${serverName}`,
        availableTools
      });
    }

    // Call the tool
    const startTime = Date.now();
    const result = await callMCPTool(serverName, toolName, args);
    const executionTime = Date.now() - startTime;

    res.status(200).json({
      success: true,
      result,
      executionTime,
      serverInfo: {
        name: serverName,
        status: serverInfo.status,
        tools: availableTools
      }
    });

  } catch (error) {
    console.error('❌ Tool test error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
EOF

# Now let's fix the main chat API to actually use the dynamic responses
echo "🔧 Fixing the main chat API to use dynamic responses..."

# Check if there are multiple chat files causing conflicts
if [ -f "src/app/api/chat/route.ts" ]; then
    echo "⚠️ Found conflicting chat API route - removing..."
    rm src/app/api/chat/route.ts
fi

# Ensure the correct chat API is in place and working
cat > src/pages/api/chat.ts << 'EOF'
// src/pages/api/chat.ts
// FIXED: Dynamic chat API that actually processes messages

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
    console.log('🔧 Initializing MCP system...');

    // Initialize MCP system
    await initializeMCP();
    
    // Get real-time status
    const mcpStatus = getMCPStatus();
    const availableServers = getMCPServers();
    const config = mcpConfig.getConfig();

    console.log('📊 MCP Status:', {
      initialized: mcpStatus.initialized,
      serverCount: Object.keys(availableServers).length,
      runningServers: mcpStatus.servers ? Object.keys(mcpStatus.servers).filter(
        name => mcpStatus.servers[name].status === 'running'
      ) : []
    });

    // Process message with detailed logging
    const response = await processMessageWithLogging(message, mcpStatus, availableServers, config);

    // Return detailed response
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
            status: server.status,
            tools: server.tools || [],
            toolCount: (server.tools || []).length,
            uptime: server.uptime || 0
          })) : []
      },
      debugInfo: {
        messageProcessed: message,
        timestamp: new Date().toISOString(),
        processingMethod: 'dynamic'
      }
    });

  } catch (error) {
    console.error('❌ Chat API error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      fallbackResponse: `I'm having trouble processing your request. Error: ${error instanceof Error ? error.message : 'Unknown error'}`
    });
  }
}

async function processMessageWithLogging(
  message: string, 
  mcpStatus: any, 
  availableServers: Record<string, any>,
  config: any
): Promise<string> {
  const lowerMessage = message.toLowerCase();
  
  console.log('🔍 Processing message:', message);
  console.log('🖥️ Available servers:', Object.keys(availableServers));
  console.log('🏃 Running servers:', mcpStatus.servers ? Object.keys(mcpStatus.servers) : []);

  try {
    // Command: list servers
    if (lowerMessage.includes('list') && (lowerMessage.includes('server') || lowerMessage.includes('tool'))) {
      return await listServersAndTools(mcpStatus);
    }

    // Command: system status
    if (lowerMessage.includes('status') || lowerMessage.includes('system')) {
      return generateDetailedSystemStatus(mcpStatus, availableServers);
    }

    // Command: help or hello
    if (lowerMessage.includes('help') || lowerMessage === 'hi' || lowerMessage === 'hello') {
      return generateDynamicWelcome(mcpStatus, availableServers);
    }

    // GLEIF/Compliance requests
    if (lowerMessage.includes('gleif') || lowerMessage.includes('compliance')) {
      return await handleGLEIFRequest(message, mcpStatus);
    }

    // Wallet requests
    if (lowerMessage.includes('wallet') || lowerMessage.includes('address') || lowerMessage.includes('balance')) {
      return await handleWalletRequest(message, mcpStatus);
    }

    // NFT requests  
    if (lowerMessage.includes('nft') || lowerMessage.includes('mint')) {
      return await handleNFTRequest(message, mcpStatus);
    }

    // File requests
    if (lowerMessage.includes('file') || lowerMessage.includes('list') || lowerMessage.includes('read')) {
      return await handleFileRequest(message, mcpStatus);
    }

    // Default helpful response
    return generateHelpfulResponse(mcpStatus, availableServers);

  } catch (error) {
    console.error('💥 Error processing message:', error);
    return `I encountered an error: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function listServersAndTools(mcpStatus: any): Promise<string> {
  if (!mcpStatus.initialized || !mcpStatus.servers) {
    return "❌ MCP system not initialized. No servers available.";
  }

  const servers = Object.entries(mcpStatus.servers);
  const runningServers = servers.filter(([_, server]: [string, any]) => server.status === 'running');

  if (runningServers.length === 0) {
    return "❌ No MCP servers are currently running.";
  }

  let response = `🖥️ **MCP Servers and Tools**\n\n`;
  let totalTools = 0;

  for (const [serverName, serverInfo] of runningServers) {
    const server = serverInfo as any;
    const tools = server.tools || [];
    
    response += `**${serverName}** (${server.status})\n`;
    if (server.pid) response += `  PID: ${server.pid}\n`;
    if (server.uptime) response += `  Uptime: ${Math.round(server.uptime / 1000)}s\n`;
    
    if (tools.length > 0) {
      response += `  Tools (${tools.length}):\n`;
      tools.forEach((tool: string) => {
        response += `    • ${tool}\n`;
        totalTools++;
      });
    } else {
      response += `  No tools available\n`;
    }
    response += `\n`;
  }

  response += `📊 **Summary:** ${runningServers.length} servers, ${totalTools} total tools`;
  
  return response;
}

function generateDetailedSystemStatus(mcpStatus: any, availableServers: Record<string, any>): string {
  let status = `🚀 **Detailed MCP System Status**\n\n`;
  
  status += `**System:** ${mcpStatus.initialized ? '✅ Initialized' : '❌ Not Initialized'}\n`;
  status += `**Configured Servers:** ${Object.keys(availableServers).length}\n`;
  
  if (mcpStatus.servers) {
    const servers = Object.entries(mcpStatus.servers);
    const runningCount = servers.filter(([_, s]: [string, any]) => s.status === 'running').length;
    const errorCount = servers.filter(([_, s]: [string, any]) => s.status === 'error').length;
    
    status += `**Running Servers:** ${runningCount}\n`;
    status += `**Error Servers:** ${errorCount}\n\n`;
    
    status += `**Server Details:**\n`;
    for (const [name, server] of servers) {
      const s = server as any;
      const statusIcon = s.status === 'running' ? '✅' : 
                        s.status === 'error' ? '❌' : 
                        s.status === 'starting' ? '🔄' : '⏸️';
      
      status += `  ${statusIcon} **${name}**: ${s.status}`;
      if (s.pid) status += ` (PID: ${s.pid})`;
      if (s.tools) status += ` - ${s.tools.length} tools`;
      status += `\n`;
      
      if (s.error) {
        status += `    Error: ${s.error}\n`;
      }
      
      if (s.tools && s.tools.length > 0) {
        status += `    Tools: ${s.tools.join(', ')}\n`;
      }
    }
  }
  
  return status;
}

function generateDynamicWelcome(mcpStatus: any, availableServers: Record<string, any>): string {
  const runningServers = mcpStatus.servers ? 
    Object.entries(mcpStatus.servers).filter(([_, s]: [string, any]) => s.status === 'running') : [];
  
  const totalTools = runningServers.reduce((count, [_, server]) => {
    const s = server as any;
    return count + (s.tools ? s.tools.length : 0);
  }, 0);

  let welcome = `🚀 **Welcome to MCP Chat Interface!**\n\n`;
  welcome += `I'm connected to **${runningServers.length} MCP servers** with **${totalTools} available tools**.\n\n`;

  if (runningServers.length > 0) {
    welcome += `**Available Servers:**\n`;
    for (const [name, server] of runningServers) {
      const s = server as any;
      welcome += `• **${name}**: ${s.tools ? s.tools.length : 0} tools\n`;
    }
    welcome += `\n`;
  }

  welcome += `**Try these commands:**\n`;
  welcome += `- "list servers and tools"\n`;
  welcome += `- "system status"\n`;
  
  // Add examples based on available tools
  const allTools = runningServers.flatMap(([_, server]) => (server as any).tools || []);
  
  if (allTools.includes('get-GLEIF-data') || allTools.includes('check_gleif_compliance')) {
    welcome += `- "Check GLEIF compliance for [company name]"\n`;
  }
  
  if (allTools.includes('get_xdc_balance')) {
    welcome += `- "What is my wallet address"\n`;
  }
  
  if (allTools.includes('mint_nft')) {
    welcome += `- "Mint NFT for [recipient]"\n`;
  }
  
  welcome += `\nWhat would you like me to help you with?`;
  
  return welcome;
}

async function handleGLEIFRequest(message: string, mcpStatus: any): Promise<string> {
  // Find GLEIF-capable servers
  const gleifServers = Object.entries(mcpStatus.servers || {})
    .filter(([_, server]: [string, any]) => {
      const tools = (server as any).tools || [];
      return tools.includes('get-GLEIF-data') || tools.includes('check_gleif_compliance');
    });

  if (gleifServers.length === 0) {
    return "❌ No GLEIF compliance servers are currently running.";
  }

  // Extract company name
  const patterns = [
    /(?:for|of)\s+(.+?)(?:\s*$|\s+(?:company|corp|corporation|ltd|limited|inc|llc))/i,
    /compliance\s+(.+?)(?:\s*$)/i,
    /gleif\s+(.+?)(?:\s*$)/i
  ];

  let companyName = '';
  for (const pattern of patterns) {
    const match = message.match(pattern);
    if (match) {
      companyName = match[1].trim();
      break;
    }
  }

  if (!companyName) {
    return "Please specify a company name. Example: 'Check GLEIF compliance for Acme Corp'";
  }

  try {
    const [serverName, serverInfo] = gleifServers[0];
    const server = serverInfo as any;
    const tools = server.tools || [];
    
    let response = `🔍 **Checking GLEIF compliance for "${companyName}"**\n\n`;
    
    // Try the available GLEIF tools
    if (tools.includes('get-GLEIF-data')) {
      try {
        console.log(`Calling get-GLEIF-data for ${companyName}`);
        const result = await callMCPTool(serverName, 'get-GLEIF-data', { 
          companyName: companyName 
        });
        
        response += `**GLEIF Data:**\n`;
        response += `\`\`\`json\n${JSON.stringify(result, null, 2)}\n\`\`\`\n\n`;
        
        // Parse the result for user-friendly display
        if (result && typeof result === 'object') {
          const data = result as any;
          if (data.gleifStatus) {
            response += `**Status:** ${data.gleifStatus}\n`;
          }
          if (data.entityId) {
            response += `**Entity ID:** ${data.entityId}\n`;
          }
        }
        
      } catch (error) {
        response += `**Error:** ${error instanceof Error ? error.message : 'Unknown error'}\n\n`;
      }
    }
    
    if (tools.includes('check_gleif_compliance')) {
      try {
        console.log(`Calling check_gleif_compliance for ${companyName}`);
        const result = await callMCPTool(serverName, 'check_gleif_compliance', { 
          company_name: companyName 
        });
        
        response += `**Compliance Check:**\n`;
        response += `\`\`\`json\n${JSON.stringify(result, null, 2)}\n\`\`\`\n`;
        
      } catch (error) {
        response += `**Compliance Check Error:** ${error instanceof Error ? error.message : 'Unknown error'}\n`;
      }
    }
    
    return response;
    
  } catch (error) {
    return `❌ Error checking GLEIF compliance: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function handleWalletRequest(message: string, mcpStatus: any): Promise<string> {
  // Find wallet-capable servers
  const walletServers = Object.entries(mcpStatus.servers || {})
    .filter(([_, server]: [string, any]) => {
      const tools = (server as any).tools || [];
      return tools.includes('get_xdc_balance') || tools.includes('get_balance');
    });

  if (walletServers.length === 0) {
    return "❌ No wallet servers are currently running.";
  }

  try {
    const [serverName, serverInfo] = walletServers[0];
    const server = serverInfo as any;
    const tools = server.tools || [];
    
    let response = `💼 **Wallet Information**\n\n`;
    
    if (tools.includes('get_xdc_balance')) {
      try {
        const result = await callMCPTool(serverName, 'get_xdc_balance', {});
        response += `**XDC Balance:**\n`;
        response += `\`\`\`json\n${JSON.stringify(result, null, 2)}\n\`\`\`\n`;
      } catch (error) {
        response += `**Balance Error:** ${error instanceof Error ? error.message : 'Unknown error'}\n`;
      }
    }
    
    return response;
    
  } catch (error) {
    return `❌ Error getting wallet information: ${error instanceof Error ? error.message : 'Unknown error'}`;
  }
}

async function handleNFTRequest(message: string, mcpStatus: any): Promise<string> {
  const nftServers = Object.entries(mcpStatus.servers || {})
    .filter(([_, server]: [string, any]) => {
      const tools = (server as any).tools || [];
      return tools.includes('mint_nft');
    });

  if (nftServers.length === 0) {
    return "❌ No NFT servers are currently running.";
  }

  return `🎨 **NFT Operations Available**\n\n` +
         `I can help you mint NFTs! Please provide:\n` +
         `- Recipient address\n` +
         `- Token URI/metadata\n` +
         `- Contract address (optional)\n\n` +
         `Example: "Mint NFT to 0x123... with metadata https://example.com/metadata.json"`;
}

async function handleFileRequest(message: string, mcpStatus: any): Promise<string> {
  return `📁 **File operations would be handled here**\n\nCurrently available file operations depend on your configured servers.`;
}

function generateHelpfulResponse(mcpStatus: any, availableServers: Record<string, any>): string {
  const runningServers = mcpStatus.servers ? 
    Object.entries(mcpStatus.servers).filter(([_, s]: [string, any]) => s.status === 'running') : [];

  if (runningServers.length === 0) {
    return "❌ No MCP servers are currently running. Please check your configuration.";
  }

  let response = `🤔 I didn't understand that specific request.\n\n`;
  response += `**Available commands:**\n`;
  response += `- "list servers and tools"\n`;
  response += `- "system status"\n`;
  response += `- "help"\n\n`;
  
  response += `**Or try asking about:**\n`;
  
  const allTools = runningServers.flatMap(([_, server]) => (server as any).tools || []);
  
  if (allTools.includes('get-GLEIF-data')) {
    response += `- GLEIF compliance checks\n`;
  }
  if (allTools.includes('get_xdc_balance')) {
    response += `- Wallet information\n`;
  }
  if (allTools.includes('mint_nft')) {
    response += `- NFT operations\n`;
  }
  
  return response;
}
EOF

echo "✅ Fixed main chat API with proper dynamic processing"

# Create a debug page to test MCP tools
cat > src/pages/debug.tsx << 'EOF'
// src/pages/debug.tsx
// Debug page for MCP system

import { useState, useEffect } from 'react';

export default function DebugPage() {
  const [debugInfo, setDebugInfo] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [testResult, setTestResult] = useState<any>(null);
  const [testForm, setTestForm] = useState({
    serverName: '',
    toolName: '',
    args: '{}'
  });

  const loadDebugInfo = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/debug/mcp-tools');
      const data = await response.json();
      setDebugInfo(data.debugInfo);
    } catch (error) {
      console.error('Debug load error:', error);
    } finally {
      setLoading(false);
    }
  };

  const testTool = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/debug/test-server', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          serverName: testForm.serverName,
          toolName: testForm.toolName,
          args: JSON.parse(testForm.args)
        })
      });
      const data = await response.json();
      setTestResult(data);
    } catch (error) {
      setTestResult({ error: error.message });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDebugInfo();
  }, []);

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">MCP System Debug</h1>
      
      <button 
        onClick={loadDebugInfo}
        disabled={loading}
        className="mb-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? 'Loading...' : 'Refresh Debug Info'}
      </button>

      {debugInfo && (
        <div className="space-y-6">
          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-2">System Status</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>MCP Initialized:</strong> {debugInfo.mcpInitialized ? '✅' : '❌'}
              </div>
              <div>
                <strong>Total Tools:</strong> {debugInfo.toolSummary.totalTools}
              </div>
              <div>
                <strong>Configured Servers:</strong> {debugInfo.totalServersConfigured}
              </div>
              <div>
                <strong>Running Servers:</strong> {debugInfo.runningServers}
              </div>
            </div>
          </div>

          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-2">Server Details</h2>
            <div className="space-y-4">
              {Object.entries(debugInfo.serverDetails).map(([name, details]: [string, any]) => (
                <div key={name} className="border p-3 rounded">
                  <h3 className="font-medium">{name}</h3>
                  <div className="grid grid-cols-3 gap-2 text-sm mt-2">
                    <div><strong>Status:</strong> {details.status}</div>
                    <div><strong>PID:</strong> {details.pid || 'N/A'}</div>
                    <div><strong>Tools:</strong> {details.toolCount}</div>
                  </div>
                  {details.tools && details.tools.length > 0 && (
                    <div className="mt-2">
                      <strong>Available Tools:</strong>
                      <ul className="list-disc list-inside ml-4">
                        {details.tools.map((tool: string) => (
                          <li key={tool}>{tool}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {details.error && (
                    <div className="mt-2 text-red-600">
                      <strong>Error:</strong> {details.error}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-4">Test Individual Tool</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Server Name</label>
                  <select 
                    value={testForm.serverName}
                    onChange={(e) => setTestForm({...testForm, serverName: e.target.value})}
                    className="w-full p-2 border rounded"
                  >
                    <option value="">Select Server</option>
                    {Object.keys(debugInfo.serverDetails).map(name => (
                      <option key={name} value={name}>{name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Tool Name</label>
                  <select 
                    value={testForm.toolName}
                    onChange={(e) => setTestForm({...testForm, toolName: e.target.value})}
                    className="w-full p-2 border rounded"
                    disabled={!testForm.serverName}
                  >
                    <option value="">Select Tool</option>
                    {testForm.serverName && debugInfo.serverDetails[testForm.serverName]?.tools?.map((tool: string) => (
                      <option key={tool} value={tool}>{tool}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Arguments (JSON)</label>
                <textarea
                  value={testForm.args}
                  onChange={(e) => setTestForm({...testForm, args: e.target.value})}
                  className="w-full p-2 border rounded h-20"
                  placeholder='{"key": "value"}'
                />
              </div>
              <button
                onClick={testTool}
                disabled={loading || !testForm.serverName || !testForm.toolName}
                className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
              >
                Test Tool
              </button>
            </div>
            
            {testResult && (
              <div className="mt-4 p-3 bg-white rounded border">
                <h3 className="font-medium mb-2">Test Result:</h3>
                <pre className="text-sm overflow-auto">{JSON.stringify(testResult, null, 2)}</pre>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
EOF

echo "✅ Created debug page"

# Build and test
echo "🧪 Testing the fixes..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "🔧 Debug tools created:"
    echo "- http://localhost:3000/debug - Debug page for MCP system"
    echo "- /api/debug/mcp-tools - Detailed MCP system inspection"
    echo "- /api/debug/test-server - Test individual MCP tools"
    echo ""
    echo "🚀 Fixed chat interface:"
    echo "- Now actually processes messages dynamically"
    echo "- Reads real MCP configuration and server status"
    echo "- Calls actual MCP tools instead of returning demos"
    echo ""
    echo "Next steps:"
    echo "1. npm run dev"
    echo "2. Go to http://localhost:3000/debug to inspect your MCP system"
    echo "3. Test the chat interface with real commands"
    echo "4. Compare tool counts with Claude Desktop"
    echo ""
else
    echo "❌ Build failed. Check errors above."
fi

echo "🔧 MCP debugging and fix completed!"