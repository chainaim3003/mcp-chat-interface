import { NextRequest, NextResponse } from 'next/server';

// Proper TypeScript interfaces
interface ToolCall {
  id: string;
  toolName: string;
  serverName: string;
  parameters: Record<string, any>;
  status: string;
  result: Record<string, any>;
}

interface MCPResponse {
  id: string;
  role: string;
  content: string;
  timestamp: string;
  toolCalls: ToolCall[];
}

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();
    
    const response: MCPResponse = {
      id: crypto.randomUUID(),
      role: 'assistant',
      content: '',
      timestamp: new Date().toISOString(),
      toolCalls: []
    };

    const lowerMessage = message.toLowerCase();

    if (lowerMessage.includes('gleif')) {
      const companyMatch = message.match(/(?:for|company)\s+([A-Za-z][A-Za-z0-9\s&.-]+?)(?:\s|$|,|\.|!|\?)/i);
      const companyName = companyMatch ? companyMatch[1].trim() : 'Unknown Company';
      
      const gleifStatus = Math.random() > 0.5 ? 'ACTIVE' : 'INACTIVE';
      const entityId = 'LEI-' + Math.random().toString(36).substring(2, 20).toUpperCase();
      
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'get-GLEIF-data',
        serverName: 'PRET-MCP-SERVER',
        parameters: { companyName },
        status: 'success',
        result: { 
          companyName, 
          gleifStatus, 
          entityId,
          lastUpdated: new Date().toISOString()
        }
      };
      
      response.content = `**GLEIF Compliance Check for ${companyName}**\n\nStatus: ${gleifStatus}\nEntity ID: ${entityId}\n\n${gleifStatus === 'ACTIVE' ? '✅ Company is GLEIF compliant!' : '❌ Company needs GLEIF registration.'}`;
      response.toolCalls = [toolCall];
      
    } else if (lowerMessage.includes('mint')) {
      const transactionHash = '0x' + Array.from({length: 64}, () => 
        Math.floor(Math.random() * 16).toString(16)).join('');
      const tokenId = Math.floor(Math.random() * 1000000);
      
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'mint_nft',
        serverName: 'GOAT-EVM-MCP-SERVER',
        parameters: { 
          network: 'testnet',
          contractAddress: '0x1234567890123456789012345678901234567890'
        },
        status: 'success',
        result: { 
          transactionHash, 
          tokenId,
          network: 'testnet',
          gasUsed: '84000'
        }
      };
      
      response.content = `**NFT Minted Successfully!**\n\nTransaction Hash: ${transactionHash}\nToken ID: ${tokenId}\nNetwork: testnet`;
      response.toolCalls = [toolCall];
      
    } else if (lowerMessage.includes('balance')) {
      const addressMatch = message.match(/(0x[a-fA-F0-9]{40})/);
      const address = addressMatch ? addressMatch[1] : '0x1234567890123456789012345678901234567890';
      const balance = (Math.random() * 1000).toFixed(6);
      
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'get_xdc_balance',
        serverName: 'GOAT-EVM-MCP-SERVER',
        parameters: { address, network: 'testnet' },
        status: 'success',
        result: { 
          address, 
          balance, 
          currency: 'XDC',
          network: 'testnet'
        }
      };
      
      response.content = `**XDC Balance Check**\n\nAddress: ${address}\nBalance: ${balance} XDC\nNetwork: testnet`;
      response.toolCalls = [toolCall];
      
    } else if (lowerMessage.includes('status')) {
      response.content = `🔧 **MCP System Status**\n\n✅ PRET-MCP-SERVER: Connected (Demo)\n✅ GOAT-EVM-MCP-SERVER: Connected (Demo)\n✅ Available Tools: 4\n✅ All systems operational!\n\n*Note: This is a demo interface with simulated MCP operations.*`;
      
    } else {
      response.content = `🤖 **Welcome to MCP Chat Interface Demo!**\n\nI can help you with:\n\n**🔍 Compliance Operations:**\n- "Check GLEIF compliance for Acme Corp"\n- "Run compliance workflow for TechStart"\n\n**🎨 NFT Operations:**\n- "Mint NFT for CompanyX"\n- "Deploy NFT contract on testnet"\n\n**💰 Blockchain Operations:**\n- "Check XDC balance for 0x123..."\n- "Get balance for wallet"\n\n**🔄 System Operations:**\n- "Check system status"\n- "List available tools"\n\n**Try asking:** *"Check GLEIF compliance for Acme Corp"*\n\n*This demo uses simulated MCP server responses.*`;
    }
    
    return NextResponse.json(response);
    
  } catch (error) {
    console.error('MCP API Error:', error);
    
    const errorResponse: MCPResponse = {
      id: crypto.randomUUID(),
      role: 'assistant',
      content: `❌ **Error Processing Request**\n\n${error instanceof Error ? error.message : 'An unexpected error occurred.'}`,
      timestamp: new Date().toISOString(),
      toolCalls: []
    };
    
    return NextResponse.json(errorResponse, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    service: 'MCP Chat Interface Demo',
    version: '1.0.0',
    mode: 'demo',
    tools: 4,
    servers: ['PRET-MCP-SERVER (Demo)', 'GOAT-EVM-MCP-SERVER (Demo)'],
    timestamp: new Date().toISOString(),
    note: 'This is a demo interface with simulated MCP operations'
  });
}
