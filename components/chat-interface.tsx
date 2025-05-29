'use client';

import { useState, useEffect, useRef } from 'react';
import { Send, Bot, User, Settings, Zap, CheckCircle, AlertCircle, Clock } from 'lucide-react';
import { ChatMessage, MCPTool, ToolCall, MCPConfig } from '../types/mcp';
import { MCPOrchestrator } from '../lib/orchestrator';

interface ChatInterfaceProps {
  config?: MCPConfig | null;
}

export default function ChatInterface({ config }: ChatInterfaceProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [orchestrator, setOrchestrator] = useState<MCPOrchestrator | null>(null);
  const [availableTools, setAvailableTools] = useState<MCPTool[]>([]);
  const [showTools, setShowTools] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (config) {
      initializeOrchestrator();
    }
  }, [config]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const initializeOrchestrator = async () => {
    if (!config) return;
    
    try {
      const orch = new MCPOrchestrator(config);
      await orch.initialize();
      setOrchestrator(orch);
      setAvailableTools(orch.getAvailableTools());
      
      const welcomeMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `🚀 **Welcome to MCP Chat Interface!**\n\nI'm connected to **${Object.keys(config.mcpServers || {}).length} MCP servers** with **${orch.getAvailableTools().length} available tools**.\n\n**Try these commands:**\n- "Check GLEIF compliance for Acme Corp"\n- "Mint NFT for TechStart"\n- "Run compliance workflow"\n\nWhat would you like me to help you with?`,
        timestamp: new Date()
      };
      
      setMessages([welcomeMessage]);
    } catch (error) {
      console.error('Failed to initialize orchestrator:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !orchestrator || isLoading) return;

    const userMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setIsLoading(true);

    try {
      const response = await orchestrator.processMessage(currentInput);
      setMessages(prev => [...prev, response]);
    } catch (error) {
      const errorMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-600" />;
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-600 animate-spin" />;
      default:
        return <Clock className="w-4 h-4 text-gray-400" />;
    }
  };

  const renderToolCall = (toolCall: ToolCall) => (
    <div key={toolCall.id} className="mt-3 p-4 bg-blue-50 rounded-lg border border-blue-200">
      <div className="flex items-center gap-3 mb-2">
        <Zap className="w-4 h-4 text-blue-600" />
        <span className="font-medium text-blue-900">{toolCall.toolName}</span>
        <span className="text-sm text-blue-600">{toolCall.serverName}</span>
        {getStatusIcon(toolCall.status)}
      </div>
      
      {toolCall.result && (
        <div className="mt-2 p-2 bg-white rounded text-sm">
          <pre className="whitespace-pre-wrap">{JSON.stringify(toolCall.result, null, 2)}</pre>
        </div>
      )}
    </div>
  );

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`${showTools ? 'w-80' : 'w-16'} transition-all duration-300 bg-white border-r border-gray-200 flex flex-col`}>
        <div className="p-4 border-b border-gray-200">
          <button
            onClick={() => setShowTools(!showTools)}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <Settings className="w-5 h-5" />
          </button>
        </div>
        
        {showTools && (
          <div className="flex-1 overflow-y-auto p-4">
            <h3 className="font-semibold mb-4">Available Tools ({availableTools.length})</h3>
            <div className="space-y-2">
              {availableTools.map((tool, index) => (
                <div key={index} className="p-3 bg-gray-50 rounded-lg">
                  <div className="font-medium text-sm">{tool.name}</div>
                  <div className="text-xs text-gray-500 mb-1">{tool.server}</div>
                  <div className="text-xs text-gray-600">{tool.description}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Main Chat */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 p-4">
          <h1 className="text-xl font-semibold">MCP Chat Interface</h1>
          <p className="text-sm text-gray-600">Natural language interface for MCP servers</p>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((message) => (
            <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-3xl ${
                message.role === 'user' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-white border border-gray-200'
              } rounded-lg p-4`}>
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                    message.role === 'user' ? 'bg-blue-500' : 'bg-gray-100'
                  }`}>
                    {message.role === 'user' ? <User className="w-4 h-4" /> : <Bot className="w-4 h-4" />}
                  </div>
                  <div className="flex-1">
                    <div className="whitespace-pre-wrap">{message.content}</div>
                    
                    {message.toolCalls && message.toolCalls.length > 0 && (
                      <div className="mt-3">
                        <div className="text-sm font-medium mb-2">Tool Executions:</div>
                        {message.toolCalls.map(renderToolCall)}
                      </div>
                    )}
                    
                    <div className={`text-xs mt-2 ${
                      message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
                    }`}>
                      {message.timestamp.toLocaleTimeString()}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
          
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <div className="flex items-center gap-3">
                  <Bot className="w-6 h-6 text-gray-400" />
                  <div className="flex space-x-1">
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                  </div>
                </div>
              </div>
            </div>
          )}
          
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="bg-white border-t border-gray-200 p-4">
          <form onSubmit={handleSubmit} className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask me to check GLEIF compliance, mint NFTs, or run workflows..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Send className="w-5 h-5" />
            </button>
          </form>
          
          <div className="mt-2 text-xs text-gray-500">
            Try: "Check GLEIF compliance for Acme Corp" or "Mint NFT for TechStart"
          </div>
        </div>
      </div>
    </div>
  );
}
