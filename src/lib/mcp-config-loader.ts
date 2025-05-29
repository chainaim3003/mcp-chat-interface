// src/lib/mcp-config-loader.ts
import fs from 'fs/promises';
import { watch, FSWatcher } from 'fs';
import path from 'path';
import { EventEmitter } from 'events';
import dotenv from 'dotenv';

// Keep the same interface as Claude Desktop config
export interface MCPServerConfig {
  command: string;
  args?: string[];
  env?: Record<string, string>;
  disabled?: boolean;
}

export interface ClaudeMCPConfig {
  mcpServers: Record<string, MCPServerConfig>;
  globalShortcut?: string;
}

export interface ExtendedConfig extends ClaudeMCPConfig {
  // Extended fields for our hot-reload functionality
  _metadata?: {
    version?: string;
    lastUpdated?: string;
    hotReload?: boolean;
  };
  _settings?: {
    autoRestart?: boolean;
    timeout?: number;
    logLevel?: string;
  };
}

export class MCPConfigManager extends EventEmitter {
  private config: ExtendedConfig | null = null;
  private configPath: string;
  private envPath: string;
  private watcher: FSWatcher | null = null;
  private reloadTimeout: NodeJS.Timeout | null = null;
  private initialized = false;

  constructor(
    configPath = './claude_mcp_config.json', 
    envPath = './.env.local'
  ) {
    super();
    this.configPath = path.resolve(configPath);
    this.envPath = path.resolve(envPath);
  }

  async initialize(): Promise<ExtendedConfig> {
    if (this.initialized && this.config) {
      return this.config;
    }

    try {
      // Load environment variables first
      await this.loadEnvironment();
      
      // Load MCP config
      await this.loadConfig();
      
      // Set up file watching for hot reload
      this.setupFileWatcher();
      
      this.initialized = true;
      this.emit('initialized', this.config);
      
      console.log('✅ MCP Config Manager initialized');
      
      if (!this.config) {
        throw new Error('Config initialization failed');
      }
      
      return this.config;
      
    } catch (error) {
      console.error('❌ Failed to initialize MCP Config Manager:', error);
      this.emit('error', error);
      throw error;
    }
  }

  private async loadEnvironment(): Promise<void> {
    try {
      if (await this.fileExists(this.envPath)) {
        dotenv.config({ path: this.envPath });
        console.log(`📁 Loaded environment from ${path.basename(this.envPath)}`);
      }
    } catch (error) {
      console.warn(`⚠️ Could not load environment file: ${error}`);
    }
  }

  private async loadConfig(): Promise<void> {
    try {
      if (!(await this.fileExists(this.configPath))) {
        throw new Error(`Config file not found: ${this.configPath}`);
      }

      const configContent = await fs.readFile(this.configPath, 'utf-8');
      let rawConfig: ExtendedConfig;
      
      try {
        rawConfig = JSON.parse(configContent);
      } catch (parseError) {
        throw new Error(`Invalid JSON in config file: ${parseError}`);
      }

      // Validate that it has the required mcpServers field
      if (!rawConfig.mcpServers || typeof rawConfig.mcpServers !== 'object') {
        throw new Error('Config must contain mcpServers object');
      }

      // Substitute environment variables in the config
      this.config = this.substituteEnvVars(rawConfig);
      
      // Null safety check
      if (!this.config || !this.config.mcpServers) {
        throw new Error('Configuration is null or missing mcpServers');
      }
      
      const serverCount = Object.keys(this.config.mcpServers).length;
      const enabledCount = Object.values(this.config.mcpServers)
        .filter(server => !server.disabled).length;
      
      console.log(`📊 Loaded ${serverCount} MCP servers (${enabledCount} enabled)`);
      
    } catch (error) {
      throw new Error(`Failed to load config from ${this.configPath}: ${error}`);
    }
  }

  private substituteEnvVars(obj: any): any {
    if (typeof obj === 'string') {
      // Replace ${VAR_NAME} with environment variable
      return obj.replace(/\$\{([^}]+)\}/g, (match, varName) => {
        const envValue = process.env[varName];
        if (envValue === undefined) {
          console.warn(`⚠️ Environment variable ${varName} not found`);
          return match; // Keep original if not found
        }
        return envValue;
      });
    } else if (Array.isArray(obj)) {
      return obj.map(item => this.substituteEnvVars(item));
    } else if (obj && typeof obj === 'object') {
      const result: any = {};
      for (const [key, value] of Object.entries(obj)) {
        result[key] = this.substituteEnvVars(value);
      }
      return result;
    }
    return obj;
  }

  private setupFileWatcher(): void {
    if (typeof window !== 'undefined') {
      // Skip file watching in browser environment
      return;
    }
    
    if (!process.env.ENABLE_HOT_RELOAD || process.env.ENABLE_HOT_RELOAD !== 'true') {
      return;
    }
    
    try {
      // Watch both config and env files
      const filesToWatch = [this.configPath, this.envPath];
      
      filesToWatch.forEach(filePath => {
        this.fileExists(filePath).then(exists => {
          if (exists) {
            try {
              const watcher = watch(filePath, (eventType) => {
                if (eventType === 'change') {
                  this.scheduleReload();
                }
              });
              
              console.log(`👀 Watching ${path.basename(filePath)} for changes`);
            } catch (error) {
              console.warn(`⚠️ Could not watch ${filePath}:`, error);
            }
          }
        });
      });
      
    } catch (error) {
      console.warn('⚠️ Could not set up file watcher:', error);
    }
  }

  private scheduleReload(): void {
    if (this.reloadTimeout) {
      clearTimeout(this.reloadTimeout);
    }

    this.reloadTimeout = setTimeout(async () => {
      try {
        console.log('🔄 Configuration file changed, reloading...');
        const oldConfig = this.config;
        
        await this.loadEnvironment();
        await this.loadConfig();
        
        this.emit('configChanged', {
          oldConfig,
          newConfig: this.config
        });
        
        console.log('✅ Configuration reloaded successfully');
      } catch (error) {
        console.error('❌ Failed to reload configuration:', error);
        this.emit('reloadError', error);
      }
    }, 1000); // 1 second debounce
  }

  private async fileExists(filePath: string): Promise<boolean> {
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  // Public API methods with null safety
  getConfig(): ExtendedConfig | null {
    return this.config;
  }

  getMCPServers(): Record<string, MCPServerConfig> {
    return this.config?.mcpServers || {};
  }

  getEnabledServers(): Record<string, MCPServerConfig> {
    if (!this.config?.mcpServers) return {};
    
    return Object.entries(this.config.mcpServers)
      .filter(([_, server]) => !server.disabled)
      .reduce((acc, [name, server]) => {
        acc[name] = server;
        return acc;
      }, {} as Record<string, MCPServerConfig>);
  }

  getServerConfig(serverName: string): MCPServerConfig | null {
    return this.config?.mcpServers?.[serverName] || null;
  }

  isServerEnabled(serverName: string): boolean {
    const server = this.getServerConfig(serverName);
    return server ? !server.disabled : false;
  }

  async updateServerConfig(
    serverName: string, 
    updates: Partial<MCPServerConfig>
  ): Promise<void> {
    if (!this.config?.mcpServers) {
      throw new Error('Config not loaded or mcpServers is null');
    }

    this.config.mcpServers[serverName] = {
      ...this.config.mcpServers[serverName],
      ...updates
    };

    await this.saveConfig();
  }

  private async saveConfig(): Promise<void> {
    if (!this.config) {
      throw new Error('Cannot save null config');
    }

    await fs.writeFile(
      this.configPath,
      JSON.stringify(this.config, null, 2),
      'utf-8'
    );

    console.log('💾 Configuration saved');
  }

  destroy(): void {
    if (this.watcher) {
      this.watcher.close();
    }
    
    if (this.reloadTimeout) {
      clearTimeout(this.reloadTimeout);
    }
    
    this.removeAllListeners();
    this.initialized = false;
  }
}

// Export singleton instance for easy use
export const mcpConfig = new MCPConfigManager();
