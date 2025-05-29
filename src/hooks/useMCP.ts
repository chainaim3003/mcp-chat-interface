// src/hooks/useMCP.ts
// Optional React hook for MCP integration
// Only use this file if you have React in your project

'use client';

import { useState, useEffect, useCallback } from 'react';
import { 
  getMCPStatus, 
  callMCPTool, 
  getMCPServers, 
  isServerAvailable 
} from '../lib/mcp-integration';

export function useMCP() {
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    const updateStatus = () => {
      setStatus(getMCPStatus());
    };
    
    // Initial status
    updateStatus();
    
    // Set up polling for status updates (since we can't easily listen to events)
    const interval = setInterval(updateStatus, 5000);
    
    return () => {
      clearInterval(interval);
    };
  }, []);
  
  const callTool = useCallback(async (
    serverName: string,
    toolName: string,
    args?: any
  ) => {
    setLoading(true);
    try {
      const result = await callMCPTool(serverName, toolName, args);
      return result;
    } finally {
      setLoading(false);
    }
  }, []);
  
  return {
    status,
    loading,
    callTool,
    servers: getMCPServers(),
    isServerAvailable
  };
}
