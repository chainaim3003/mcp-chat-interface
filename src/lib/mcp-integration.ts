// src/lib/mcp-integration.ts
// Drop-in integration that works with existing code

import { mcpConfig, MCPConfigManager } from './mcp-config-loader';
import { MCPServerManager } from './mcp-server-manager';

// Global instances - initialized lazily
let serverManager: MCPServerManager | null = null;
let initialized = false;

/**
 * Initialize MCP system - call this once on app startup
 */
export async function initializeMCP(): Promise<void> {
  if (initialized) return;
  
  try {
    console.log('🔄 Initializing MCP system...');
    
    // Initialize config manager
    await mcpConfig.initialize();
    
    // Initialize server manager
    serverManager = new MCPServerManager(mcpConfig);
    await serverManager.initialize();
    
    initialized = true;
    console.log('✅ MCP system ready');
    
  } catch (error) {
    console.error('❌ Failed to initialize MCP system:', error);
    throw error;
  }
}

/**
 * Get MCP server status - safe to call anytime
 */
export function getMCPStatus() {
  if (!initialized || !serverManager) {
    return {
      initialized: false,
      servers: {},
      error: 'MCP system not initialized'
    };
  }
  
  return {
    initialized: true,
    servers: serverManager.getServerStatus(),
    config: mcpConfig.getConfig()
  };
}

/**
 * Call an MCP tool - handles errors gracefully
 */
export async function callMCPTool(
  serverName: string,
  toolName: string, 
  args: any = {}
): Promise<any> {
  if (!initialized || !serverManager) {
    throw new Error('MCP system not initialized. Call initializeMCP() first.');
  }
  
  try {
    return await serverManager.callTool(serverName, toolName, args);
  } catch (error) {
    console.error(`Failed to call ${serverName}.${toolName}:`, error);
    throw error;
  }
}

/**
 * Get available MCP servers
 */
export function getMCPServers(): Record<string, any> {
  if (!initialized) return {};
  
  return mcpConfig.getEnabledServers();
}

/**
 * Check if a specific server is available
 */
export function isServerAvailable(serverName: string): boolean {
  if (!initialized || !serverManager) return false;
  
  const server = serverManager.getServer(serverName);
  return server?.status === 'running';
}

/**
 * Add a new MCP server dynamically
 */
export async function addMCPServer(
  name: string,
  config: {
    command: string;
    args?: string[];
    env?: Record<string, string>;
  }
): Promise<void> {
  if (!initialized) {
    throw new Error('MCP system not initialized');
  }
  
  await mcpConfig.updateServerConfig(name, config);
}

/**
 * Shutdown MCP system gracefully
 */
export async function shutdownMCP(): Promise<void> {
  if (serverManager) {
    await serverManager.shutdown();
  }
  
  if (mcpConfig) {
    mcpConfig.destroy();
  }
  
  initialized = false;
  serverManager = null;
}

// Export for convenience
export { mcpConfig, serverManager };

// Simple status interface (no React dependencies)
export interface MCPStatus {
  initialized: boolean;
  servers: Record<string, any>;
  config?: any;
  error?: string;
}

/**
 * Get current MCP system status
 */
export function getCurrentStatus(): MCPStatus {
  return getMCPStatus();
}

/**
 * Check if MCP system is ready
 */
export function isReady(): boolean {
  return initialized && serverManager !== null;
}
