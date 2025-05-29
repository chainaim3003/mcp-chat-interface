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
