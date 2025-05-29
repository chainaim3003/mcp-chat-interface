// src/lib/mcp-server-manager.ts
import { EventEmitter } from 'events';
import { spawn, ChildProcess } from 'child_process';
import { MCPConfigManager, MCPServerConfig } from './mcp-config-loader';

// Use dynamic imports to avoid compilation issues if MCP SDK is not installed
let Client: any;
let StdioClientTransport: any;

async function loadMCPSDK() {
  try {
    const clientModule = await import('@modelcontextprotocol/sdk/client/index.js');
    const transportModule = await import('@modelcontextprotocol/sdk/client/stdio.js');
    
    Client = clientModule.Client;
    StdioClientTransport = transportModule.StdioClientTransport;
    
    return true;
  } catch (error) {
    console.warn('⚠️ MCP SDK not available, running in compatibility mode');
    return false;
  }
}

export interface MCPServerInstance {
  name: string;
  config: MCPServerConfig;
  process?: ChildProcess;
  client?: any; // MCP Client instance
  transport?: any;
  status: 'starting' | 'running' | 'stopped' | 'error' | 'disabled';
  error?: string;
  startTime?: Date;
  tools?: string[];
  pid?: number;
}

export class MCPServerManager extends EventEmitter {
  private servers = new Map<string, MCPServerInstance>();
  private configManager: MCPConfigManager;
  private sdkAvailable = false;
  private shutdownInProgress = false;

  constructor(configManager: MCPConfigManager) {
    super();
    this.configManager = configManager;
    
    // Listen for config changes for hot reload
    this.configManager.on('configChanged', this.handleConfigChange.bind(this));
  }

  async initialize(): Promise<void> {
    // Skip initialization in browser environment
    if (typeof window !== 'undefined') {
      console.log('📱 Browser environment detected - MCP server management disabled');
      return;
    }

    console.log('🚀 Starting MCP Server Manager...');
    
    // Try to load MCP SDK
    this.sdkAvailable = await loadMCPSDK();
    
    if (!this.sdkAvailable) {
      console.log('📝 Running in process-only mode (MCP SDK features disabled)');
    }

    // Start all enabled servers
    const enabledServers = this.configManager.getEnabledServers();
    
    for (const [serverName, serverConfig] of Object.entries(enabledServers)) {
      await this.startServer(serverName, serverConfig);
    }

    console.log(`✅ MCP Server Manager initialized with ${this.servers.size} servers`);
  }

  private async startServer(
    serverName: string, 
    config: MCPServerConfig
  ): Promise<void> {
    // Skip in browser environment
    if (typeof window !== 'undefined') {
      return;
    }

    console.log(`🔄 Starting MCP server: ${serverName}`);
    
    const instance: MCPServerInstance = {
      name: serverName,
      config,
      status: 'starting',
      startTime: new Date()
    };

    this.servers.set(serverName, instance);

    try {
      // Start the process
      await this.startProcess(instance);
      
      // If MCP SDK is available, set up client
      if (this.sdkAvailable && instance.process) {
        await this.setupMCPClient(instance);
      }

      instance.status = 'running';
      console.log(`✅ Server ${serverName} started (PID: ${instance.pid})`);
      
      this.emit('serverStarted', serverName, instance);
      
    } catch (error) {
      instance.status = 'error';
      instance.error = error instanceof Error ? error.message : String(error);
      
      console.error(`❌ Failed to start server ${serverName}:`, error);
      this.emit('serverError', serverName, error);
    }
  }

  private async startProcess(instance: MCPServerInstance): Promise<void> {
    const { config } = instance;
    
    // Prepare environment variables
    const env = {
      ...process.env,
      ...(config.env || {})
    };

    // Start the child process
    const childProcess = spawn(config.command, config.args || [], {
      env,
      stdio: this.sdkAvailable ? ['pipe', 'pipe', 'pipe'] : 'inherit'
    });

    instance.process = childProcess;
    instance.pid = childProcess.pid;

    // Set up process event handlers
    childProcess.on('error', (error) => {
      console.error(`❌ Process error for ${instance.name}:`, error);
      instance.status = 'error';
      instance.error = error.message;
      this.emit('serverError', instance.name, error);
    });

    childProcess.on('exit', (code, signal) => {
      console.log(`🔚 Server ${instance.name} exited (code: ${code}, signal: ${signal})`);
      
      if (instance.status === 'running') {
        instance.status = 'stopped';
      }

      // Auto-restart if configured and not a clean shutdown
      if (this.shouldAutoRestart(instance, code) && !this.shutdownInProgress) {
        console.log(`🔄 Auto-restarting server ${instance.name} in 2 seconds...`);
        setTimeout(() => {
          if (!this.shutdownInProgress) {
            this.restartServer(instance.name);
          }
        }, 2000);
      }

      this.emit('serverStopped', instance.name, code, signal);
    });

    // Wait a bit to ensure process started
    await new Promise(resolve => setTimeout(resolve, 500));

    if (childProcess.exitCode !== null) {
      throw new Error(`Process exited immediately with code ${childProcess.exitCode}`);
    }
  }

  private async setupMCPClient(instance: MCPServerInstance): Promise<void> {
    if (!instance.process || !Client || !StdioClientTransport) {
      return;
    }

    try {
      // Set up MCP client transport
      const transport = new StdioClientTransport({
        reader: instance.process.stdout!,
        writer: instance.process.stdin!
      });

      // Create MCP client
      const client = new Client(
        {
          name: `mcp-chat-interface-${instance.name}`,
          version: '1.0.0'
        },
        {
          capabilities: {
            tools: {},
            resources: {}
          }
        }
      );

      // Connect to the server
      await client.connect(transport);

      instance.client = client;
      instance.transport = transport;

      // Load server capabilities
      await this.loadServerCapabilities(instance);

      console.log(`🔗 MCP client connected to ${instance.name}`);
      
    } catch (error) {
      console.warn(`⚠️ Could not set up MCP client for ${instance.name}:`, error);
      // Don't fail the server start just because MCP client setup failed
    }
  }

  private async loadServerCapabilities(instance: MCPServerInstance): Promise<void> {
    if (!instance.client) return;

    try {
      // List available tools
      const toolsResult = await instance.client.listTools();
      instance.tools = toolsResult.tools?.map((tool: any) => tool.name) || [];
      
      console.log(`📋 Server ${instance.name} provides ${instance.tools?.length || 0} tools:`, 
                  instance.tools?.join(', '));
      
    } catch (error) {
      console.warn(`⚠️ Could not load capabilities for ${instance.name}:`, error);
    }
  }

  private shouldAutoRestart(instance: MCPServerInstance, exitCode: number | null): boolean {
    // Don't restart if explicitly disabled
    if (instance.config.disabled) return false;
    
    // Don't restart if clean exit (code 0)
    if (exitCode === 0) return false;
    
    // Check environment variable
    return process.env.ENABLE_AUTO_RESTART === 'true';
  }

  private async handleConfigChange({ oldConfig, newConfig }: any): Promise<void> {
    console.log('🔄 MCP configuration changed, updating servers...');
    
    const oldServers = oldConfig?.mcpServers || {};
    const newServers = newConfig?.mcpServers || {};
    
    // Stop removed servers
    for (const serverName of Object.keys(oldServers)) {
      if (!newServers[serverName]) {
        console.log(`🗑️ Removing server: ${serverName}`);
        await this.stopServer(serverName);
      }
    }
    
    // Update existing servers or start new ones
    for (const [serverName, serverConfig] of Object.entries(newServers)) {
      const oldServerConfig = oldServers[serverName];
      const typedConfig = serverConfig as MCPServerConfig;
      
      if (typedConfig.disabled) {
        // Stop if now disabled
        if (this.servers.has(serverName)) {
          console.log(`⏸️ Disabling server: ${serverName}`);
          await this.stopServer(serverName);
        }
        continue;
      }
      
      // Check if server configuration changed
      const configChanged = !oldServerConfig || 
        JSON.stringify(oldServerConfig) !== JSON.stringify(typedConfig);
        
      if (configChanged) {
        if (this.servers.has(serverName)) {
          console.log(`🔄 Restarting server due to config change: ${serverName}`);
          await this.restartServer(serverName);
        } else {
          console.log(`➕ Starting new server: ${serverName}`);
          await this.startServer(serverName, typedConfig);
        }
      }
    }
  }

  async stopServer(serverName: string): Promise<void> {
    const instance = this.servers.get(serverName);
    if (!instance) {
      return;
    }

    console.log(`🛑 Stopping server: ${serverName}`);
    
    try {
      // Close MCP client if available
      if (instance.client) {
        try {
          await instance.client.close();
        } catch (error) {
          console.warn(`⚠️ Error closing MCP client for ${serverName}:`, error);
        }
      }

      // Terminate the process
      if (instance.process && !instance.process.killed) {
        instance.process.kill('SIGTERM');
        
        // Force kill after 5 seconds if still running
        setTimeout(() => {
          if (instance.process && !instance.process.killed) {
            console.log(`🔪 Force killing server ${serverName}`);
            instance.process.kill('SIGKILL');
          }
        }, 5000);
      }

      instance.status = 'stopped';
      this.emit('serverStopped', serverName);
      
    } catch (error) {
      console.error(`❌ Error stopping server ${serverName}:`, error);
    }
  }

  async restartServer(serverName: string): Promise<void> {
    const config = this.configManager.getServerConfig(serverName);
    if (!config) {
      throw new Error(`Server ${serverName} not found in configuration`);
    }

    await this.stopServer(serverName);
    
    // Wait for clean shutdown
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    await this.startServer(serverName, config);
  }

  // Public API methods
  getServer(serverName: string): MCPServerInstance | undefined {
    return this.servers.get(serverName);
  }

  getAllServers(): MCPServerInstance[] {
    return Array.from(this.servers.values());
  }

  getRunningServers(): MCPServerInstance[] {
    return this.getAllServers().filter(s => s.status === 'running');
  }

  async callTool(
    serverName: string, 
    toolName: string, 
    args: any
  ): Promise<any> {
    const instance = this.servers.get(serverName);
    
    if (!instance) {
      throw new Error(`Server ${serverName} not found`);
    }
    
    if (instance.status !== 'running') {
      throw new Error(`Server ${serverName} is not running (status: ${instance.status})`);
    }
    
    if (!instance.client) {
      throw new Error(`Server ${serverName} does not have MCP client (SDK not available)`);
    }
    
    try {
      const result = await instance.client.callTool({
        name: toolName,
        arguments: args
      });
      
      return result;
    } catch (error) {
      console.error(`❌ Error calling tool ${toolName} on ${serverName}:`, error);
      throw error;
    }
  }

  getServerStatus(): Record<string, any> {
    const status: Record<string, any> = {};
    
    for (const [name, instance] of this.servers) {
      status[name] = {
        status: instance.status,
        pid: instance.pid,
        uptime: instance.startTime ? Date.now() - instance.startTime.getTime() : 0,
        tools: instance.tools || [],
        error: instance.error
      };
    }
    
    return status;
  }

  async shutdown(): Promise<void> {
    console.log('🛑 Shutting down MCP Server Manager...');
    this.shutdownInProgress = true;
    
    const stopPromises = Array.from(this.servers.keys()).map(name => 
      this.stopServer(name)
    );
    
    await Promise.all(stopPromises);
    
    this.servers.clear();
    this.removeAllListeners();
    
    console.log('✅ MCP Server Manager shut down');
  }
}
