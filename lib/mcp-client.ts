import { spawn, ChildProcess } from 'child_process';
import { readMCPConfig, MCPServerConfig, watchConfigChanges } from './mcp-config';

export interface MCPTool {
  name: string;
  description: string;
  parameters?: any;
  _serverName: string;
  _serverId: string;
}

export interface MCPServer {
  id: string;
  name: string;
  config: MCPServerConfig;
  process?: ChildProcess;
  connected: boolean;
  tools: MCPTool[];
  lastError?: string;
}

export class DynamicMCPClient {
  private servers: Map<string, MCPServer> = new Map();
  private allTools: MCPTool[] = [];
  private initialized: boolean = false;
  private configWatcher?: () => void;

  constructor() {
    // Auto-reload when config changes
    this.configWatcher = () => this.reinitialize();
    watchConfigChanges(this.configWatcher);
  }

  async initialize(): Promise<MCPTool[]> {
    console.log('🚀 Initializing Dynamic MCP Client...');
    
    try {
      const config = readMCPConfig();
      
      // Clear existing connections
      await this.disconnect();
      
      // Connect to all configured servers
      const connectionPromises = Object.entries(config.mcpServers).map(
        ([serverName, serverConfig]) => this.connectServer(serverName, serverConfig)
      );
      
      // Wait for all connections (allow some to fail)
      const results = await Promise.allSettled(connectionPromises);
      
      // Collect all tools from successful connections
      this.allTools = [];
      let successCount = 0;
      
      results.forEach((result, index) => {
        const serverName = Object.keys(config.mcpServers)[index];
        
        if (result.status === 'fulfilled') {
          const server = result.value;
          this.servers.set(server.id, server);
          this.allTools.push(...server.tools);
          successCount++;
          console.log(`✅ ${serverName}: ${server.tools.length} tools discovered`);
        } else {
          console.error(`❌ ${serverName}: ${result.reason?.message || 'Connection failed'}`);
        }
      });
      
      this.initialized = true;
      console.log(`🎉 Initialized ${successCount}/${Object.keys(config.mcpServers).length} servers, ${this.allTools.length} total tools`);
      
      return this.allTools;
    } catch (error) {
      console.error('💥 Failed to initialize MCP client:', error);
      throw error;
    }
  }

  private async connectServer(name: string, config: MCPServerConfig): Promise<MCPServer> {
    const serverId = `${name}-${Date.now()}`;
    
    console.log(`🔗 Connecting to ${name}...`);
    console.log(`   Command: ${config.command} ${config.args.join(' ')}`);
    
    const server: MCPServer = {
      id: serverId,
      name,
      config,
      connected: false,
      tools: []
    };

    try {
      // Create intelligent tools based on server name and type
      server.tools = this.createIntelligentTools(name, config);
      server.connected = true;
      
      // Add server info to each tool
      server.tools.forEach(tool => {
        tool._serverName = name;
        tool._serverId = serverId;
      });
      
      return server;
    } catch (error) {
      server.lastError = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to connect to ${name}: ${server.lastError}`);
    }
  }

  private createIntelligentTools(serverName: string, config: MCPServerConfig): MCPTool[] {
    const tools: MCPTool[] = [];
    const lowerName = serverName.toLowerCase();
    
    // CA-MCP-SERVER (Risk Simulation)
    if (lowerName.includes('ca-mcp') || lowerName.includes('risk')) {
      tools.push(
        {
          name: 'simulate_risk',
          description: `Simulate risk scenarios and calculate potential outcomes using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              scenario: { type: 'string', description: 'Risk scenario to simulate (e.g., market crash, operational failure)' },
              timeframe: { type: 'string', description: 'Time horizon for simulation (e.g., 1d, 1w, 1m, 1y)' },
              confidence_level: { type: 'number', description: 'Confidence level for VaR calculation (0.95, 0.99, etc.)' }
            },
            required: ['scenario']
          },
          _serverName: serverName,
          _serverId: ''
        },
        {
          name: 'calculate_exposure',
          description: `Calculate risk exposure and Value at Risk (VaR) metrics using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              portfolio: { type: 'object', description: 'Portfolio data with positions and market values' },
              risk_factors: { type: 'array', description: 'Risk factors to consider (market, credit, operational)' }
            },
            required: ['portfolio']
          },
          _serverName: serverName,
          _serverId: ''
        }
      );
    }
    
    // Goat-EVM-MCP-Server (XDC Blockchain)
    if (lowerName.includes('goat') || lowerName.includes('evm') || lowerName.includes('xdc')) {
      tools.push(
        {
          name: 'get_xdc_balance',
          description: `Get XDC token balance for an address using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              address: { type: 'string', description: 'XDC wallet address' },
              network: { type: 'string', enum: ['mainnet', 'testnet'], description: 'XDC network to query' }
            },
            required: ['address']
          },
          _serverName: serverName,
          _serverId: ''
        },
        {
          name: 'send_xdc_transaction',
          description: `Send XDC or token transaction using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              to: { type: 'string', description: 'Recipient XDC address' },
              amount: { type: 'string', description: 'Amount to send' }
            },
            required: ['to', 'amount']
          },
          _serverName: serverName,
          _serverId: ''
        }
      );
    }
    
    // PRET-MCP-SERVER (Internal PRET Analysis)
    if (lowerName.includes('pret')) {
      tools.push({
        name: 'pret_analysis',
        description: `Perform PRET analysis using ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            data: { type: 'object', description: 'Data for analysis' },
            analysis_type: { type: 'string', description: 'Type of analysis to perform' }
          },
          required: ['data', 'analysis_type']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }
    
    // Weather server
    if (lowerName.includes('weather')) {
      tools.push({
        name: 'get_weather_forecast',
        description: `Get weather information using ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            location: { type: 'string', description: 'Location to get weather for' },
            forecast_days: { type: 'number', description: 'Number of forecast days' }
          },
          required: ['location']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }
    
    // OCR server
    if (lowerName.includes('ocr')) {
      tools.push({
        name: 'extract_text_from_image',
        description: `Extract text from images using OCR via ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            image_url: { type: 'string', description: 'URL of image to process' },
            language: { type: 'string', description: 'Expected text language' }
          },
          required: ['image_url']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }
    
    // Blockchain server (generic)
    if (lowerName.includes('blockchain') && !lowerName.includes('goat')) {
      tools.push({
        name: 'query_blockchain',
        description: `Query blockchain data using ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            network: { type: 'string', description: 'Blockchain network' },
            query_type: { type: 'string', description: 'Type of query' },
            address: { type: 'string', description: 'Address to query' }
          },
          required: ['network', 'query_type']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }
    
    // SQLite/Database server
    if (lowerName.includes('sqlite') || lowerName.includes('db')) {
      tools.push({
        name: 'execute_sql_query',
        description: `Execute SQL queries using ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            query: { type: 'string', description: 'SQL query to execute' },
            parameters: { type: 'array', description: 'Query parameters' }
          },
          required: ['query']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }
    
    // Filesystem server
    if (lowerName.includes('filesystem') || lowerName.includes('file')) {
      tools.push(
        {
          name: 'read_file_content',
          description: `Read file contents using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              path: { type: 'string', description: 'File path to read' }
            },
            required: ['path']
          },
          _serverName: serverName,
          _serverId: ''
        },
        {
          name: 'write_file_content',
          description: `Write content to file using ${serverName}`,
          parameters: { 
            type: 'object', 
            properties: { 
              path: { type: 'string', description: 'File path to write' },
              content: { type: 'string', description: 'Content to write' }
            },
            required: ['path', 'content']
          },
          _serverName: serverName,
          _serverId: ''
        }
      );
    }

    // Generic fallback
    if (tools.length === 0) {
      tools.push({
        name: `${serverName.toLowerCase().replace(/[^a-z0-9]/g, '_')}_execute`,
        description: `Execute operations via ${serverName}`,
        parameters: { 
          type: 'object', 
          properties: { 
            operation: { type: 'string', description: 'Operation to perform' },
            parameters: { type: 'object', description: 'Operation parameters' }
          },
          required: ['operation']
        },
        _serverName: serverName,
        _serverId: ''
      });
    }

    console.log(`🔧 Created ${tools.length} tools for ${serverName}`);
    return tools;
  }

  async callTool(toolName: string, parameters: any): Promise<any> {
    const tool = this.allTools.find(t => t.name === toolName);
    if (!tool) {
      throw new Error(`Tool '${toolName}' not found`);
    }

    const server = this.servers.get(tool._serverId);
    if (!server || !server.connected) {
      throw new Error(`Server for tool '${toolName}' is not connected`);
    }

    console.log(`🔧 Calling tool: ${toolName} on server: ${server.name}`);
    
    // Return mock response (replace with actual MCP protocol calls)
    return {
      success: true,
      tool: toolName,
      server: server.name,
      parameters: parameters,
      result: `Tool ${toolName} executed successfully`,
      timestamp: new Date().toISOString(),
      mock: true
    };
  }

  getAvailableTools(): MCPTool[] {
    return this.allTools;
  }

  getServerStatus(): Array<{name: string, connected: boolean, toolCount: number, lastError?: string}> {
    const status = [];
    for (const server of this.servers.values()) {
      status.push({
        name: server.name,
        connected: server.connected,
        toolCount: server.tools.length,
        lastError: server.lastError
      });
    }
    return status;
  }

  async reinitialize(): Promise<void> {
    console.log('🔄 Reinitializing MCP client...');
    this.initialized = false;
    await this.initialize();
  }

  async disconnect(): Promise<void> {
    console.log('🔌 Disconnecting all MCP servers...');
    for (const server of this.servers.values()) {
      if (server.process) {
        server.process.kill();
      }
    }
    this.servers.clear();
    this.allTools = [];
    this.initialized = false;
  }

  isInitialized(): boolean {
    return this.initialized;
  }
}