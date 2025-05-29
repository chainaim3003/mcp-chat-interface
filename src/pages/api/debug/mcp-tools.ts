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
    
    // Debug information with proper typing
    const debugInfo: any = {
      timestamp: new Date().toISOString(),
      mcpInitialized: status.initialized,
      configLoaded: !!config,
      totalServersConfigured: config ? Object.keys(config.mcpServers).length : 0,
      enabledServersConfigured: config ? Object.keys(mcpConfig.getEnabledServers()).length : 0,
      runningServers: status.servers ? Object.keys(status.servers).length : 0,
      serverDetails: {} as any,
      toolSummary: {
        totalTools: 0,
        toolsByServer: {} as any
      },
      configComparison: {
        configuredServers: [] as string[],
        runningServers: [] as string[],
        missingServers: [] as string[],
        extraServers: [] as string[]
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
    if (config && status.servers) {
      const configuredServers = Object.keys(config.mcpServers);
      const runningServers = Object.keys(status.servers);
      
      debugInfo.configComparison.configuredServers = configuredServers;
      debugInfo.configComparison.runningServers = runningServers;
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
