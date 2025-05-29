'use client';

import { useState, useEffect } from 'react';
import ChatInterface from '../components/chat-interface';
import { MCPConfig } from '../types/mcp';
import { ConfigManager } from '../lib/config-manager';

export default function Home() {
  const [config, setConfig] = useState<MCPConfig | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadConfiguration();
  }, []);

  const loadConfiguration = () => {
    const savedConfig = ConfigManager.loadConfig();
    const finalConfig = savedConfig || ConfigManager.getDefaultConfig();
    setConfig(finalConfig);
    setIsLoading(false);
  };

  const saveConfiguration = (newConfig: MCPConfig) => {
    setConfig(newConfig);
    ConfigManager.saveConfig(newConfig);
  };

  if (isLoading) {
    return (
      <div className="h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Initializing MCP Chat Interface...</p>
        </div>
      </div>
    );
  }

  if (showConfig) {
    return (
      <div className="p-8 max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">MCP Configuration</h1>
        <div className="bg-white rounded-lg shadow-lg p-6">
          <textarea
            value={JSON.stringify(config, null, 2)}
            onChange={(e) => {
              try {
                const newConfig = JSON.parse(e.target.value);
                setConfig(newConfig);
              } catch (err) {
                console.error('Invalid JSON:', err);
              }
            }}
            className="w-full h-96 p-4 border border-gray-300 rounded-lg font-mono text-sm"
            placeholder="Enter your MCP configuration..."
          />
          <div className="mt-6 flex justify-between">
            <button
              onClick={() => setConfig(ConfigManager.getDefaultConfig())}
              className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
            >
              Reset to Default
            </button>
            <div className="space-x-2">
              <button
                onClick={() => setShowConfig(false)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Start Chat
              </button>
              <button
                onClick={() => saveConfiguration(config!)}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Save Config
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen relative">
      <ChatInterface config={config} />
      <button
        onClick={() => setShowConfig(true)}
        className="fixed bottom-4 right-4 p-3 bg-gray-800 text-white rounded-full hover:bg-gray-700 shadow-lg transition-all hover:scale-105"
        title="Configure MCP Servers"
      >
        ⚙️
      </button>
    </div>
  );
}
