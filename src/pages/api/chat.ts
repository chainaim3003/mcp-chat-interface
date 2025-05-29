// DEBUG: Chat API being called
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
