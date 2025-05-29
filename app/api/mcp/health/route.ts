import { NextRequest, NextResponse } from 'next/server';
import { readMCPConfig } from '@/lib/mcp-config';
import { DynamicMCPClient } from '@/lib/mcp-client';
import fs from 'fs';
import path from 'path';

export async function GET(req: NextRequest) {
  try {
    const configPath = path.join(process.cwd(), 'claude_mcp_config.json');
    
    if (!fs.existsSync(configPath)) {
      return NextResponse.json({
        status: 'error',
        error: 'claude_mcp_config.json not found',
        configPath,
        servers: [],
        totalServers: 0,
        totalTools: 0
      }, { status: 404 });
    }

    const config = readMCPConfig();
    const serverNames = Object.keys(config.mcpServers);
    const stats = fs.statSync(configPath);
    
    const client = new DynamicMCPClient();
    let tools = [];
    let serverStatus = [];
    
    try {
      tools = await client.initialize();
      serverStatus = client.getServerStatus();
    } catch (error) {
      console.error('MCP client initialization failed:', error);
    } finally {
      await client.disconnect();
    }

    const detailedServers = serverNames.map(serverName => {
      const serverConfig = config.mcpServers[serverName];
      const status = serverStatus.find(s => s.name === serverName);
      const serverTools = tools.filter(tool => tool._serverName === serverName);
      
      return {
        name: serverName,
        command: serverConfig.command,
        args: serverConfig.args,
        status: status?.connected ? 'connected' : 'failed',
        toolCount: serverTools.length,
        tools: serverTools.map(t => ({
          name: t.name,
          description: t.description
        })),
        lastError: status?.lastError
      };
    });

    const connectedServers = detailedServers.filter(s => s.status === 'connected');

    return NextResponse.json({
      status: connectedServers.length > 0 ? 'healthy' : 'unhealthy',
      configFile: 'claude_mcp_config.json',
      configPath,
      configLastModified: stats.mtime.toISOString(),
      totalServers: serverNames.length,
      connectedServers: connectedServers.length,
      totalTools: tools.length,
      servers: detailedServers,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    return NextResponse.json({
      status: 'error',
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const client = new DynamicMCPClient();
    const tools = await client.initialize();
    
    return NextResponse.json({
      status: 'reinitialized',
      totalTools: tools.length,
      serverStatus: client.getServerStatus(),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    return NextResponse.json({
      status: 'error',
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}