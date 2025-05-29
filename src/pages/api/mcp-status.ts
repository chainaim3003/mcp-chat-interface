// src/pages/api/mcp-status.ts
// API route for MCP system status

import { NextApiRequest, NextApiResponse } from 'next';
import { getMCPStatus, initializeMCP, callMCPTool } from '../../lib/mcp-integration';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  try {
    if (req.method === 'GET') {
      // Get MCP status
      const status = getMCPStatus();
      
      res.status(200).json({
        success: true,
        data: status
      });
      
    } else if (req.method === 'POST') {
      // Initialize MCP or call tool
      const { action, serverName, toolName, args } = req.body;
      
      if (action === 'initialize') {
        await initializeMCP();
        res.status(200).json({
          success: true,
          message: 'MCP system initialized'
        });
      } else if (action === 'callTool' && serverName && toolName) {
        const result = await callMCPTool(serverName, toolName, args);
        res.status(200).json({
          success: true,
          data: result
        });
      } else {
        res.status(400).json({
          success: false,
          error: 'Invalid action or missing parameters'
        });
      }
      
    } else {
      res.setHeader('Allow', ['GET', 'POST']);
      res.status(405).json({
        success: false,
        error: 'Method not allowed'
      });
    }
    
  } catch (error) {
    console.error('MCP API error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
