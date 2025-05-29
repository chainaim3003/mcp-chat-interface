import fs from 'fs';
import path from 'path';

export interface MCPServerConfig {
  command: string;
  args: string[];
  env?: Record<string, string>;
}

export interface MCPConfig {
  mcpServers: Record<string, MCPServerConfig>;
}

export function readMCPConfig(): MCPConfig {
  const configPath = path.join(process.cwd(), 'claude_mcp_config.json');
  
  if (!fs.existsSync(configPath)) {
    throw new Error(`MCP config file not found at: ${configPath}`);
  }
  
  try {
    const configContent = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configContent);
    
    if (!config.mcpServers) {
      throw new Error('Invalid config: mcpServers property is missing');
    }
    
    console.log(`📄 Loaded MCP config with ${Object.keys(config.mcpServers).length} servers`);
    return config;
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error(`Invalid JSON in claude_mcp_config.json: ${error.message}`);
    }
    throw error;
  }
}

export function getServerNames(): string[] {
  const config = readMCPConfig();
  return Object.keys(config.mcpServers);
}

export function getServerConfig(serverName: string): MCPServerConfig {
  const config = readMCPConfig();
  const serverConfig = config.mcpServers[serverName];
  
  if (!serverConfig) {
    throw new Error(`Server '${serverName}' not found in config`);
  }
  
  return serverConfig;
}

export function watchConfigChanges(callback: (config: MCPConfig) => void) {
  const configPath = path.join(process.cwd(), 'claude_mcp_config.json');
  
  console.log(`👀 Watching for config changes: ${configPath}`);
  
  fs.watchFile(configPath, (curr, prev) => {
    if (curr.mtime !== prev.mtime) {
      console.log('🔄 Config file changed, reloading...');
      try {
        const newConfig = readMCPConfig();
        callback(newConfig);
      } catch (error) {
        console.error('❌ Failed to reload config:', error);
      }
    }
  });
}