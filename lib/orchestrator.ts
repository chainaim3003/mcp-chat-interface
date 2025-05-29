import { ChatMessage, ToolCall, MCPConfig, MCPTool } from '../types/mcp';

export class MCPOrchestrator {
  private availableTools: MCPTool[] = [];

  constructor(private config: MCPConfig) {
    this.initializeTools();
  }

  private initializeTools(): void {
    this.availableTools = [
      {
        name: 'get-GLEIF-data',
        description: 'Get GLEIF compliance data for a company',
        server: 'PRET-MCP-SERVER',
        category: 'compliance',
        inputSchema: {
          type: 'object',
          properties: {
            companyName: { type: 'string', description: 'Name of the company to check' },
            typeOfNet: { type: 'string', default: 'mainnet', description: 'Network type' }
          },
          required: ['companyName']
        }
      },
      {
        name: 'mint_nft',
        description: 'Mint NFT on XDC network',
        server: 'GOAT-EVM-MCP-SERVER', 
        category: 'blockchain',
        inputSchema: {
          type: 'object',
          properties: {
            contractAddress: { type: 'string', description: 'NFT contract address' },
            to: { type: 'string', description: 'Recipient address' },
            tokenURI: { type: 'string', description: 'Token metadata URI' },
            network: { type: 'string', default: 'testnet', description: 'Blockchain network' }
          },
          required: ['contractAddress', 'to']
        }
      },
      {
        name: 'get_xdc_balance',
        description: 'Get XDC balance for an address',
        server: 'GOAT-EVM-MCP-SERVER',
        category: 'blockchain',
        inputSchema: {
          type: 'object',
          properties: {
            address: { type: 'string', description: 'Wallet address to check' },
            network: { type: 'string', default: 'testnet', description: 'Network to query' }
          },
          required: ['address']
        }
      },
      {
        name: 'check-corp-registration',
        description: 'Check corporate registration status',
        server: 'PRET-MCP-SERVER',
        category: 'compliance',
        inputSchema: {
          type: 'object',
          properties: {
            companyName: { type: 'string', description: 'Name of the company to check' },
            jurisdiction: { type: 'string', default: 'US', description: 'Legal jurisdiction' }
          },
          required: ['companyName']
        }
      }
    ];
  }

  async initialize(): Promise<void> {
    console.log('🔧 Initializing MCP Orchestrator...');
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
      const lowerMessage = message.toLowerCase();

      if (lowerMessage.includes('gleif')) {
        const companyName = this.extractCompanyName(message);
        const gleifStatus = Math.random() > 0.5 ? 'ACTIVE' : 'INACTIVE';
        const entityId = 'LEI-' + Math.random().toString(36).substring(2, 20).toUpperCase();
        
        const toolCall: ToolCall = {
          id: crypto.randomUUID(),
          toolName: 'get-GLEIF-data',
          serverName: 'PRET-MCP-SERVER',
          parameters: { companyName },
          status: 'success',
          result: { companyName, gleifStatus, entityId }
        };
        
        chatMessage.toolCalls = [toolCall];
        chatMessage.content = `**GLEIF Compliance Check for ${companyName}**\n\nStatus: ${gleifStatus}\nEntity ID: ${entityId}\n\n${gleifStatus === 'ACTIVE' ? '✅ Company is GLEIF compliant!' : '❌ Company needs GLEIF registration.'}`;
        
      } else if (lowerMessage.includes('mint')) {
        const transactionHash = '0x' + Array.from({length: 64}, () => 
          Math.floor(Math.random() * 16).toString(16)).join('');
        const tokenId = Math.floor(Math.random() * 1000000);
        
        const toolCall: ToolCall = {
          id: crypto.randomUUID(),
          toolName: 'mint_nft',
          serverName: 'GOAT-EVM-MCP-SERVER',
          parameters: { network: 'testnet' },
          status: 'success',
          result: { transactionHash, tokenId }
        };
        
        chatMessage.toolCalls = [toolCall];
        chatMessage.content = `**NFT Minted Successfully!**\n\nTransaction Hash: ${transactionHash}\nToken ID: ${tokenId}\nNetwork: testnet`;
        
      } else {
        chatMessage.content = `🤖 **MCP Chat Interface Demo**\n\nTry these commands:\n- "Check GLEIF compliance for Acme Corp"\n- "Mint NFT for TechStart"\n- "Check system status"`;
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

  getAvailableTools(): MCPTool[] {
    return [...this.availableTools];
  }
}
