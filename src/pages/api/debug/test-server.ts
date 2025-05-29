// src/pages/api/debug/test-server.ts
// Test individual MCP server tools

import { NextApiRequest, NextApiResponse } from 'next';
import { initializeMCP, callMCPTool, getMCPStatus } from '../../../lib/mcp-integration';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { serverName, toolName, args = {} } = req.body;

    if (!serverName || !toolName) {
      return res.status(400).json({ 
        error: 'serverName and toolName are required' 
      });
    }

    console.log(`🔧 Testing ${serverName}.${toolName} with args:`, args);

    // Initialize MCP
    await initializeMCP();
    
    // Get server status
    const status = getMCPStatus();
    const serverInfo = status.servers?.[serverName];
    
    if (!serverInfo) {
      return res.status(404).json({
        error: `Server ${serverName} not found`,
        availableServers: Object.keys(status.servers || {})
      });
    }

    if (serverInfo.status !== 'running') {
      return res.status(400).json({
        error: `Server ${serverName} is not running (status: ${serverInfo.status})`,
        serverInfo
      });
    }

    const availableTools = serverInfo.tools || [];
    if (!availableTools.includes(toolName)) {
      return res.status(400).json({
        error: `Tool ${toolName} not available on server ${serverName}`,
        availableTools
      });
    }

    // Call the tool
    const startTime = Date.now();
    const result = await callMCPTool(serverName, toolName, args);
    const executionTime = Date.now() - startTime;

    res.status(200).json({
      success: true,
      result,
      executionTime,
      serverInfo: {
        name: serverName,
        status: serverInfo.status,
        tools: availableTools
      }
    });

  } catch (error) {
    console.error('❌ Tool test error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
