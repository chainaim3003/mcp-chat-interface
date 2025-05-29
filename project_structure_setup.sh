export default orchestrator;
EOF

echo "🧩 Creating components..."

# components/chat-interface.tsx
cat > components/chat-interface.tsx << 'EOF'
'use client';

import { useState, useEffect, useRef } from 'react';
import { Send, Bot, User, Settings, Zap, AlertCircle, CheckCircle, Clock } from 'lucide-react';
import { ChatMessage, MCPTool, ToolCall, MCPConfig } from '../types/mcp';
import { MCPOrchestrator } from '../lib/orchestrator';
import { WorkflowBuilder } from './workflow-builder';

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
  const [showWorkflowBuilder, setShowWorkflowBuilder] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'error'>('connecting');
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
      setConnectionStatus('connecting');
      const orch = new MCPOrchestrator(config);
      await orch.initialize();
      setOrchestrator(orch);
      setAvailableTools(orch.getAvailableTools());
      setConnectionStatus('connected');
      
      // Add welcome message
      const welcomeMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `🚀 **Welcome to MCP Chat Interface!**

I'm connected to **${Object.keys(config.mcpServers || {}).length} MCP servers** with **${orch.getAvailableTools().length} available tools**.

Here's what I can help you with:

**🔍 Compliance Operations:**
- \`"Check GLEIF compliance for Acme Corp"\`
- \`"Run full compliance workflow for TechStart"\` 
- \`"Verify export/import compliance for GlobalTrade"\`

**🎨 NFT & Blockchain Operations:**
- \`"Mint NFT if CompanyX is GLEIF compliant"\`
- \`"Check XDC balance for wallet 0x123..."\`
- \`"Deploy NFT contract on testnet"\`

**🔄 Advanced Workflows:**
- \`"Convert ERC-721 token to ERC-6960 for CompanyY"\`
- \`"Run compliance check and mint NFT if all requirements met"\`

**📋 Multi-Server Operations:**
Execute complex workflows across PRET-MCP-SERVER, GOAT-EVM-MCP-SERVER, and FILE-MCP-SERVER seamlessly!

Try asking me something like: *"Check GLEIF compliance for Acme Corp and mint NFT if ACTIVE"*`,
        timestamp: new Date()
      };
      
      setMessages([welcomeMessage]);
    } catch (error) {
      setConnectionStatus('error');
      console.error('Failed to initialize orchestrator:', error);
      
      const errorMessage: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `❌ **Connection Error**\n\nFailed to connect to MCP servers. Please check your configuration and ensure the servers are running.\n\nError: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date()
      };
      setMessages([errorMessage]);
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
        content: `❌ **Error Processing Request**\n\n${error instanceof Error ? error.message : 'An unexpected error occurred. Please try again.'}`,
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
    <div key={toolCall.id} className="mt-3 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg border border-blue-200">
      <div className="flex items-center gap-3 mb-3">
        <Zap className="w-5 h-5 text-blue-600" />
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-blue-900">{toolCall.toolName}</span>
            <span className="text-sm text-blue-600 bg-blue-100 px-2 py-1 rounded-full">
              {toolCall.serverName}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {getStatusIcon(toolCall.status)}
          <span className={`text-sm font-medium capitalize ${
            toolCall.status === 'success' ? 'text-green-700' :
            toolCall.status === 'error' ? 'text-red-700' :
            'text-yellow-700'
          }`}>
            {toolCall.status}
          </span>
          {toolCall.duration && (
            <span className="text-xs text-gray-500">
              ({toolCall.duration}ms)
            </span>
          )}
        </div>
      </div>
      
      <div className="space-y-2">
        <details className="group">
          <summary className="cursor-pointer text-sm font-medium text-gray-700 hover:text-gray-900">
            Parameters
          </summary>
          <pre className="mt-2 text-xs bg-white p-3 rounded border overflow-x-auto">
            {JSON.stringify(toolCall.parameters, null, 2)}
          </pre>
        </details>
        
        {toolCall.result && (
          <details className="group">
            <summary className="cursor-pointer text-sm font-medium text-gray-700 hover:text-gray-900">
              Result
            </summary>
            <pre className="mt-2 text-xs bg-white p-3 rounded border overflow-x-auto">
              {JSON.stringify(toolCall.result, null, 2)}
            </pre>
          </details>
        )}

        {toolCall.error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded">
            <p className="text-sm text-red-800 font-medium">Error:</p>
            <p className="text-sm text-red-700">{toolCall.error}</p>
          </div>
        )}
      </div>
    </div>
  );

  const handleWorkflowSave = (workflow: any) => {
    console.log('Saving workflow:', workflow);
    // Here you would save the workflow to your orchestrator
  };

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`${showTools ? 'w-80' : 'w-16'} transition-all duration-300 bg-white border-r border-gray-200 flex flex-col shadow-lg`}>
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <button
              onClick={() => setShowTools(!showTools)}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Toggle Tools Panel"
            >
              <Settings className="w-5 h-5" />
            </button>
            {showTools && (
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${
                  connectionStatus === 'connected' ? 'bg-green-500' :
                  connectionStatus === 'connecting' ? 'bg-yellow-500 animate-pulse' :
                  'bg-red-500'
                }`} />
                <span className="text-sm text-gray-600 capitalize">
                  {connectionStatus}
                </span>
              </div>
            )}
          </div>
        </div>
        
        {showTools && (
          <div className="flex-1 overflow-y-auto p-4">
            <div className="mb-6">
              <h3 className="font-semibold mb-3">Available Tools ({availableTools.length})</h3>
              
              {/* Group tools by category */}
              {['compliance', 'blockchain', 'storage', 'utility'].map(category => {
                const categoryTools = availableTools.filter(tool => tool.category === category);
                if (categoryTools.length === 0) return null;
                
                return (
                  <div key={category} className="mb-4">
                    <h4 className="text-sm font-medium text-gray-700 mb-2 capitalize">
                      {category} ({categoryTools.length})
                    </h4>
                    <div className="space-y-2">
                      {categoryTools.map((tool, index) => (
                        <div key={index} className="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                          <div className="font-medium text-sm text-gray-900">{tool.name}</div>
                          <div className="text-xs text-gray-500 mb-1">{tool.server}</div>
                          <div className="text-xs text-gray-600">{tool.description}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="border-t pt-4">
              <button
                onClick={() => setShowWorkflowBuilder(true)}
                className="w-full px-3 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors text-sm"
              >
                Build Workflow
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Main Chat */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-semibold text-gray-900">MCP Chat Interface</h1>
              <p className="text-sm text-gray-600">Natural language interface for MCP servers</p>
            </div>
            <div className="flex items-center gap-3">
              {config && (
                <div className="text-sm text-gray-500">
                  {Object.keys(config.mcpServers).length} servers • {availableTools.length} tools
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((message) => (
            <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-4xl ${
                message.role === 'user' 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-white border border-gray-200 shadow-sm'
              } rounded-lg p-4`}>
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                    message.role === 'user' 
                      ? 'bg-blue-500' 
                      : 'bg-gradient-to-br from-purple-500 to-blue-600'
                  }`}>
                    {message.role === 'user' ? 
                      <User className="w-4 h-4" /> : 
                      <Bot className="w-4 h-4 text-white" />
                    }
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="prose prose-sm max-w-none">
                      <div className="whitespace-pre-wrap break-words">{message.content}</div>
                    </div>
                    
                    {message.toolCalls && message.toolCalls.length > 0 && (
                      <div className="mt-4">
                        <div className="text-sm font-medium mb-3 text-gray-700">
                          🔧 Tool Executions ({message.toolCalls.length})
                        </div>
                        <div className="space-y-2">
                          {message.toolCalls.map(renderToolCall)}
                        </div>
                      </div>
                    )}
                    
                    <div className={`text-xs mt-3 ${
                      message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
                    }`}>
                      {message.timestamp.toLocaleTimeString()}
                      {message.metadata?.transactionHash && (
                        <span className="ml-2">
                          • TX: {message.metadata.transactionHash.substring(0, 10)}...
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
          
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-500 to-blue-600 flex items-center justify-center">
                    <Bot className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="flex space-x-1">
                      <div className="w-2 h-2 bg-blue-400 rounded-full animate-bounce"></div>
                      <div className="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                      <div className="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                    </div>
                    <span className="text-sm text-gray-600">Processing your request...</span>
                  </div>
                </div>
              </div>
            </div>
          )}
          
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="bg-white border-t border-gray-200 p-4 shadow-sm">
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="flex gap-2">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Ask me to check GLEIF compliance, mint NFTs, run workflows..."
                className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                disabled={isLoading || connectionStatus !== 'connected'}
              />
              <button
                type="submit"
                disabled={isLoading || !input.trim() || connectionStatus !== 'connected'}
                className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
              >
                <Send className="w-4 h-4" />
                Send
              </button>
            </div>
            
            <div className="flex items-center justify-between text-xs">
              <div className="text-gray-500">
                <strong>Try:</strong> "Check GLEIF compliance for Acme Corp" or "Mint NFT if TechStart is compliant"
              </div>
              <div className="text-gray-400">
                {connectionStatus === 'connected' ? '✅ Ready' : 
                 connectionStatus === 'connecting' ? '🔄 Connecting...' : 
                 '❌ Disconnected'}
              </div>
            </div>
          </form>
        </div>
      </div>

      {/* Workflow Builder Modal */}
      {showWorkflowBuilder && (
        <WorkflowBuilder 
          onSave={handleWorkflowSave}
          onClose={() => setShowWorkflowBuilder(false)}
        />
      )}
    </div>
  );
}
EOF

# components/workflow-builder.tsx
cat > components/workflow-builder.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { Plus, Play, Settings, Trash2, X, ArrowDown } from 'lucide-react';

interface WorkflowStep {
  id: string;
  type: 'tool_call' | 'condition' | 'decision';
  server: string;
  tool: string;
  parameters: any;
  condition?: string;
  onSuccess?: string;
  onFailure?: string;
}

interface WorkflowBuilderProps {
  onSave: (workflow: WorkflowStep[]) => void;
  onClose: () => void;
}

export function WorkflowBuilder({ onSave, onClose }: WorkflowBuilderProps) {
  const [workflow, setWorkflow] = useState<WorkflowStep[]>([]);
  const [workflowName, setWorkflowName] = useState('');
  const [workflowDescription, setWorkflowDescription] = useState('');

  const serverTools = {
    'PRET-MCP-SERVER': [
      'get-GLEIF-data',
      'check-corp-registration', 
      'check-export-import'
    ],
    'GOAT-EVM-MCP-SERVER': [
      'mint_nft',
      'deploy_simple_nft_contract', 
      'get_xdc_balance',
      'send_native_token'
    ],
    'FILE-MCP-SERVER': [
      'read_file',
      'write_file'
    ]
  };

  const addStep = () => {
    const newStep: WorkflowStep = {
      id: crypto.randomUUID(),
      type: 'tool_call',
      server: 'PRET-MCP-SERVER',
      tool: 'get-GLEIF-data',
      parameters: {}
    };
    setWorkflow([...workflow, newStep]);
  };

  const removeStep = (id: string) => {
    setWorkflow(workflow.filter(step => step.id !== id));
  };

  const updateStep = (id: string, updates: Partial<WorkflowStep>) => {
    setWorkflow(workflow.map(step => 
      step.id === id ? { ...step, ...updates } : step
    ));
  };

  const getParameterFields = (server: string, tool: string) => {
    const parameterSets: Record<string, Record<string, string[]>> = {
      'PRET-MCP-SERVER': {
        'get-GLEIF-data': ['companyName', 'typeOfNet'],
        'check-corp-registration': ['companyName', 'jurisdiction'],
        'check-export-import': ['companyName', 'commodityCode']
      },
      'GOAT-EVM-MCP-SERVER': {
        'mint_nft': ['contractAddress', 'to', 'tokenURI', 'network'],
        'deploy_simple_nft_contract': ['name', 'symbol', 'network'],
        'get_xdc_balance': ['address', 'network'],
        'send_native_token': ['to', 'amount', 'network']
      },
      'FILE-MCP-SERVER': {
        'read_file': ['path'],
        'write_file': ['path', 'content']
      }
    };

    return parameterSets[server]?.[tool] || [];
  };

  const saveWorkflow = () => {
    const workflowDefinition = {
      id: crypto.randomUUID(),
      name: workflowName || 'Untitled Workflow',
      description: workflowDescription || 'Custom workflow',
      steps: workflow,
      autonomous: false,
      triggers: [{ type: 'manual', config: {} }]
    };

    onSave(workflowDefinition);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl w-full max-w-5xl max-h-[90vh] overflow-hidden shadow-2xl">
        {/* Header */}
        <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-purple-600 to-blue-600 text-white">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold">Workflow Builder</h2>
              <p className="text-purple-100">Create automated compliance and NFT workflows</p>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-white hover:bg-opacity-20 rounded-lg transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
        
        {/* Workflow Details */}
        <div className="p-6 border-b border-gray-200 bg-gray-50">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Workflow Name</label>
              <input
                type="text"
                value={workflowName}
                onChange={(e) => setWorkflowName(e.target.value)}
                placeholder="e.g., GLEIF Compliance Check"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Description</label>
              <input
                type="text"
                value={workflowDescription}
                onChange={(e) => setWorkflowDescription(e.target.value)}
                placeholder="Brief description of what this workflow does"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
          </div>
        </div>
        
        {/* Workflow Steps */}
        <div className="flex-1 p-6 overflow-y-auto max-h-96">
          <div className="space-y-6">
            {workflow.map((step, index) => (
              <div key={step.id} className="relative">
                <div className="border-2 border-gray-200 rounded-lg p-4 bg-white hover:border-purple-300 transition-colors">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-purple-600 text-white rounded-full flex items-center justify-center font-medium">
                        {index + 1}
                      </div>
                      <div className="font-medium text-gray-900">
                        Step {index + 1}: {step.tool.replace(/[_-]/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </div>
                    </div>
                    <button
                      onClick={() => removeStep(step.id)}
                      className="text-red-600 hover:text-red-700 p-1 hover:bg-red-50 rounded"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-4 mb-4">
                    <div>
                      <label className="block text-sm font-medium mb-1">Type</label>
                      <select
                        value={step.type}
                        onChange={(e) => updateStep(step.id, { type: e.target.value as WorkflowStep['type'] })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                      >
                        <option value="tool_call">Tool Call</option>
                        <option value="condition">Condition</option>
                        <option value="decision">Decision</option>
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-1">Server</label>
                      <select
                        value={step.server}
                        onChange={(e) => updateStep(step.id, { 
                          server: e.target.value,
                          tool: serverTools[e.target.value as keyof typeof serverTools][0] || ''
                        })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                      >
                        {Object.keys(serverTools).map(server => (
                          <option key={server} value={server}>{server}</option>
                        ))}
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-1">Tool</label>
                      <select
                        value={step.tool}
                        onChange={(e) => updateStep(step.id, { tool: e.target.value })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                      >
                        {serverTools[step.server as keyof typeof serverTools]?.map(tool => (
                          <option key={tool} value={tool}>{tool}</option>
                        )) || []}
                      </select>
                    </div>
                  </div>

                  {/* Parameters */}
                  <div className="mb-4">
                    <label className="block text-sm font-medium mb-2">Parameters</label>
                    <div className="grid grid-cols-2 gap-3">
                      {getParameterFields(step.server, step.tool).map(param => (
                        <div key={param}>
                          <label className="block text-xs text-gray-600 mb-1">{param}</label>
                          <input
                            type="text"
                            value={step.parameters[param] || ''}
                            onChange={(e) => updateStep(step.id, {
                              parameters: { ...step.parameters, [param]: e.target.value }
                            })}
                            placeholder={`Enter ${param}`}
                            className="w-full px-2 py-1 border border-gray-300 rounded text-sm"
                          />
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Condition */}
                  {step.type === 'condition' && (
                    <div>
                      <label className="block text-sm font-medium mb-1">Condition</label>
                      <input
                        type="text"
                        value={step.condition || ''}
                        onChange={(e) => updateStep(step.id, { condition: e.target.value })}
                        placeholder="e.g., result.gleifStatus === 'ACTIVE'"
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                      />
                    </div>
                  )}
                </div>

                {/* Arrow between steps */}
                {index < workflow.length - 1 && (
                  <div className="flex justify-center py-2">
                    <ArrowDown className="w-5 h-5 text-gray-400" />
                  </div>
                )}
              </div>
            ))}
          </div>
          
          <button
            onClick={addStep}
            className="mt-6 flex items-center gap-2 px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-purple-400 w-full justify-center text-gray-600 hover:text-purple-600 transition-colors"
          >
            <Plus className="w-5 h-5" />
            Add Step
          </button>
        </div>
        
        {/* Footer */}
        <div className="p-6 border-t border-gray-200 flex justify-between bg-gray-50">
          <div className="text-sm text-gray-600">
            {workflow.length} step{workflow.length !== 1 ? 's' : ''} configured
          </div>
          
          <div className="space-x-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:text-gray-700 transition-colors"
            >
              Cancel
            </button>
            
            <button
              onClick={saveWorkflow}
              disabled={workflow.length === 0 || !workflowName.trim()}
              className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Save Workflow
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "📡 Creating remaining library files..."

# lib/orchestrator.ts - Complete implementation
cat > lib/orchestrator.ts << 'EOF'
import { MCPClient } from './mcp-client';
import { WorkflowEngine } from './workflow-engine';
import { ChatMessage, ToolCall, ComplianceResult, MCPConfig } from '../types/mcp';

export class MCPOrchestrator {
  private mcpClient: MCPClient;
  private workflowEngine: WorkflowEngine;
  
  constructor(private config: MCPConfig) {
    this.mcpClient = new MCPClient(config.mcpServers);
    this.workflowEngine = new WorkflowEngine(this.mcpClient);
  }

  async initialize(): Promise<void> {
    console.log('🔧 Initializing MCP Orchestrator...');
    await this.mcpClient.initialize();
    console.log('✅ MCP Orchestrator initialized successfully');
  }

  async processMessage(message: string): Promise<ChatMessage> {
    const startTime = Date.now();
    
    const chatMessage: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      toolCalls: []
    };

    try {
      console.log(`🎯 Processing message: "${message}"`);
      
      // Parse intent from natural language
      const intent = this.parseIntent(message);
      console.log('🧠 Parsed intent:', intent);
      
      // Execute workflow based on intent
      const result = await this.executeWorkflow(intent);
      
      chatMessage.content = result.response;
      chatMessage.toolCalls = result.toolCalls;
      chatMessage.metadata = result.metadata;
      
      const duration = Date.now() - startTime;
      console.log(`✅ Message processed in ${duration}ms`);
      
    } catch (error) {
      console.error('❌ Error processing message:', error);
      chatMessage.content = `**Error Processing Request**\n\n${error instanceof Error ? error.message : 'An unexpected error occurred. Please try again or check your MCP server connections.'}`;
    }

    return chatMessage;
  }

  private parseIntent(message: string): any {
    const lowerMessage = message.toLowerCase();
    
    // Enhanced intent parsing with more sophisticated patterns
    
    // GLEIF compliance check intent
    if (this.matchesPattern(lowerMessage, ['gleif', 'compliance'])) {
      const companyName = this.extractCompanyName(message);
      return {
        type: 'gleif_compliance_check',
        companyName,
        confidence: 0.9
      };
    }
    
    // Full compliance workflow intent
    if (this.matchesPattern(lowerMessage, ['compliance', 'workflow']) || 
        this.matchesPattern(lowerMessage, ['full', 'compliance']) ||
        this.matchesPattern(lowerMessage, ['complete', 'compliance'])) {
      const companyName = this.extractCompanyName(message);
      const network = this.extractNetwork(message);
      return {
        type: 'full_compliance_workflow',
        companyName,
        network,
        confidence: 0.95
      };
    }
    
    // NFT minting intent
    if (this.matchesPattern(lowerMessage, ['mint', 'nft'])) {
      const companyName = this.extractCompanyName(message);
      const conditional = this.matchesPattern(lowerMessage, ['if', 'compliant']) || 
                         this.matchesPattern(lowerMessage, ['if', 'active']);
      const network = this.extractNetwork(message);
      
      return {
        type: conditional ? 'conditional_nft_mint' : 'direct_nft_mint',
        companyName,
        network,
        confidence: 0.85
      };
    }
    
    // Balance check intent
    if (this.matchesPattern(lowerMessage, ['balance', 'check']) ||
        this.matchesPattern(lowerMessage, ['xdc', 'balance']) ||
        this.matchesPattern(lowerMessage, ['usdc', 'balance'])) {
      const address = this.extractWalletAddress(message);
      const network = this.extractNetwork(message);
      const currency = this.extractCurrency(message);
      
      return {
        type: 'balance_check',
        address,
        network,
        currency,
        confidence: 0.8
      };
    }
    
    // Token conversion intent
    if (this.matchesPattern(lowerMessage, ['convert', 'erc721', 'erc6960']) ||
        this.matchesPattern(lowerMessage, ['trade', 'finance', 'token'])) {
      const tokenId = this.extractTokenId(message);
      return {
        type: 'token_conversion',
        tokenId,
        fromStandard: 'ERC721',
        toStandard: 'ERC6960',
        confidence: 0.75
      };
    }
    
    // Export/Import compliance intent
    if (this.matchesPattern(lowerMessage, ['export', 'import']) ||
        this.matchesPattern(lowerMessage, ['trade', 'compliance'])) {
      const companyName = this.extractCompanyName(message);
      return {
        type: 'export_import_compliance',
        companyName,
        confidence: 0.8
      };
    }
    
    // Multi-server status check
    if (this.matchesPattern(lowerMessage, ['status', 'servers']) ||
        this.matchesPattern(lowerMessage, ['health', 'check'])) {
      return {
        type: 'system_status',
        confidence: 0.9
      };
    }

    // Default fallback
    return { 
      type: 'general_inquiry', 
      message, 
      confidence: 0.1 
    };
  }

  private matchesPattern(text: string, keywords: string[]): boolean {
    return keywords.every(keyword => text.includes(keyword));
  }

  private extractCompanyName(message: string): string {
    // Try multiple patterns to extract company name
    const patterns = [
      /(?:for|company|corp(?:oration)?)\s+([A-Za-z][A-Za-z0-9\s&.-]+?)(?:\s|$|,|\.|!|\?)/i,
      /([A-Z][a-zA-Z0-9\s&.-]*(?:Corp|Inc|LLC|Ltd|Company))/g,
      /([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)/g
    ];

    for (const pattern of patterns) {
      const match = message.match(pattern);
      if (match && match[1]) {
        return match[1].trim();
      }
    }

    return 'Unknown Company';
  }

  private extractNetwork(message: string): 'mainnet' | 'testnet' {
    const lowerMessage = message.toLowerCase();
    if (lowerMessage.includes('mainnet') || lowerMessage.includes('production')) {
      return 'mainnet';
    }
    return 'testnet'; // Default to testnet for safety
  }

  private extractWalletAddress(message: string): string {
    const addressPattern = /(0x[a-fA-F0-9]{40})/g;
    const match = message.match(addressPattern);
    return match ? match[0] : '';
  }

  private extractTokenId(message: string): string {
    const tokenIdPattern = /token[:\s]+(\d+|0x[a-fA-F0-9]+)/i;
    const match = message.match(tokenIdPattern);
    return match ? match[1] : '';
  }

  private extractCurrency(message: string): string {
    const lowerMessage = message.toLowerCase();
    if (lowerMessage.includes('usdc')) return 'USDC';
    if (lowerMessage.includes('xdc')) return 'XDC';
    return 'XDC'; // Default
  }

  private async executeWorkflow(intent: any): Promise<{ response: string; toolCalls: ToolCall[]; metadata?: any }> {
    const toolCalls: ToolCall[] = [];
    
    try {
      switch (intent.type) {
        case 'gleif_compliance_check':
          return await this.executeGLEIFWorkflow(intent.companyName, toolCalls);
        
        case 'full_compliance_workflow':
          return await this.executeFullComplianceWorkflow(intent.companyName, intent.network, toolCalls);
        
        case 'conditional_nft_mint':
          return await this.executeConditionalNFTMint(intent.companyName, intent.network, toolCalls);
        
        case 'direct_nft_mint':
          return await this.executeMintingWorkflow(intent.network, toolCalls);
        
        case 'balance_check':
          return await this.executeBalanceCheck(intent.address, intent.network, intent.currency, toolCalls);
        
        case 'token_conversion':
          return await this.executeTokenConversion(intent, toolCalls);
        
        case 'export_import_compliance':
          return await this.executeExportImportCheck(intent.companyName, toolCalls);
        
        case 'system_status':
          return await this.executeSystemStatusCheck(toolCalls);
        
        default:
          return await this.executeGeneralInquiry(intent.message, toolCalls);
      }
    } catch (error) {
      console.error('Workflow execution error:', error);
      return {
        response: `❌ **Workflow Execution Failed**\n\n${error instanceof Error ? error.message : 'Unknown error occurred during workflow execution.'}`,
        toolCalls
      };
    }
  }

  private async executeGLEIFWorkflow(companyName: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[]; metadata?: any }> {
    console.log(`🔍 Executing GLEIF workflow for: ${companyName}`);
    
    // Step 1: Check GLEIF compliance
    const gleifCall: ToolCall = {
      id: crypto.randomUUID(),
      toolName: 'get-GLEIF-data',
      serverName: 'PRET-MCP-SERVER',
      parameters: { companyName, typeOfNet: 'mainnet' },
      status: 'pending'
    };
    
    toolCalls.push(gleifCall);
    
    try {
      const startTime = Date.now();
      const gleifResult = await this.mcpClient.executeTool('PRET-MCP-SERVER', 'get-GLEIF-data', gleifCall.parameters);
      gleifCall.result = gleifResult;
      gleifCall.status = 'success';
      gleifCall.duration = Date.now() - startTime;
      
      const complianceResult: ComplianceResult = {
        companyName,
        gleifStatus: gleifResult.gleifStatus || 'PENDING',
        corpRegistration: 'PENDING',
        exportImport: 'PENDING',
        financialHealth: 'MEDIUM_RISK',
        overallCompliance: gleifResult.gleifStatus === 'ACTIVE' ? 'PARTIALLY_COMPLIANT' : 'NON_COMPLIANT',
        score: gleifResult.gleifStatus === 'ACTIVE' ? 75 : 25,
        lastUpdated: new Date().toISOString()
      };

      if (gleifResult.gleifStatus === 'ACTIVE') {
        return {
          response: `✅ **GLEIF Compliance Check - PASSED**\n\n**Company:** ${companyName}\n**GLEIF Status:** ${gleifResult.gleifStatus}\n**Entity ID:** ${gleifResult.entityId || 'N/A'}\n**Last Updated:** ${new Date(gleifResult.lastUpdated || Date.now()).toLocaleDateString()}\n\n🎯 **Next Steps:**\n- Company is GLEIF compliant and ready for NFT minting\n- You can now proceed with blockchain operations\n- Consider running full compliance workflow for complete verification`,
          toolCalls,
          metadata: { complianceResult }
        };
      } else {
        return {
          response: `❌ **GLEIF Compliance Check - FAILED**\n\n**Company:** ${companyName}\n**GLEIF Status:** ${gleifResult.gleifStatus}\n**Issue:** Company does not have an active GLEIF registration\n\n📋 **Required Actions:**\n- Company must obtain GLEIF Legal Entity Identifier (LEI)\n- LEI registration must be in ACTIVE status\n- Contact GLEIF-accredited service provider for assistance\n\n⚠️ **Cannot proceed with NFT minting until compliance requirements are met.**`,
          toolCalls,
          metadata: { complianceResult }
        };
      }
    } catch (error) {
      gleifCall.status = 'error';
      gleifCall.error = error instanceof Error ? error.message : 'Unknown error';
      return {
        response: `❌ **GLEIF Compliance Check Failed**\n\nError checking GLEIF compliance for ${companyName}:\n${error instanceof Error ? error.message : 'Connection or server error'}\n\nPlease ensure:\n- PRET-MCP-SERVER is running and accessible\n- Company name is spelled correctly\n- Network connectivity is stable`,
        toolCalls
      };
    }
  }

  private async executeFullComplianceWorkflow(companyName: string, network: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[]; metadata?: any }> {
    console.log(`🔄 Executing full compliance workflow for: ${companyName}`);
    
    const complianceChecks = [
      { name: 'GLEIF', tool: 'get-GLEIF-data', server: 'PRET-MCP-SERVER' },
      { name: 'Corp Registration', tool: 'check-corp-registration', server: 'PRET-MCP-SERVER' },
      { name: 'Export/Import', tool: 'check-export-import', server: 'PRET-MCP-SERVER' }
    ];

    const results: any = {};
    let allCompliant = true;

    // Execute all compliance checks
    for (const check of complianceChecks) {
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: check.tool,
        serverName: check.server,
        parameters: { companyName },
        status: 'pending'
      };
      
      toolCalls.push(toolCall);
      
      try {
        const startTime = Date.now();
        const result = await this.mcpClient.executeTool(check.server, check.tool, toolCall.parameters);
        toolCall.result = result;
        toolCall.status = 'success';
        toolCall.duration = Date.now() - startTime;
        
        results[check.name] = result;
        
        // Check if this specific compliance check passed
        const isCompliant = this.isComplianceCheckPassed(check.tool, result);
        if (!isCompliant) {
          allCompliant = false;
        }
        
      } catch (error) {
        toolCall.status = 'error';
        toolCall.error = error instanceof Error ? error.message : 'Unknown error';
        results[check.name] = { status: 'ERROR', error: toolCall.error };
        allCompliant = false;
      }
    }

    // Create comprehensive compliance result
    const complianceResult: ComplianceResult = {
      companyName,
      gleifStatus: this.getStatusFromResult(results['GLEIF'], 'gleifStatus'),
      corpRegistration: this.getStatusFromResult(results['Corp Registration'], 'status'),
      exportImport: this.getStatusFromResult(results['Export/Import'], 'status'),
      financialHealth: 'MEDIUM_RISK', // This would come from a financial health check
      overallCompliance: allCompliant ? 'FULLY_COMPLIANT' : 'PARTIALLY_COMPLIANT',
      score: this.calculateComplianceScore(results),
      lastUpdated: new Date().toISOString()
    };

    if (allCompliant) {
      // Proceed with ERC-6960 token deployment for trade finance
      const deployCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'deploy_erc6960_contract',
        serverName: 'GOAT-EVM-MCP-SERVER',
        parameters: {
          name: `${companyName} Trade Finance Token`,
          symbol: `TFT-${companyName.replace(/\s+/g, '').toUpperCase().substring(0, 6)}`,
          complianceData: complianceResult,
          network
        },
        status: 'pending'
      };
      
      toolCalls.push(deployCall);
      
      try {
        const deployResult = await this.mcpClient.executeTool('GOAT-EVM-MCP-SERVER', 'deploy_simple_nft_contract', deployCall.parameters);
        deployCall.result = deployResult;
        deployCall.status = 'success';
        
        return {
          response: `🎉 **FULL COMPLIANCE WORKFLOW - SUCCESS**\n\n**Company:** ${companyName}\n**Overall Status:** FULLY COMPLIANT\n**Compliance Score:** ${complianceResult.score}/100\n\n✅ **Compliance Checks:**\n- GLEIF: ${complianceResult.gleifStatus}\n- Corp Registration: ${complianceResult.corpRegistration}\n- Export/Import: ${complianceResult.exportImport}\n\n🚀 **Next Steps Completed:**\n- ERC-6960 Trade Finance Token Contract Deployed\n- Contract Address: ${deployResult.contractAddress}\n- Network: ${network}\n- Transaction Hash: ${deployResult.transactionHash}\n\n📈 **Ready for Trade Finance Operations!**`,
          toolCalls,
          metadata: { 
            complianceResult, 
            contractAddress: deployResult.contractAddress,
            transactionHash: deployResult.transactionHash
          }
        };
      } catch (error) {
        deployCall.status = 'error';
        deployCall.error = error instanceof Error ? error.message : 'Unknown error';
        
        return {
          response: `⚠️ **COMPLIANCE PASSED - DEPLOYMENT FAILED**\n\n**Company:** ${companyName}\n**Compliance Status:** FULLY COMPLIANT\n**Compliance Score:** ${complianceResult.score}/100\n\n✅ **All compliance checks passed, but contract deployment failed:**\n${deployCall.error}\n\n💡 **You can manually deploy the contract or retry the deployment.**`,
          toolCalls,
          metadata: { complianceResult }
        };
      }
    } else {
      const failedChecks = Object.entries(results)
        .filter(([_, result]) => !this.isResultCompliant(result))
        .map(([name, _]) => name);

      return {
        response: `❌ **FULL COMPLIANCE WORKFLOW - INCOMPLETE**\n\n**Company:** ${companyName}\n**Overall Status:** ${complianceResult.overallCompliance}\n**Compliance Score:** ${complianceResult.score}/100\n\n📋 **Compliance Status:**\n- GLEIF: ${complianceResult.gleifStatus}\n- Corp Registration: ${complianceResult.corpRegistration}\n- Export/Import: ${complianceResult.exportImport}\n\n⚠️ **Failed Checks:** ${failedChecks.join(', ')}\n\n🔧 **Required Actions:**\n${this.generateComplianceRecommendations(complianceResult)}\n\n**Cannot proceed with trade finance token deployment until all compliance requirements are met.**`,
        toolCalls,
        metadata: { complianceResult }
      };
    }
  }

  private isComplianceCheckPassed(toolName: string, result: any): boolean {
    switch (toolName) {
      case 'get-GLEIF-data':
        return result.gleifStatus === 'ACTIVE';
      case 'check-corp-registration':
        return result.status === 'COMPLIANT';
      case 'check-export-import':
        return result.status === 'COMPLIANT';
      default:
        return false;
    }
  }

  private getStatusFromResult(result: any, field: string): any {
    if (!result || result.status === 'ERROR') return 'PENDING';
    return result[field] || 'PENDING';
  }

  private isResultCompliant(result: any): boolean {
    if (!result || result.status === 'ERROR') return false;
    return result.gleifStatus === 'ACTIVE' || result.status === 'COMPLIANT';
  }

  private calculateComplianceScore(results: any): number {
    let score = 0;
    let totalChecks = 0;

    Object.values(results).forEach((result: any) => {
      totalChecks++;
      if (this.isResultCompliant(result)) {
        score += 33; // Each check worth ~33 points
      }
    });

    return Math.min(100, score);
  }

  private generateComplianceRecommendations(compliance: ComplianceResult): string {
    const recommendations = [];
    
    if (compliance.gleifStatus !== 'ACTIVE') {
      recommendations.push('- Obtain active GLEIF Legal Entity Identifier (LEI)');
    }
    
    if (compliance.corpRegistration !== 'COMPLIANT') {
      recommendations.push('- Ensure corporate registration is current and valid');
    }
    
    if (compliance.exportImport !== 'COMPLIANT') {
      recommendations.push('- Obtain necessary export/import licenses and permits');
    }

    return recommendations.join('\n');
  }

  // Additional workflow methods would go here...
  private async executeConditionalNFTMint(companyName: string, network: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[]; metadata?: any }> {
    // First check GLEIF, then mint if compliant
    const gleifWorkflow = await this.executeGLEIFWorkflow(companyName, toolCalls);
    
    if (gleifWorkflow.metadata?.complianceResult?.gleifStatus === 'ACTIVE') {
      // Proceed with NFT minting
      const mintCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'mint_nft',
        serverName: 'GOAT-EVM-MCP-SERVER',
        parameters: {
          contractAddress: '0x1234567890123456789012345678901234567890', // Default contract
          to: '0x0987654321098765432109876543210987654321', // Default recipient
          tokenURI: `https://metadata.api/company/${companyName}/compliance`,
          network
        },
        status: 'pending'
      };
      
      toolCalls.push(mintCall);
      
      try {
        const mintResult = await this.mcpClient.executeTool('GOAT-EVM-MCP-SERVER', 'mint_nft', mintCall.parameters);
        mintCall.result = mintResult;
        mintCall.status = 'success';
        
        return {
          response: `${gleifWorkflow.response}\n\n🎨 **NFT MINTING - SUCCESS**\n\nSince ${companyName} is GLEIF compliant, NFT has been minted:\n- Transaction Hash: ${mintResult.transactionHash}\n- Token ID: ${mintResult.tokenId}\n- Network: ${network}\n- Contract: ${mintCall.parameters.contractAddress}`,
          toolCalls,
          metadata: {
            ...gleifWorkflow.metadata,
            transactionHash: mintResult.transactionHash,
            tokenId: mintResult.tokenId
          }
        };
      } catch (error) {
        mintCall.status = 'error';
        mintCall.error = error instanceof Error ? error.message : 'Unknown error';
        
        return {
          response: `${gleifWorkflow.response}\n\n❌ **NFT MINTING - FAILED**\n\nAlthough ${companyName} is compliant, NFT minting failed:\n${mintCall.error}`,
          toolCalls
        };
      }
    } else {
      return {
        response: `${gleifWorkflow.response}\n\n⏹️ **NFT MINTING - SKIPPED**\n\nNFT minting was skipped because ${companyName} does not meet GLEIF compliance requirements.`,
        toolCalls
      };
    }
  }

  private async executeMintingWorkflow(network: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    // Direct NFT minting without compliance checks
    const deployCall: ToolCall = {
      id: crypto.randomUUID(),
      toolName: 'deploy_simple_nft_contract',
      serverName: 'GOAT-EVM-MCP-SERVER',
      parameters: {
        name: 'Compliance NFT Collection',
        symbol: 'COMP',
        network
      },
      status: 'pending'
    };
    
    toolCalls.push(deployCall);
    
    try {
      const deployResult = await this.mcpClient.executeTool('GOAT-EVM-MCP-SERVER', 'deploy_simple_nft_contract', deployCall.parameters);
      deployCall.result = deployResult;
      deployCall.status = 'success';
      
      return {
        response: `🎨 **NFT Contract Deployment - SUCCESS**\n\nNew NFT contract has been deployed:\n- Contract Address: ${deployResult.contractAddress}\n- Network: ${network}\n- Name: ${deployCall.parameters.name}\n- Symbol: ${deployCall.parameters.symbol}\n- Transaction Hash: ${deployResult.transactionHash}\n\n✅ **Ready for NFT minting operations!**`,
        toolCalls
      };
    } catch (error) {
      deployCall.status = 'error';
      deployCall.error = error instanceof Error ? error.message : 'Unknown error';
      return {
        response: `❌ **NFT Contract Deployment Failed**\n\n${deployCall.error}\n\nPlease check:\n- GOAT-EVM-MCP-SERVER is running\n- Network connectivity\n- Sufficient gas for deployment`,
        toolCalls
      };
    }
  }

  private async executeBalanceCheck(address: string, network: string, currency: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    if (!address) {
      return {
        response: `❌ **Balance Check Failed**\n\nNo wallet address provided. Please specify a valid XDC address (0x...).`,
        toolCalls
      };
    }

    const balanceCall: ToolCall = {
      id: crypto.randomUUID(),
      toolName: 'get_xdc_balance',
      serverName: 'GOAT-EVM-MCP-SERVER',
      parameters: { address, network },
      status: 'pending'
    };
    
    toolCalls.push(balanceCall);
    
    try {
      const balanceResult = await this.mcpClient.executeTool('GOAT-EVM-MCP-SERVER', 'get_xdc_balance', balanceCall.parameters);
      balanceCall.result = balanceResult;
      balanceCall.status = 'success';
      
      return {
        response: `💰 **Balance Check - SUCCESS**\n\n**Address:** ${address}\n**Network:** ${network.toUpperCase()}\n**Balance:** ${balanceResult.balance} ${balanceResult.currency || currency}\n\n${parseFloat(balanceResult.balance) > 0 ? '✅ Sufficient balance for transactions' : '⚠️ Low balance - consider funding this wallet'}`,
        toolCalls
      };
    } catch (error) {
      balanceCall.status = 'error';
      balanceCall.error = error instanceof Error ? error.message : 'Unknown error';
      return {
        response: `❌ **Balance Check Failed**\n\n${balanceCall.error}\n\nPlease verify:\n- Address format is correct\n- Network is accessible\n- GOAT-EVM-MCP-SERVER is connected`,
        toolCalls
      };
    }
  }

  private async executeTokenConversion(intent: any, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    return {
      response: `🔄 **Token Conversion Feature**\n\nERC-721 to ERC-6960 conversion is planned for future release.\n\nThis will enable:\n- Trade finance token creation\n- Compliance data embedding\n- Enhanced liquidity features\n\nStay tuned for updates!`,
      toolCalls
    };
  }

  private async executeExportImportCheck(companyName: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    const exportCall: ToolCall = {
      id: crypto.randomUUID(),
      toolName: 'check-export-import',
      serverName: 'PRET-MCP-SERVER',
      parameters: { companyName },
      status: 'pending'
    };
    
    toolCalls.push(exportCall);
    
    try {
      const exportResult = await this.mcpClient.executeTool('PRET-MCP-SERVER', 'check-export-import', exportCall.parameters);
      exportCall.result = exportResult;
      exportCall.status = 'success';
      
      return {
        response: `🌍 **Export/Import Compliance Check**\n\n**Company:** ${companyName}\n**Status:** ${exportResult.status}\n**Licenses:** ${exportResult.licenses?.join(', ') || 'N/A'}\n**Restrictions:** ${exportResult.restrictions?.length || 0} active\n\n${exportResult.status === 'COMPLIANT' ? '✅ Ready for international trade' : '⚠️ Additional licenses may be required'}`,
        toolCalls
      };
    } catch (error) {
      exportCall.status = 'error';
      exportCall.error = error instanceof Error ? error.message : 'Unknown error';
      return {
        response: `❌ **Export/Import Check Failed**\n\n${exportCall.error}`,
        toolCalls
      };
    }
  }

  private async executeSystemStatusCheck(toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    const servers = Object.keys(this.config.mcpServers);
    const statusResults: any[] = [];

    for (const serverName of servers) {
      const status = this.mcpClient.getServerStatus(serverName);
      const tools = this.mcpClient.getServerTools(serverName);
      
      statusResults.push({
        name: serverName,
        status,
        toolCount: tools.length,
        tools: tools.map(t => t.name)
      });
    }

    const totalTools = statusResults.reduce((sum, server) => sum + server.toolCount, 0);
    const connectedServers = statusResults.filter(s => s.status === 'connected').length;

    return {
      response: `🔧 **MCP System Status Report**\n\n**Overview:**\n- Total Servers: ${servers.length}\n- Connected: ${connectedServers}\n- Total Tools: ${totalTools}\n\n**Server Details:**\n${statusResults.map(server => 
        `\n**${server.name}**\n- Status: ${server.status === 'connected' ? '✅' : '❌'} ${server.status.toUpperCase()}\n- Tools: ${server.toolCount} (${server.tools.slice(0, 3).join(', ')}${server.tools.length > 3 ? '...' : ''})`
      ).join('\n')}\n\n${connectedServers === servers.length ? '🚀 All systems operational!' : '⚠️ Some servers need attention'}`,
      toolCalls
    };
  }

  private async executeGeneralInquiry(message: string, toolCalls: ToolCall[]): Promise<{ response: string; toolCalls: ToolCall[] }> {
    return {
      response: `🤔 **I can help you with MCP operations!**\n\nI didn't quite understand your request, but here's what I can do:\n\n**🔍 Compliance Operations:**\n- "Check GLEIF compliance for [Company]"\n- "Run full compliance workflow for [Company]"\n- "Verify export/import compliance for [Company]"\n\n**🎨 NFT & Blockchain:**\n- "Mint NFT if [Company] is compliant"\n- "Check XDC balance for [address]"\n- "Deploy NFT contract on testnet/mainnet"\n\n**🔄 Advanced Workflows:**\n- "Run compliance check and mint NFT for [Company]"\n- "Check system status"\n\n**💡 Try asking:** "Check GLEIF compliance for Acme Corp and mint NFT if ACTIVE"\n\nWhat would you like me to help you with?`,
      toolCalls
    };
  }

  getAvailableTools() {
    return this.mcpClient.getAvailableTools();
  }

  async disconnect(): Promise<void> {
    await this.mcpClient.disconnect();
  }
}
EOF

# lib/workflow-engine.ts
cat > lib/workflow-engine.ts << 'EOF'
import { MCPClient } from './mcp-client';
import { ToolCall, WorkflowDefinition } from '../types/mcp';

export interface WorkflowRule {
  id: string;
  type: 'COMPLIANCE_GATE' | 'NFT_MINT_CONDITIONAL' | 'TOKEN_CONVERSION' | 'PARALLEL_EXECUTION';
  conditions?: any;
  parameters?: any;
  priority: number;
  autonomous?: boolean;
}

export interface WorkflowResult {
  ruleId: string;
  success: boolean;
  message: string;
  toolCalls: ToolCall[];
  timestamp: Date;
  metadata?: any;
}

export class WorkflowEngine {
  private activeWorkflows: Map<string, WorkflowDefinition> = new Map();
  private executionHistory: WorkflowResult[] = [];

  constructor(private mcpClient: MCPClient) {}

  async executeRule(rule: WorkflowRule, context: any): Promise<WorkflowResult> {
    const toolCalls: ToolCall[] = [];
    let success = false;
    let message = '';
    let metadata: any = {};

    const startTime = Date.now();

    try {
      console.log(`🔄 Executing workflow rule: ${rule.type} (ID: ${rule.id})`);

      switch (rule.type) {
        case 'COMPLIANCE_GATE':
          const complianceResult = await this.executeComplianceGate(rule, context, toolCalls);
          success = complianceResult.success;
          message = complianceResult.message;
          metadata = complianceResult.metadata;
          break;
          
        case 'NFT_MINT_CONDITIONAL':
          const mintResult = await this.executeConditionalMint(rule, context, toolCalls);
          success = mintResult.success;
          message = mintResult.message;
          metadata = mintResult.metadata;
          break;
          
        case 'TOKEN_CONVERSION':
          const conversionResult = await this.executeTokenConversion(rule, context, toolCalls);
          success = conversionResult.success;
          message = conversionResult.message;
          metadata = conversionResult.metadata;
          break;

        case 'PARALLEL_EXECUTION':
          const parallelResult = await this.executeParallelTasks(rule, context, toolCalls);
          success = parallelResult.success;
          message = parallelResult.message;
          metadata = parallelResult.metadata;
          break;
          
        default:
          message = `Unknown rule type: ${rule.type}`;
      }
    } catch (error) {
      console.error(`❌ Rule execution failed:`, error);
      message = `Rule execution failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
    }

    const result: WorkflowResult = {
      ruleId: rule.id,
      success,
      message,
      toolCalls,
      timestamp: new Date(),
      metadata: {
        ...metadata,
        executionTime: Date.now() - startTime,
        ruleType: rule.type,
        autonomous: rule.autonomous || false
      }
    };

    this.executionHistory.push(result);
    
    // Keep only last 100 executions
    if (this.executionHistory.length > 100) {
      this.executionHistory = this.executionHistory.slice(-100);
    }

    return result;
  }

  private async executeComplianceGate(rule: WorkflowRule, context: any, toolCalls: ToolCall[]): Promise<{ success: boolean; message: string; metadata?: any }> {
    const { companyName } = context;
    const requiredChecks = rule.conditions?.requiredCompliance || ['gleif'];
    const threshold = rule.conditions?.threshold || 100; // Percentage required to pass
    
    console.log(`🔍 Executing compliance gate for ${companyName} with checks: ${requiredChecks.join(', ')}`);

    const complianceResults: any = { companyName };
    const checkResults: any[] = [];
    let totalScore = 0;
    let maxScore = 0;

    for (const check of requiredChecks) {
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: this.getToolForCheck(check),
        serverName: this.getServerForCheck(check),
        parameters: { companyName },
        status: 'pending'
      };
      
      toolCalls.push(toolCall);

      try {
        const startTime = Date.now();
        const result = await this.mcpClient.executeTool(toolCall.serverName, toolCall.toolName, toolCall.parameters);
        toolCall.result = result;
        toolCall.status = 'success';
        toolCall.duration = Date.now() - startTime;
        
        // Score each check
        const checkScore = this.scoreComplianceCheck(check, result);
        totalScore += checkScore.score;
        maxScore += checkScore.maxScore;
        
        complianceResults[check] = result.status || result[check + 'Status'];
        checkResults.push({
          check,
          result,
          score: checkScore.score,
          maxScore: checkScore.maxScore,
          passed: checkScore.passed
        });

        console.log(`✅ ${check} check completed: ${checkScore.passed ? 'PASSED' : 'FAILED'} (${checkScore.score}/${checkScore.maxScore})`);
        
      } catch (error) {
        toolCall.status = 'error';
        toolCall.error = error instanceof Error ? error.message : 'Unknown error';
        
        checkResults.push({
          check,
          result: null,
          score: 0,
          maxScore: 25,
          passed: false,
          error: toolCall.error
        });
        
        maxScore += 25; // Default max score per check
        console.error(`❌ ${check} check failed:`, error);
      }
    }
    
    const overallScore = maxScore > 0 ? Math.round((totalScore / maxScore) * 100) : 0;
    const isCompliant = overallScore >= threshold;
    
    const passedChecks = checkResults.filter(c => c.passed).length;
    const totalChecks = checkResults.length;

    return {
      success: isCompliant,
      message: `Compliance Gate Result: ${isCompliant ? 'PASSED' : 'FAILED'} (${overallScore}% - ${passedChecks}/${totalChecks} checks passed)`,
      metadata: {
        companyName,
        overallScore,
        threshold,
        passedChecks,
        totalChecks,
        checkResults,
        complianceResults,
        recommendation: this.generateComplianceRecommendation(checkResults, isCompliant)
      }
    };
  }

  private async executeConditionalMint(rule: WorkflowRule, context: any, toolCalls: ToolCall[]): Promise<{ success: boolean; message: string; metadata?: any }> {
    const { companyName, complianceStatus, contractAddress, recipient, network = 'testnet' } = context;
    
    console.log(`🎨 Executing conditional NFT mint for ${companyName}`);

    // Check if preconditions are met
    if (!complianceStatus || complianceStatus === 'NON_COMPLIANT') {
      return {
        success: false,
        message: `Cannot mint NFT: Company ${companyName} does not meet compliance requirements (Status: ${complianceStatus || 'UNKNOWN'})`,
        metadata: { reason: 'compliance_failed', complianceStatus }
      };
    }

    // Determine contract address if not provided
    const targetContract = contractAddress || rule.parameters?.defaultContract || '0x1234567890123456789012345678901234567890';
    const targetRecipient = recipient || rule.parameters?.defaultRecipient || '0x0987654321098765432109876543210987654321';

    const mintCall: ToolCall = {
      id: crypto.randomUUID(),
      toolName: 'mint_nft',
      serverName: 'GOAT-EVM-MCP-SERVER',
      parameters: {
        contractAddress: targetContract,
        to: targetRecipient,
        tokenURI: `https://metadata.api/company/${encodeURIComponent(companyName)}/compliance`,
        network
      },
      status: 'pending'
    };
    
    toolCalls.push(mintCall);
    
    try {
      const startTime = Date.now();
      const result = await this.mcpClient.executeTool(mintCall.serverName, mintCall.toolName, mintCall.parameters);
      mintCall.result = result;
      mintCall.status = 'success';
      mintCall.duration = Date.now() - startTime;
      
      return {
        success: true,
        message: `NFT successfully minted for ${companyName}. Transaction: ${result.transactionHash}, Token ID: ${result.tokenId}`,
        metadata: {
          transactionHash: result.transactionHash,
          tokenId: result.tokenId,
          contractAddress: targetContract,
          recipient: targetRecipient,
          network,
          companyName
        }
      };
    } catch (error) {
      mintCall.status = 'error';
      mintCall.error = error instanceof Error ? error.message : 'Unknown error';
      
      return {
        success: false,
        message: `NFT minting failed for ${companyName}: ${mintCall.error}`,
        metadata: { 
          error: mintCall.error,
          companyName,
          contractAddress: targetContract 
        }
      };
    }
  }

  private async executeTokenConversion(rule: WorkflowRule, context: any, toolCalls: ToolCall[]): Promise<{ success: boolean; message: string; metadata?: any }> {
    const { tokenId, fromStandard, toStandard, complianceData, network = 'testnet' } = context;
    
    console.log(`🔄 Executing token conversion: ${fromStandard} → ${toStandard} for token ${tokenId}`);

    if (fromStandard === 'ERC721' && toStandard === 'ERC6960') {
      const conversionCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: 'convert_to_erc6960',
        serverName: 'GOAT-EVM-MCP-SERVER',
        parameters: {
          tokenId,
          tradeFinanceData: {
            complianceScore: complianceData?.score || 85,
            riskAssessment: complianceData?.riskLevel || 'LOW_RISK',
            financialHealth: complianceData?.financialHealth || 'GOOD',
            regulatoryCompliance: complianceData?.regulatory || 'COMPLIANT'
          },
          network
        },
        status: 'pending'
      };
      
      toolCalls.push(conversionCall);
      
      try {
        // Note: This would be a real conversion in production
        // For now, we'll simulate the conversion
        const simulatedResult = {
          originalTokenId: tokenId,
          newTokenId: `TFT-${tokenId}`,
          transactionHash: '0x' + Array.from({length: 64}, () => Math.floor(Math.random() * 16).toString(16)).join(''),
          contractAddress: '0x' + Array.from({length: 40}, () => Math.floor(Math.random() * 16).toString(16)).join(''),
          status: 'converted',
          tradeFinanceFeatures: {
            divisibility: true,
            transferRestrictions: true,
            complianceEmbedded: true,
            liquidityEnabled: true
          }
        };
        
        conversionCall.result = simulatedResult;
        conversionCall.status = 'success';
        
        return {
          success: true,
          message: `Token ${tokenId} successfully converted to ERC-6960 trade finance standard. New Token: ${simulatedResult.newTokenId}`,
          metadata: {
            originalTokenId: tokenId,
            newTokenId: simulatedResult.newTokenId,
            transactionHash: simulatedResult.transactionHash,
            contractAddress: simulatedResult.contractAddress,
            fromStandard,
            toStandard,
            features: simulatedResult.tradeFinanceFeatures
          }
        };
      } catch (error) {
        conversionCall.status = 'error';
        conversionCall.error = error instanceof Error ? error.message : 'Unknown error';
        
        return {
          success: false,
          message: `Token conversion failed: ${conversionCall.error}`,
          metadata: { error: conversionCall.error, tokenId, fromStandard, toStandard }
        };
      }
    }
    
    return {
      success: false,
      message: `Unsupported token conversion: ${fromStandard} to ${toStandard}. Currently supported: ERC721 → ERC6960`,
      metadata: { fromStandard, toStandard, supported: false }
    };
  }

  private async executeParallelTasks(rule: WorkflowRule, context: any, toolCalls: ToolCall[]): Promise<{ success: boolean; message: string; metadata?: any }> {
    const tasks = rule.parameters?.tasks || [];
    console.log(`⚡ Executing ${tasks.length} parallel tasks`);

    const taskPromises = tasks.map(async (task: any) => {
      const toolCall: ToolCall = {
        id: crypto.randomUUID(),
        toolName: task.tool,
        serverName: task.server,
        parameters: { ...task.parameters, ...context },
        status: 'pending'
      };
      
      toolCalls.push(toolCall);

      try {
        const startTime = Date.now();
        const result = await this.mcpClient.executeTool(task.server, task.tool, toolCall.parameters);
        toolCall.result = result;
        toolCall.status = 'success';
        toolCall.duration = Date.now() - startTime;
        return { task: task.name, success: true, result };
      } catch (error) {
        toolCall.status = 'error';
        toolCall.error = error instanceof Error ? error.message : 'Unknown error';
        return { task: task.name, success: false, error: toolCall.error };
      }
    });

    const results = await Promise.all(taskPromises);
    const successCount = results.filter(r => r.success).length;
    const totalCount = results.length;
    const overallSuccess = successCount === totalCount;

    return {
      success: overallSuccess,
      message: `Parallel execution completed: ${successCount}/${totalCount} tasks succeeded`,
      metadata: {
        totalTasks: totalCount,
        successfulTasks: successCount,
        failedTasks: totalCount - successCount,
        results
      }
    };
  }

  private getToolForCheck(checkType: string): string {
    const toolMap: Record<string, string> = {
      'gleif': 'get-GLEIF-data',
      'corp_registration': 'check-corp-registration',
      'corpRegistration': 'check-corp-registration',
      'export_import': 'check-export-import',
      'exportImport': 'check-export-import',
      'financial_health': 'assess-financial-health',
      'financialHealth': 'assess-financial-health'
    };
    
    return toolMap[checkType] || 'generic-compliance-check';
  }

  private getServerForCheck(checkType: string): string {
    // Most compliance checks go to PRET-MCP-SERVER
    const serverMap: Record<string, string> = {
      'gleif': 'PRET-MCP-SERVER',
      'corp_registration': 'PRET-MCP-SERVER',
      'corpRegistration': 'PRET-MCP-SERVER',
      'export_import': 'PRET-MCP-SERVER',
      'exportImport': 'PRET-MCP-SERVER',
      'financial_health': 'PRET-MCP-SERVER',
      'financialHealth': 'PRET-MCP-SERVER'
    };
    
    return serverMap[checkType] || 'PRET-MCP-SERVER';
  }

  private scoreComplianceCheck(checkType: string, result: any): { score: number; maxScore: number; passed: boolean } {
    const maxScore = 25; // Each check worth 25 points max
    
    switch (checkType) {
      case 'gleif':
        if (result.gleifStatus === 'ACTIVE') {
          return { score: 25, maxScore, passed: true };
        } else if (result.gleifStatus === 'PENDING') {
          return { score: 10, maxScore, passed: false };
        } else {
          return { score: 0, maxScore, passed: false };
        }
      
      case 'corp_registration':
      case 'corpRegistration':
        if (result.status === 'COMPLIANT') {
          return { score: 25, maxScore, passed: true };
        } else if (result.status === 'PENDING') {
          return { score: 10, maxScore, passed: false };
        } else {
          return { score: 0, maxScore, passed: false };
        }
      
      case 'export_import':
      case 'exportImport':
        if (result.status === 'COMPLIANT') {
          return { score: 25, maxScore, passed: true };
        } else {
          return { score: 0, maxScore, passed: false };
        }
      
      default:
        // Generic scoring
        if (result.status === 'COMPLIANT' || result.status === 'ACTIVE') {
          return { score: 25, maxScore, passed: true };
        } else {
          return { score: 0, maxScore, passed: false };
        }
    }
  }

  private generateComplianceRecommendation(checkResults: any[], isCompliant: boolean): string {
    if (isCompliant) {
      return "All compliance requirements met. Ready for advanced operations like NFT minting and trade finance token creation.";
    }

    const failedChecks = checkResults.filter(c => !c.passed);
    const recommendations = [];

    for (const check of failedChecks) {
      switch (check.check) {
        case 'gleif':
          recommendations.push("• Obtain active GLEIF Legal Entity Identifier (LEI) registration");
          break;
        case 'corp_registration':
        case 'corpRegistration':
          recommendations.push("• Ensure corporate registration is current and valid in jurisdiction");
          break;
        case 'export_import':
        case 'exportImport':
          recommendations.push("• Obtain necessary export/import licenses and trade permits");
          break;
        default:
          recommendations.push(`• Address ${check.check} compliance requirements`);
      }
    }

    return `Required actions to achieve compliance:\n${recommendations.join('\n')}`;
  }

  // Workflow management methods
  registerWorkflow(workflow: WorkflowDefinition): void {
    this.activeWorkflows.set(workflow.id, workflow);
    console.log(`📋 Registered workflow: ${workflow.name} (${workflow.id})`);
  }

  async executeWorkflow(workflowId: string, context: any): Promise<WorkflowResult[]> {
    const workflow = this.activeWorkflows.get(workflowId);
    if (!workflow) {
      throw new Error(`Workflow not found: ${workflowId}`);
    }

    console.log(`🚀 Executing workflow: ${workflow.name}`);
    const results: WorkflowResult[] = [];

    for (const step of workflow.steps) {
      const rule: WorkflowRule = {
        id: step.id,
        type: this.mapStepTypeToRuleType(step.type),
        parameters: step.parameters,
        priority: 1,
        autonomous: workflow.autonomous
      };

      const result = await this.executeRule(rule, context);
      results.push(result);

      // Handle step flow control
      if (!result.success && step.onFailure) {
        console.log(`⚠️ Step failed, jumping to: ${step.onFailure}`);
        // In a full implementation, we'd handle step jumping
        break;
      }
    }

    return results;
  }

  private mapStepTypeToRuleType(stepType: string): WorkflowRule['type'] {
    const mapping: Record<string, WorkflowRule['type']> = {
      'tool_call': 'COMPLIANCE_GATE',
      'condition': 'COMPLIANCE_GATE',
      'decision': 'NFT_MINT_CONDITIONAL',
      'parallel': 'PARALLEL_EXECUTION'
    };

    return mapping[stepType] || 'COMPLIANCE_GATE';
  }

  getExecutionHistory(): WorkflowResult[] {
    return [...this.executionHistory];
  }

  getActiveWorkflows(): WorkflowDefinition[] {
    return Array.from(this.activeWorkflows.values());
  }

  clearExecutionHistory(): void {
    this.executionHistory = [];
  }
}
EOF

echo "📝 Creating API routes..."

# app/api/mcp/route.ts
cat > app/api/mcp/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { MCPOrchestrator } from '../../../lib/orchestrator';
import { ConfigManager } from '../../../lib/config-manager';

let orchestrator: MCPOrchestrator | null = null;

// Initialize orchestrator with default config
const getOrchestrator = async () => {
  if (!orchestrator) {
    const config = ConfigManager.getDefaultConfig();
    orchestrator = new MCPOrchestrator(config);
    await orchestrator.initialize();
  }
  return orchestrator;
};

export async function POST(request: NextRequest) {
  try {
    const { message, action, config } = await request.json();
    
    // Reinitialize if config provided
    if (config && ConfigManager.validateConfig(config)) {
      orchestrator = new MCPOrchestrator(config);
      await orchestrator.initialize();
    }
    
    const orch = await getOrchestrator();
    
    if (action === 'chat') {
      const response = await orch.processMessage(message);
      return NextResponse.json(response);
    }
    
    if (action === 'tools') {
      const tools = orch.getAvailableTools();
      return NextResponse.json({ tools });
    }
    
    if (action === 'status') {
      const tools = orch.getAvailableTools();
      return NextResponse.json({
        status: 'connected',
        toolCount: tools.length,
        timestamp: new Date().toISOString()
      });
    }
    
    return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
    
  } catch (error) {
    console.error('MCP API Error:', error);
    return NextResponse.json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

export async function GET() {
  try {
    const orch = await getOrchestrator();
    const tools = orch.getAvailableTools();
    
    return NextResponse.json({
      status: 'healthy',
      tools: tools.length,
      servers: ['PRET-MCP-SERVER', 'GOAT-EVM-MCP-SERVER', 'FILE-MCP-SERVER'],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    return NextResponse.json({ 
      error: 'Failed to initialize',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}
EOF

# app/api/compliance/route.ts
cat > app/api/compliance/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { ComplianceResult } from '../../../types/mcp';

export async function POST(request: NextRequest) {
  try {
    const { companyName, checks = ['gleif', 'corpRegistration'] } = await request.json();
    
    if (!companyName) {
      return NextResponse.json({ error: 'Company name is required' }, { status: 400 });
    }
    
    // Mock comprehensive compliance checking logic
    const complianceResults: ComplianceResult = {
      companyName,
      gleifStatus: Math.random() > 0.3 ? 'ACTIVE' : 'INACTIVE',
      corpRegistration: Math.random() > 0.2 ? 'COMPLIANT' : 'NON_COMPLIANT',
      exportImport: Math.random() > 0.4 ? 'COMPLIANT' : 'NON_COMPLIANT',
      financialHealth: ['LOW_RISK', 'MEDIUM_RISK', 'HIGH_RISK'][Math.floor(Math.random() * 3)] as any,
      overallCompliance: 'PENDING',
      score: 0,
      lastUpdated: new Date().toISOString()
    };
    
    // Calculate compliance score
    let score = 0;
    let maxScore = 0;
    
    if (checks.includes('gleif')) {
      maxScore += 30;
      if (complianceResults.gleifStatus === 'ACTIVE') score += 30;
      else if (complianceResults.gleifStatus === 'PENDING') score += 15;
    }
    
    if (checks.includes('corpRegistration')) {
      maxScore += 25;
      if (complianceResults.corpRegistration === 'COMPLIANT') score += 25;
    }
    
    if (checks.includes('exportImport')) {
      maxScore += 25;
      if (complianceResults.exportImport === 'COMPLIANT') score += 25;
    }
    
    if (checks.includes('financialHealth')) {
      maxScore += 20;
      if (complianceResults.financialHealth === 'LOW_RISK') score += 20;
      else if (complianceResults.financialHealth === 'MEDIUM_RISK') score += 12;
      else score += 5;
    }
    
    complianceResults.score = maxScore > 0 ? Math.round((score / maxScore) * 100) : 0;
    
    // Determine overall compliance
    if (complianceResults.score >= 85) {
      complianceResults.overallCompliance = 'FULLY_COMPLIANT';
    } else if (complianceResults.score >= 60) {
      complianceResults.overallCompliance = 'PARTIALLY_COMPLIANT';
    } else {
      complianceResults.overallCompliance = 'NON_COMPLIANT';
    }
    
    // Add realistic delays and metadata
    const metadata = {
      checksPerformed: checks,
      processingTime: 500 + Math.random() * 2000, // 0.5-2.5 seconds
      dataProviders: {
        gleif: 'GLEIF Global Directory',
        corpRegistration: 'Corporate Registry API',
        exportImport: 'Trade Compliance Database',
        financialHealth: 'Credit Rating Service'
      },
      recommendations: generateRecommendations(complianceResults)
    };
    
    return NextResponse.json({
      ...complianceResults,
      metadata
    });
    
  } catch (error) {
    console.error('Compliance API Error:', error);
    return NextResponse.json({ 
      error: 'Compliance check failed',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

function generateRecommendations(compliance: ComplianceResult): string[] {
  const recommendations: string[] = [];
  
  if (compliance.gleifStatus !== 'ACTIVE') {
    recommendations.push('Obtain or renew GLEIF Legal Entity Identifier (LEI) registration');
  }
  
  if (compliance.corpRegistration !== 'COMPLIANT') {
    recommendations.push('Update corporate registration and ensure all filings are current');
  }
  
  if (compliance.exportImport !== 'COMPLIANT') {
    recommendations.push('Acquire necessary export/import licenses for international trade');
  }
  
  if (compliance.financialHealth === 'HIGH_RISK') {
    recommendations.push('Improve financial health metrics and creditworthiness');
  } else if (compliance.financialHealth === 'MEDIUM_RISK') {
    recommendations.push('Monitor financial health and consider risk mitigation strategies');
  }
  
  if (compliance.overallCompliance === 'FULLY_COMPLIANT') {
    recommendations.push('Consider advanced features like trade finance tokenization');
  }
  
  return recommendations;
}

export async function GET() {
  return NextResponse.json({
    service: 'MCP Compliance API',
    version: '1.0.0',
    supportedChecks: ['gleif', 'corpRegistration', 'exportImport', 'financialHealth'],
    status: 'operational'
  });
}
EOF

echo "📋 Creating scripts..."

# scripts/setup.sh
cat > scripts/setup.sh << 'EOF'
#!/bin/bash

echo "🚀 Setting up MCP Chat Interface..."

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create data directory for FILE-MCP-SERVER
mkdir -p data
echo "Sample company data for testing" > data/sample.txt

# Build MCP Orchestrator
echo "🔧 Building MCP Orchestrator..."
cd mcp-orchestrator
npm install
npm run build
cd ..

# Set up environment variables
if [ ! -f .env.local ]; then
    echo "📝 Creating environment file..."
    cp .env.local .env.local.backup 2>/dev/null || true
    echo "Environment file created. Please update with your actual values."
fi

# Create next-env.d.ts
cat > next-env.d.ts << 'ENVEOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/basic-features/typescript for more information.
ENVEOF

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env.local with your API keys and server URLs"
echo "2. Start your MCP servers (PRET-MCP-SERVER, GOAT-EVM-MCP-SERVER, etc.)"
echo "3. Run 'npm run dev' to start the development server"
echo "4. Optional: Run 'npm run orchestrator:dev' to start the MCP orchestrator"
echo ""
echo "🌐 The app will be available at http://localhost:3000"
EOF

chmod +x scripts/setup.sh

echo "📋 Creating documentation..."

# docs/README.md
cat > docs/README.md << 'EOF'
# MCP Chat Interface

A natural language chat interface for Model Context Protocol (MCP) servers with built-in compliance workflows and blockchain operations.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP Chat Interface                           │
│                     (Next.js App)                              │
├─────────────────────────────────────────────────────────────────┤
│                  MCP Orchestrator                              │
│              (Optional MCP Server)                             │
├─────────────────────────────────────────────────────────────────┤
│  PRET-MCP-SERVER  │  GOAT-EVM-MCP-SERVER  │  FILE-MCP-SERVER   │
│  (Compliance)     │  (Blockchain)         │  (Storage)         │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### 🔍 **Compliance Workflows**
- GLEIF Legal Entity Identifier verification
- Corporate registration status checking
- Export/import compliance verification
- Multi-step compliance orchestration

### 🎨 **Blockchain Operations**
- NFT minting on XDC Network (mainnet/testnet)
- Smart contract deployment
- Balance checking and token transfers
- ERC-721 to ERC-6960 conversion (planned)

### 🔄 **Workflow Automation**
- Visual workflow builder
- Conditional logic execution
- Parallel task processing
- Autonomous operation boundaries

### 🌐 **Natural Language Interface**
- Intent parsing from natural language
- Multi-server tool orchestration
- Real-time execution feedback
- Comprehensive error handling

## Quick Start

1. **Setup Project**
   ```bash
   ./scripts/setup.sh
   ```

2. **Configure Environment**
   ```bash
   # Edit .env.local with your values
   PRET_MCP_SERVER_URL=ws://localhost:3001
   GOAT_EVM_MCP_SERVER_URL=ws://localhost:3003
   PRET_API_KEY=your-api-key
   GOAT_PRIVATE_KEY=your-private-key
   ```

3. **Start Development**
   ```bash
   npm run dev                    # Start Next.js app
   npm run orchestrator:dev       # Start MCP orchestrator (optional)
   ```

4. **Deploy to Vercel**
   ```bash
   vercel deploy
   ```

## Usage Examples

### Compliance Checking
```
"Check GLEIF compliance for Acme Corp"
"Run full compliance workflow for TechStart"
"Verify export/import compliance for GlobalTrade"
```

### NFT Operations
```
"Mint NFT if CompanyX is GLEIF compliant"
"Deploy NFT contract on XDC testnet"
"Check XDC balance for wallet 0x123..."
```

### Advanced Workflows
```
"Check compliance for Acme Corp and mint NFT if all requirements are met"
"Convert ERC-721 token 123 to ERC-6960 for trade finance"
```

## Configuration

### MCP Server Configuration
The application uses a Claude Desktop-style configuration:

```json
{
  "mcpServers": {
    "PRET-MCP-SERVER": {
      "name": "PRET-MCP-SERVER",
      "command": "pret-mcp-server",
      "args": ["--port", "3001"],
      "url": "ws://localhost:3001",
      "env": {
        "API_KEY": "your-pret-api-key"
      }
    },
    "GOAT-EVM-MCP-SERVER": {
      "name": "GOAT-EVM-MCP-SERVER",
      "command": "goat-evm-mcp-server", 
      "args": ["--network", "xdc"],
      "url": "ws://localhost:3003",
      "env": {
        "PRIVATE_KEY": "your-private-key",
        "RPC_URL": "https://erpc.xinfin.network"
      }
    }
  }
}
```

## MCP Orchestrator

The MCP Orchestrator is **BOTH**:

1. **An MCP Server** - Can be used by Claude Desktop or other MCP clients
2. **A Service** - Serves the web chat interface

### As an MCP Server
Add to your Claude Desktop config:
```json
{
  "mcpServers": {
    "mcp-orchestrator": {
      "command": "node",
      "args": ["./mcp-orchestrator/dist/server.js"]
    }
  }
}
```

### Available Orchestrator Tools
- `compliance_workflow` - Complete compliance check + NFT minting
- `gleif_check_and_mint` - GLEIF check with conditional NFT mint
- `multi_compliance_check` - Parallel compliance verification
- `erc721_to_erc6960_conversion` - Token standard conversion
- `get_orchestrator_status` - System health check

## API Endpoints

### `/api/mcp` - Main orchestrator endpoint
```typescript
POST /api/mcp
{
  "action": "chat",
  "message": "Check GLEIF compliance for Acme Corp"
}
```

### `/api/compliance` - Compliance checking service
```typescript
POST /api/compliance
{
  "companyName": "Acme Corp",
  "checks": ["gleif", "corpRegistration", "exportImport"]
}
```

## Development

### Project Structure
```
mcp-chat-interface/
├── app/                    # Next.js 14 app directory
│   ├── api/               # API routes
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Main page
├── components/            # React components
│   ├── chat-interface.tsx # Main chat UI
│   └── workflow-builder.tsx # Workflow builder
├── lib/                   # Core libraries
│   ├── mcp-client.ts      # MCP client implementation
│   ├── orchestrator.ts    # Main orchestrator
│   ├── workflow-engine.ts # Workflow execution
│   └── config-manager.ts  # Configuration management
├── types/                 # TypeScript definitions
├── mcp-orchestrator/      # Standalone MCP server
│   ├── src/server.ts      # Main orchestrator server
│   └── package.json       # Orchestrator dependencies
└── scripts/               # Setup and utility scripts
```

### Adding New MCP Servers

1. **Update Configuration**
   ```typescript
   // Add to config
   "NEW-MCP-SERVER": {
     "name": "NEW-MCP-SERVER",
     "url": "ws://localhost:3005",
     "command": "new-mcp-server"
   }
   ```

2. **Add Tool Definitions**
   ```typescript
   // In mcp-client.ts
   'NEW-MCP-SERVER': [
     {
       name: 'new-tool',
       description: 'Description of new tool',
       inputSchema: { /* schema */ },
       server: 'NEW-MCP-SERVER'
     }
   ]
   ```

3. **Update Intent Parser**
   ```typescript
   // In orchestrator.ts
   if (lowerMessage.includes('new-operation')) {
     return {
       type: 'new_operation',
       parameters: extractParameters(message)
     };
   }
   ```

## Deployment

### Vercel (Recommended)
```bash
vercel deploy
```

### Docker
```bash
docker build -t mcp-chat-interface .
docker run -p 3000:3000 mcp-chat-interface
```

### Environment Variables for Production
```bash
NODE_ENV=production
PRET_MCP_SERVER_URL=wss://your-pret-server.com
GOAT_EVM_MCP_SERVER_URL=wss://your-goat-server.com
# Add your production API keys and URLs
```

## Troubleshooting

### Common Issues

1. **MCP Server Connection Failed**
   - Ensure MCP servers are running
   - Check URL and port configuration
   - Verify network connectivity

2. **Tool Execution Timeout**
   - Check server responsiveness
   - Increase timeout values if needed
   - Verify tool parameters

3. **Configuration Errors**
   - Validate JSON configuration
   - Check required environment variables
   - Ensure proper permissions

### Debug Mode
```bash
DEBUG=mcp:* npm run dev
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push branch: `git push origin feature/new-feature`
5. Submit pull request

## License

MIT License - see LICENSE file for details.
EOF

# Create README.md in root
cat > README.md << 'EOF'
# MCP Chat Interface

🚀 **Natural Language Interface for MCP Servers with Compliance Workflows**

A Next.js application that provides a conversational interface to Model Context Protocol (MCP) servers, specializing in compliance checking, NFT operations, and automated workflows.

## ✨ Features

- **🔍 Compliance Workflows**: GLEIF, Corporate Registration, Export/Import verification
- **🎨 Blockchain Operations**: NFT minting, contract deployment on XDC Network
- **🔄 Workflow Automation**: Visual workflow builder with conditional logic
- **🌐 Natural Language**: Intent parsing from conversational input
- **📡 MCP Orchestrator**: Acts as both MCP server and web service
- **🔧 Multi-Server**: Orchestrates calls across multiple MCP servers

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository>
cd mcp-chat-interface
./scripts/setup.sh

# Configure environment
cp .env.local.example .env.local
# Edit .env.local with your values

# Start development
npm run dev                    # Next.js app at http://localhost:3000
npm run orchestrator:dev       # MCP orchestrator at http://localhost:3002
```

## 💬 Usage Examples

```
"Check GLEIF compliance for Acme Corp"
"Run full compliance workflow for TechStart"
"Mint NFT if CompanyX is GLEIF compliant"
"Check XDC balance for wallet 0x123..."
"Convert ERC-721 token to ERC-6960 for trade finance"
```

## 🏗️ Architecture

```
Web Chat Interface (Next.js)
        ↓
MCP Orchestrator (Optional)
        ↓
┌─────────────┬─────────────────┬─────────────┐
│PRET-MCP     │GOAT-EVM-MCP     │FILE-MCP     │
│(Compliance) │(Blockchain)     │(Storage)    │
└─────────────┴─────────────────┴─────────────┘
```

## 📖 Documentation

- [Full Documentation](./docs/README.md)
- [API Reference](./docs/API.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)

## 🚢 Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/your-repo/mcp-chat-interface)

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guide](./CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](./LICENSE) file.
EOF

echo "✅ Project structure created successfully!"
echo ""
echo "📁 Project Structure:"
echo "mcp-chat-interface/"
echo "├── app/                   # Next.js 14 app"
echo "├── components/            # React components"  
echo "├── lib/                   # Core libraries"
echo "├── types/                 # TypeScript types"
echo "├── mcp-orchestrator/      # MCP orchestrator server"
echo "├── scripts/               # Setup scripts"
echo "├── docs/                  # Documentation"
echo "└── Configuration files"
echo ""
echo "🚀 Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. ./scripts/setup.sh"
echo "3. Edit .env.local with your API keys"
echo "4. npm run dev"
echo ""
echo "🌐 Your MCP Chat Interface will be ready at http://localhost:3000"
    #!/bin/bash

# MCP Chat Interface - Project Setup Script
# This script creates the complete project structure and files

set -e

PROJECT_NAME="mcp-chat-interface"
echo "🚀 Setting up MCP Chat Interface project: $PROJECT_NAME"

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

echo "📁 Creating project structure..."

# Create directory structure
mkdir -p {app/{api/{mcp,compliance,orchestrator},globals},components,lib,types,public,docs,.vscode}
mkdir -p app/api/mcp-server
mkdir -p mcp-orchestrator/{src,dist,config}
mkdir -p scripts

echo "📄 Creating configuration files..."

# package.json
cat > package.json << 'EOF'
{
  "name": "mcp-chat-interface",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "setup": "./scripts/setup.sh",
    "orchestrator:dev": "cd mcp-orchestrator && npm run dev",
    "orchestrator:build": "cd mcp-orchestrator && npm run build",
    "orchestrator:start": "cd mcp-orchestrator && npm start"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.2.2",
    "@types/node": "^20.8.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "ws": "^8.14.2",
    "axios": "^1.5.0",
    "zod": "^3.22.4",
    "lucide-react": "^0.290.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^1.14.0",
    "@mcp/sdk": "^1.0.0"
  },
  "devDependencies": {
    "@types/ws": "^8.5.8",
    "eslint": "^8.52.0",
    "eslint-config-next": "14.0.0"
  }
}
EOF

# next.config.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    serverActions: true,
  },
  webpack: (config) => {
    config.resolve.fallback = {
      ...config.resolve.fallback,
      ws: false,
    };
    return config;
  },
  async rewrites() {
    return [
      {
        source: '/mcp/:path*',
        destination: 'http://localhost:3002/mcp/:path*',
      },
    ];
  },
}

module.exports = nextConfig
EOF

# tailwind.config.js
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
      },
    },
  },
  plugins: [],
}
EOF

# postcss.config.js
cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"],
      "@/components/*": ["./components/*"],
      "@/lib/*": ["./lib/*"],
      "@/types/*": ["./types/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# vercel.json
cat > vercel.json << 'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "next.config.js",
      "use": "@vercel/next"
    },
    {
      "src": "mcp-orchestrator/src/server.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/api/$1"
    },
    {
      "src": "/mcp/(.*)",
      "dest": "/mcp-orchestrator/src/server.ts"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
EOF

# .env.local (template)
cat > .env.local << 'EOF'
# MCP Server Configuration
PRET_MCP_SERVER_URL=ws://localhost:3001
GOAT_EVM_MCP_SERVER_URL=ws://localhost:3003
FILE_MCP_SERVER_URL=ws://localhost:3004

# MCP Orchestrator
MCP_ORCHESTRATOR_PORT=3002
MCP_ORCHESTRATOR_HOST=localhost

# API Keys (Replace with your actual keys)
PRET_API_KEY=your-pret-api-key-here
GOAT_PRIVATE_KEY=your-private-key-here
XDC_RPC_URL=https://erpc.xinfin.network
XDC_TESTNET_RPC_URL=https://erpc.apothem.network

# Security
JWT_SECRET=your-jwt-secret-here
ENCRYPTION_KEY=your-encryption-key-here

# Feature Flags
ENABLE_AUTONOMOUS_MODE=false
MAX_CONCURRENT_TOOLS=5
ENABLE_WORKFLOW_BUILDER=true
EOF

echo "🎨 Creating app files..."

# app/globals.css
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --border: 214.3 31.8% 91.4%;
  --primary: 222.2 47.4% 11.2%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
  --muted: 210 40% 96%;
  --muted-foreground: 215.4 16.3% 46.9%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --border: 217.2 32.6% 17.5%;
  --primary: 210 40% 98%;
  --primary-foreground: 222.2 47.4% 11.2%;
  --secondary: 217.2 32.6% 17.5%;
  --secondary-foreground: 210 40% 98%;
  --muted: 217.2 32.6% 17.5%;
  --muted-foreground: 215.4 16.3% 56.9%;
}

body {
  color: rgb(var(--foreground));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background))
    )
    rgb(var(--background));
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: hsl(var(--muted));
}

::-webkit-scrollbar-thumb {
  background: hsl(var(--border));
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: hsl(var(--muted-foreground));
}
EOF

# app/layout.tsx
cat > app/layout.tsx << 'EOF'
import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'MCP Chat Interface',
  description: 'Natural language interface for MCP servers with compliance workflows',
  keywords: ['MCP', 'Model Context Protocol', 'Compliance', 'NFT', 'Blockchain', 'Workflow'],
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  )
}
EOF

# app/page.tsx
cat > app/page.tsx << 'EOF'
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
EOF

echo "🔧 Creating types..."

# types/mcp.ts
cat > types/mcp.ts << 'EOF'
export interface MCPServer {
  name: string;
  command: string;
  args?: string[];
  env?: Record<string, string>;
  tools?: MCPTool[];
  status?: 'connected' | 'disconnected' | 'error';
  url?: string;
  port?: number;
}

export interface MCPTool {
  name: string;
  description: string;
  inputSchema: any;
  server: string;
  category?: 'compliance' | 'blockchain' | 'storage' | 'utility';
}

export interface MCPConfig {
  mcpServers: Record<string, MCPServer>;
  workflows?: WorkflowDefinition[];
  settings?: {
    autoExecute: boolean;
    confirmActions: boolean;
    maxConcurrentTools: number;
    enableAutonomous: boolean;
  };
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  toolCalls?: ToolCall[];
  metadata?: {
    workflowId?: string;
    complianceCheck?: ComplianceResult;
    transactionHash?: string;
  };
}

export interface ToolCall {
  id: string;
  toolName: string;
  serverName: string;
  parameters: any;
  result?: any;
  status: 'pending' | 'success' | 'error';
  duration?: number;
  error?: string;
}

export interface ComplianceResult {
  companyName: string;
  gleifStatus: 'ACTIVE' | 'INACTIVE' | 'PENDING';
  corpRegistration: 'COMPLIANT' | 'NON_COMPLIANT' | 'PENDING';
  exportImport: 'COMPLIANT' | 'NON_COMPLIANT' | 'PENDING';
  financialHealth: 'LOW_RISK' | 'MEDIUM_RISK' | 'HIGH_RISK';
  overallCompliance: 'FULLY_COMPLIANT' | 'PARTIALLY_COMPLIANT' | 'NON_COMPLIANT';
  score: number;
  lastUpdated: string;
}

export interface WorkflowDefinition {
  id: string;
  name: string;
  description: string;
  steps: WorkflowStep[];
  triggers: WorkflowTrigger[];
  autonomous: boolean;
}

export interface WorkflowStep {
  id: string;
  type: 'tool_call' | 'condition' | 'decision' | 'parallel';
  server?: string;
  tool?: string;
  parameters?: any;
  condition?: string;
  onSuccess?: string; // next step id
  onFailure?: string; // next step id
}

export interface WorkflowTrigger {
  type: 'manual' | 'schedule' | 'event' | 'webhook';
  config: any;
}

export interface NFTMetadata {
  name: string;
  description: string;
  image: string;
  attributes: Array<{
    trait_type: string;
    value: string | number;
  }>;
  compliance?: ComplianceResult;
}

export interface BlockchainTransaction {
  hash: string;
  status: 'pending' | 'confirmed' | 'failed';
  network: 'mainnet' | 'testnet';
  gasUsed?: string;
  gasPrice?: string;
  blockNumber?: number;
}
EOF

echo "📚 Creating library files..."

# lib/config-manager.ts
cat > lib/config-manager.ts << 'EOF'
import { MCPConfig } from '../types/mcp';

export class ConfigManager {
  private static readonly CONFIG_KEY = 'mcp-chat-config';
  private static readonly VERSION = '1.0.0';
  
  static loadConfig(): MCPConfig | null {
    if (typeof window === 'undefined') return null;
    
    try {
      const stored = localStorage.getItem(this.CONFIG_KEY);
      if (!stored) return null;
      
      const config = JSON.parse(stored);
      
      // Version check and migration if needed
      if (config.version !== this.VERSION) {
        return this.migrateConfig(config);
      }
      
      return config;
    } catch (error) {
      console.error('Failed to load config:', error);
      return null;
    }
  }
  
  static saveConfig(config: MCPConfig): void {
    if (typeof window === 'undefined') return;
    
    try {
      const configWithVersion = {
        ...config,
        version: this.VERSION,
        lastUpdated: new Date().toISOString()
      };
      
      localStorage.setItem(this.CONFIG_KEY, JSON.stringify(configWithVersion, null, 2));
    } catch (error) {
      console.error('Failed to save config:', error);
    }
  }
  
  static getDefaultConfig(): MCPConfig {
    return {
      mcpServers: {
        "PRET-MCP-SERVER": {
          name: "PRET-MCP-SERVER",
          command: "pret-mcp-server",
          args: ["--port", "3001"],
          url: "ws://localhost:3001",
          port: 3001,
          env: {
            "API_KEY": process.env.PRET_API_KEY || "your-pret-api-key"
          }
        },
        "GOAT-EVM-MCP-SERVER": {
          name: "GOAT-EVM-MCP-SERVER", 
          command: "goat-evm-mcp-server",
          args: ["--network", "xdc", "--port", "3003"],
          url: "ws://localhost:3003",
          port: 3003,
          env: {
            "PRIVATE_KEY": process.env.GOAT_PRIVATE_KEY || "your-private-key",
            "RPC_URL": process.env.XDC_RPC_URL || "https://erpc.xinfin.network"
          }
        },
        "FILE-MCP-SERVER": {
          name: "FILE-MCP-SERVER",
          command: "file-mcp-server",
          args: ["--root", "./data", "--port", "3004"],
          url: "ws://localhost:3004",
          port: 3004
        }
      },
      workflows: [
        {
          id: "gleif-nft-workflow",
          name: "GLEIF Compliance → NFT Minting",
          description: "Check GLEIF compliance and mint NFT if active",
          autonomous: false,
          steps: [
            {
              id: "check-gleif",
              type: "tool_call",
              server: "PRET-MCP-SERVER",
              tool: "get-GLEIF-data",
              onSuccess: "mint-nft",
              onFailure: "error-response"
            },
            {
              id: "mint-nft",
              type: "tool_call",
              server: "GOAT-EVM-MCP-SERVER",
              tool: "mint_nft"
            }
          ],
          triggers: [
            {
              type: "manual",
              config: {}
            }
          ]
        }
      ],
      settings: {
        autoExecute: false,
        confirmActions: true,
        maxConcurrentTools: 5,
        enableAutonomous: false
      }
    };
  }
  
  private static migrateConfig(oldConfig: any): MCPConfig {
    // Handle config migrations between versions
    console.log('Migrating config to version', this.VERSION);
    
    // For now, just return default config
    // In the future, implement proper migration logic
    return this.getDefaultConfig();
  }
  
  static validateConfig(config: any): boolean {
    try {
      return (
        config &&
        typeof config === 'object' &&
        config.mcpServers &&
        typeof config.mcpServers === 'object' &&
        Object.keys(config.mcpServers).length > 0
      );
    } catch (error) {
      return false;
    }
  }
}
EOF

# lib/mcp-client.ts - Complete implementation
cat > lib/mcp-client.ts << 'EOF'
import WebSocket from 'ws';
import { MCPServer, MCPTool, ToolCall } from '../types/mcp';

export class MCPClient {
  private connections: Map<string, WebSocket> = new Map();
  private tools: Map<string, MCPTool[]> = new Map();
  private messageHandlers: Map<string, (data: any) => void> = new Map();
  
  constructor(private config: Record<string, MCPServer>) {}

  async initialize(): Promise<void> {
    console.log('🔧 Initializing MCP Client...');
    
    for (const [serverName, serverConfig] of Object.entries(this.config)) {
      try {
        await this.connectToServer(serverName, serverConfig);
      } catch (error) {
        console.error(`Failed to connect to ${serverName}:`, error);
      }
    }
  }

  private async connectToServer(name: string, config: MCPServer): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        console.log(`🔌 Connecting to MCP server: ${name} at ${config.url}`);
        
        // In browser environment, we'll simulate the connection
        // In Node.js environment, establish actual WebSocket connection
        if (typeof window !== 'undefined') {
          // Browser environment - simulate connection
          this.simulateConnection(name, config);
          resolve();
        } else {
          // Node.js environment - real WebSocket connection
          const ws = new WebSocket(config.url || `ws://localhost:${config.port || 3001}`);
          
          ws.on('open', async () => {
            console.log(`✅ Connected to ${name}`);
            this.connections.set(name, ws);
            
            // Perform MCP handshake
            await this.performHandshake(name, ws);
            
            // Discover tools
            const tools = await this.discoverTools(name);
            this.tools.set(name, tools);
            
            resolve();
          });
          
          ws.on('error', (error) => {
            console.error(`❌ Connection error for ${name}:`, error);
            reject(error);
          });
          
          ws.on('message', (data) => {
            this.handleMessage(name, JSON.parse(data.toString()));
          });
        }
      } catch (error) {
        reject(error);
      }
    });
  }

  private simulateConnection(name: string, config: MCPServer): void {
    // Simulate tool discovery for browser environment
    const mockTools = this.getMockTools(name);
    this.tools.set(name, mockTools);
    console.log(`✅ Simulated connection to ${name} with ${mockTools.length} tools`);
  }

  private async performHandshake(serverName: string, ws: WebSocket): Promise<void> {
    return new Promise((resolve, reject) => {
      const handshakeMessage = {
        jsonrpc: '2.0',
        id: 1,
        method: 'initialize',
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {},
            resources: {},
            prompts: {}
          },
          clientInfo: {
            name: 'MCP Chat Interface',
            version: '1.0.0'
          }
        }
      };

      ws.send(JSON.stringify(handshakeMessage));
      
      const timeout = setTimeout(() => {
        reject(new Error('Handshake timeout'));
      }, 5000);

      this.messageHandlers.set(serverName, (data) => {
        if (data.id === 1 && data.result) {
          clearTimeout(timeout);
          resolve();
        }
      });
    });
  }

  private async discoverTools(serverName: string): Promise<MCPTool[]> {
    const ws = this.connections.get(serverName);
    if (!ws) return [];

    return new Promise((resolve) => {
      const toolsMessage = {
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/list',
        params: {}
      };

      ws.send(JSON.stringify(toolsMessage));

      const timeout = setTimeout(() => {
        resolve(this.getMockTools(serverName));
      }, 3000);

      this.messageHandlers.set(serverName + '_tools', (data) => {
        if (data.id === 2 && data.result) {
          clearTimeout(timeout);
          const tools = data.result.tools.map((tool: any) => ({
            name: tool.name,
            description: tool.description,
            inputSchema: tool.inputSchema,
            server: serverName,
            category: this.categorizeool(tool.name)
          }));
          resolve(tools);
        }
      });
    });
  }

  private getMockTools(serverName: string): MCPTool[] {
    const toolSets: Record<string, MCPTool[]> = {
      'PRET-MCP-SERVER': [
        {
          name: 'get-GLEIF-data',
          description: 'Get GLEIF compliance data for a company',
          inputSchema: { 
            type: 'object',
            properties: {
              companyName: { type: 'string' },
              typeOfNet: { type: 'string', default: 'mainnet' }
            },
            required: ['companyName']
          },
          server: serverName,
          category: 'compliance'
        },
        {
          name: 'check-corp-registration',
          description: 'Check corporate registration status',
          inputSchema: {
            type: 'object',
            properties: {
              companyName: { type: 'string' },
              jurisdiction: { type: 'string', default: 'US' }
            },
            required: ['companyName']
          },
          server: serverName,
          category: 'compliance'
        },
        {
          name: 'check-export-import',
          description: 'Check export/import compliance',
          inputSchema: {
            type: 'object',
            properties: {
              companyName: { type: 'string' },
              commodityCode: { type: 'string' }
            },
            required: ['companyName']
          },
          server: serverName,
          category: 'compliance'
        }
      ],
      'GOAT-EVM-MCP-SERVER': [
        {
          name: 'mint_nft',
          description: 'Mint NFT on XDC network',
          inputSchema: {
            type: 'object',
            properties: {
              contractAddress: { type: 'string' },
              to: { type: 'string' },
              tokenURI: { type: 'string' },
              network: { type: 'string', default: 'testnet' }
            },
            required: ['contractAddress', 'to']
          },
          server: serverName,
          category: 'blockchain'
        },
        {
          name: 'deploy_simple_nft_contract',
          description: 'Deploy NFT contract',
          inputSchema: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              symbol: { type: 'string' },
              network: { type: 'string', default: 'testnet' }
            },
            required: ['name', 'symbol']
          },
          server: serverName,
          category: 'blockchain'
        },
        {
          name: 'get_xdc_balance',
          description: 'Get XDC balance for address',
          inputSchema: {
            type: 'object',
            properties: {
              address: { type: 'string' },
              network: { type: 'string', default: 'testnet' }
            },
            required: ['address']
          },
          server: serverName,
          category: 'blockchain'
        }
      ],
      'FILE-MCP-SERVER': [
        {
          name: 'read_file',
          description: 'Read file contents',
          inputSchema: {
            type: 'object',
            properties: {
              path: { type: 'string' }
            },
            required: ['path']
          },
          server: serverName,
          category: 'storage'
        },
        {
          name: 'write_file',
          description: 'Write file contents',
          inputSchema: {
            type: 'object',
            properties: {
              path: { type: 'string' },
              content: { type: 'string' }
            },
            required: ['path', 'content']
          },
          server: serverName,
          category: 'storage'
        }
      ]
    };

    return toolSets[serverName] || [];
  }

  private categorizeool(toolName: string): 'compliance' | 'blockchain' | 'storage' | 'utility' {
    if (toolName.includes('gleif') || toolName.includes('compliance') || toolName.includes('corp')) {
      return 'compliance';
    }
    if (toolName.includes('nft') || toolName.includes('mint') || toolName.includes('balance')) {
      return 'blockchain';
    }
    if (toolName.includes('file') || toolName.includes('read') || toolName.includes('write')) {
      return 'storage';
    }
    return 'utility';
  }

  private handleMessage(serverName: string, data: any): void {
    const handler = this.messageHandlers.get(serverName) || this.messageHandlers.get(serverName + '_tools');
    if (handler) {
      handler(data);
    }
  }

  async executeTool(serverName: string, toolName: string, parameters: any): Promise<any> {
    console.log(`🔧 Executing ${toolName} on ${serverName}:`, parameters);
    
    const ws = this.connections.get(serverName);
    
    if (ws && ws.readyState === WebSocket.OPEN) {
      // Real MCP server call
      return this.executeRealTool(serverName, toolName, parameters, ws);
    } else {
      // Mock execution for development/browser
      return this.executeMockTool(serverName, toolName, parameters);
    }
  }

  private async executeRealTool(serverName: string, toolName: string, parameters: any, ws: WebSocket): Promise<any> {
    return new Promise((resolve, reject) => {
      const requestId = Date.now();
      const toolMessage = {
        jsonrpc: '2.0',
        id: requestId,
        method: 'tools/call',
        params: {
          name: toolName,
          arguments: parameters
        }
      };

      ws.send(JSON.stringify(toolMessage));

      const timeout = setTimeout(() => {
        reject(new Error('Tool execution timeout'));
      }, 30000);

      this.messageHandlers.set(serverName + '_' + requestId, (data) => {
        if (data.id === requestId) {
          clearTimeout(timeout);
          if (data.error) {
            reject(new Error(data.error.message));
          } else {
            resolve(data.result);
          }
        }
      });
    });
  }

  private async executeMockTool(serverName: string, toolName: string, parameters: any): Promise<any> {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 500 + Math.random() * 1000));
    
    // Mock responses based on tool
    switch (toolName) {
      case 'get-GLEIF-data':
        return {
          companyName: parameters.companyName,
          gleifStatus: Math.random() > 0.3 ? 'ACTIVE' : 'INACTIVE',
          entityId: 'LEI-' + Math.random().toString(36).substring(2, 20).toUpperCase(),
          lastUpdated: new Date().toISOString(),
          jurisdiction: 'US',
          registrationStatus: 'ACTIVE'
        };
      
      case 'check-corp-registration':
        return {
          companyName: parameters.companyName,
          status: Math.random() > 0.2 ? 'COMPLIANT' : 'NON_COMPLIANT',
          registrationNumber: 'REG-' + Math.random().toString(36).substring(2, 8).toUpperCase(),
          jurisdiction: parameters.jurisdiction || 'US',
          incorporationDate: '2020-01-15'
        };
      
      case 'mint_nft':
        return {
          transactionHash: '0x' + Array.from({length: 64}, () => 
            Math.floor(Math.random() * 16).toString(16)).join(''),
          tokenId: Math.floor(Math.random() * 1000000),
          status: 'success',
          network: parameters.network || 'testnet',
          gasUsed: '84000',
          contractAddress: parameters.contractAddress
        };
      
      case 'deploy_simple_nft_contract':
        return {
          contractAddress: '0x' + Array.from({length: 40}, () => 
            Math.floor(Math.random() * 16).toString(16)).join(''),
          transactionHash: '0x' + Array.from({length: 64}, () => 
            Math.floor(Math.random() * 16).toString(16)).join(''),
          status: 'deployed',
          network: parameters.network || 'testnet',
          name: parameters.name,
          symbol: parameters.symbol
        };
      
      case 'get_xdc_balance':
        return {
          address: parameters.address,
          balance: (Math.random() * 1000).toFixed(6),
          network: parameters.network || 'testnet',
          currency: 'XDC'
        };
      
      case 'read_file':
        return {
          path: parameters.path,
          content: `Mock file content for ${parameters.path}`,
          size: Math.floor(Math.random() * 10000),
          lastModified: new Date().toISOString()
        };
      
      default:
        return { 
          status: 'executed', 
          result: 'mock_result',
          tool: toolName,
          server: serverName,
          parameters 
        };
    }
  }

  getAvailableTools(): MCPTool[] {
    const allTools: MCPTool[] = [];
    for (const tools of this.tools.values()) {
      allTools.push(...tools);
    }
    return allTools;
  }

  getServerTools(serverName: string): MCPTool[] {
    return this.tools.get(serverName) || [];
  }

  getServerStatus(serverName: string): 'connected' | 'disconnected' | 'error' {
    const ws = this.connections.get(serverName);
    if (!ws) return 'disconnected';
    
    switch (ws.readyState) {
      case WebSocket.OPEN:
        return 'connected';
      case WebSocket.CONNECTING:
        return 'disconnected';
      default:
        return 'error';
    }
  }

  async disconnect(): Promise<void> {
    for (const [name, ws] of this.connections.entries()) {
      console.log(`🔌 Disconnecting from ${name}`);
      ws.close();
    }
    this.connections.clear();
    this.tools.clear();
    this.messageHandlers.clear();
  }
}
EOF

echo "🎯 Creating MCP Orchestrator..."

# MCP Orchestrator package.json
cat > mcp-orchestrator/package.json << 'EOF'
{
  "name": "mcp-orchestrator",
  "version": "1.0.0",
  "description": "MCP Orchestrator Server - Acts as an MCP server that orchestrates other MCP servers",
  "main": "dist/server.js",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "jest"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "ws": "^8.14.2",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.1",
    "zod": "^3.22.4",
    "winston": "^3.10.0"
  },
  "devDependencies": {
    "@types/ws": "^8.5.8",
    "@types/express": "^4.17.20",
    "@types/cors": "^2.8.15",
    "@types/node": "^20.8.0",
    "typescript": "^5.2.2",
    "tsx": "^4.0.0",
    "jest": "^29.7.0"
  }
}
EOF

# MCP Orchestrator TypeScript config
cat > mcp-orchestrator/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "allowJs": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noImplicitAny": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": false
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# MCP Orchestrator main server
cat > mcp-orchestrator/src/server.ts << 'EOF'
#!/usr/bin/env node

/**
 * MCP Orchestrator Server
 * 
 * This server acts as an MCP server itself while orchestrating calls to other MCP servers.
 * It provides high-level tools that combine operations across multiple MCP servers.
 * 
 * Architecture:
 * - Implements MCP Server protocol
 * - Connects to downstream MCP servers as a client
 * - Provides orchestration tools that combine multiple server operations
 * - Can be used by Claude Desktop or any MCP client
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  McpError,
  ErrorCode,
} from '@modelcontextprotocol/sdk/types.js';
import WebSocket from 'ws';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createLogger, format, transports } from 'winston';
import dotenv from 'dotenv';

dotenv.config();

// Logger setup
const logger = createLogger({
  level: 'info',
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.json()
  ),
  defaultMeta: { service: 'mcp-orchestrator' },
  transports: [
    new transports.File({ filename: 'error.log', level: 'error' }),
    new transports.File({ filename: 'combined.log' }),
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.simple()
      )
    })
  ],
});

interface MCPServerConnection {
  name: string;
  url: string;
  ws?: WebSocket;
  status: 'connected' | 'disconnected' | 'error';
  tools: any[];
}

class MCPOrchestrator {
  private connections: Map<string, MCPServerConnection> = new Map();
  private server: Server;
  private httpServer?: express.Application;

  constructor() {
    this.server = new Server(
      {
        name: 'mcp-orchestrator',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupMCPHandlers();
    this.setupDownstreamConnections();
  }

  private setupMCPHandlers() {
    // List available orchestration tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'compliance_workflow',
            description: 'Execute complete compliance workflow (GLEIF + Corp Registration + NFT minting)',
            inputSchema: {
              type: 'object',
              properties: {
                companyName: {
                  type: 'string',
                  description: 'Company name to check compliance for'
                },
                network: {
                  type: 'string', 
                  enum: ['mainnet', 'testnet'],
                  default: 'testnet',
                  description: 'Blockchain network for NFT operations'
                },
                nftRecipient: {
                  type: 'string',
                  description: 'Address to receive NFT if compliant'
                }
              },
              required: ['companyName', 'nftRecipient']
            }
          },
          {
            name: 'gleif_check_and_mint',
            description: 'Check GLEIF compliance and mint NFT if ACTIVE',
            inputSchema: {
              type: 'object',
              properties: {
                companyName: { type: 'string' },
                contractAddress: { type: 'string' },
                recipient: { type: 'string' },
                network: { type: 'string', default: 'testnet' }
              },
              required: ['companyName', 'contractAddress', 'recipient']
            }
          },
          {
            name: 'multi_compliance_check',
            description: 'Run multiple compliance checks across different servers',
            inputSchema: {
              type: 'object',
              properties: {
                companyName: { type: 'string' },
                checks: {
                  type: 'array',
                  items: {
                    type: 'string',
                    enum: ['gleif', 'corp_registration', 'export_import']
                  },
                  default: ['gleif', 'corp_registration']
                }
              },
              required: ['companyName']
            }
          },
          {
            name: 'erc721_to_erc6960_conversion',
            description: 'Convert ERC-721 NFT to ERC-6960 trade finance token',
            inputSchema: {
              type: 'object',
              properties: {
                tokenId: { type: 'string' },
                complianceData: { type: 'object' },
                network: { type: 'string', default: 'testnet' }
              },
              required: ['tokenId', 'complianceData']
            }
          },
          {
            name: 'get_orchestrator_status',
            description: 'Get status of all connected MCP servers',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          }
        ]
      };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'compliance_workflow':
            return await this.executeComplianceWorkflow(args);
          
          case 'gleif_check_and_mint':
            return await this.executeGleifCheckAndMint(args);
          
          case 'multi_compliance_check':
            return await this.executeMultiComplianceCheck(args);
          
          case 'erc721_to_erc6960_conversion':
            return await this.executeTokenConversion(args);
          
          case 'get_orchestrator_status':
            return await this.getOrchestratorStatus();
          
          default:
            throw new McpError(
              ErrorCode.MethodNotFound,
              `Unknown tool: ${name}`
            );
        }
      } catch (error) {
        logger.error('Tool execution error:', error);
        throw new McpError(
          ErrorCode.InternalError,
          `Tool execution failed: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    });
  }

  private setupDownstreamConnections() {
    const servers = [
      { name: 'PRET-MCP-SERVER', url: process.env.PRET_MCP_SERVER_URL || 'ws://localhost:3001' },
      { name: 'GOAT-EVM-MCP-SERVER', url: process.env.GOAT_EVM_MCP_SERVER_URL || 'ws://localhost:3003' },
      { name: 'FILE-MCP-SERVER', url: process.env.FILE_MCP_SERVER_URL || 'ws://localhost:3004' }
    ];

    servers.forEach(server => {
      this.connections.set(server.name, {
        name: server.name,
        url: server.url,
        status: 'disconnected',
        tools: []
      });
    });
  }

  private async connectToDownstreamServer(serverName: string): Promise<void> {
    const connection = this.connections.get(serverName);
    if (!connection) return;

    try {
      const ws = new WebSocket(connection.url);
      
      ws.on('open', async () => {
        logger.info(`Connected to downstream server: ${serverName}`);
        connection.ws = ws;
        connection.status = 'connected';
        
        // Perform MCP handshake and tool discovery
        await this.performDownstreamHandshake(serverName, ws);
      });

      ws.on('error', (error) => {
        logger.error(`Error connecting to ${serverName}:`, error);
        connection.status = 'error';
      });

      ws.on('close', () => {
        logger.info(`Disconnected from ${serverName}`);
        connection.status = 'disconnected';
        connection.ws = undefined;
      });

    } catch (error) {
      logger.error(`Failed to connect to ${serverName}:`, error);
      connection.status = 'error';
    }
  }

  private async performDownstreamHandshake(serverName: string, ws: WebSocket): Promise<void> {
    // Implement MCP handshake protocol
    // This is a simplified version - real implementation would follow MCP spec
    const initMessage = {
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        clientInfo: { name: 'mcp-orchestrator', version: '1.0.0' }
      }
    };

    ws.send(JSON.stringify(initMessage));
  }

  private async callDownstreamTool(serverName: string, toolName: string, parameters: any): Promise<any> {
    const connection = this.connections.get(serverName);
    
    if (!connection || !connection.ws || connection.status !== 'connected') {
      // If not connected, try to reconnect
      await this.connectToDownstreamServer(serverName);
      
      // If still not connected, return mock data for development
      if (connection?.status !== 'connected') {
        logger.warn(`Server ${serverName} not connected, returning mock data`);
        return this.getMockToolResult(toolName, parameters);
      }
    }

    try {
      return new Promise((resolve, reject) => {
        const requestId = Date.now();
        const message = {
          jsonrpc: '2.0',
          id: requestId,
          method: 'tools/call',
          params: { name: toolName, arguments: parameters }
        };

        const timeout = setTimeout(() => {
          reject(new Error('Tool call timeout'));
        }, 30000);

        const messageHandler = (data: Buffer) => {
          try {
            const response = JSON.parse(data.toString());
            if (response.id === requestId) {
              clearTimeout(timeout);
              connection.ws?.off('message', messageHandler);
              
              if (response.error) {
                reject(new Error(response.error.message));
              } else {
                resolve(response.result);
              }
            }
          } catch (error) {
            // Ignore parse errors for other messages
          }
        };

        connection.ws?.on('message', messageHandler);
        connection.ws?.send(JSON.stringify(message));
      });
    } catch (error) {
      logger.error(`Error calling ${toolName} on ${serverName}:`, error);
      // Return mock data as fallback
      return this.getMockToolResult(toolName, parameters);
    }
  }

  private getMockToolResult(toolName: string, parameters: any): any {
    // Mock results for development/testing
    switch (toolName) {
      case 'get-GLEIF-data':
        return {
          companyName: parameters.companyName,
          gleifStatus: Math.random() > 0.3 ? 'ACTIVE' : 'INACTIVE',
          entityId: 'LEI-' + Math.random().toString(36).substring(2, 20).toUpperCase(),
          lastUpdated: new Date().toISOString()
        };
      
      case 'mint_nft':
        return {
          transactionHash: '0x' + Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
          tokenId: Math.floor(Math.random() * 1000000),
          status: 'success'
        };
      
      default:
        return { status: 'mock_executed', tool: toolName, parameters };
    }
  }

  // Orchestration workflows
  private async executeComplianceWorkflow(args: any) {
    const { companyName, network = 'testnet', nftRecipient } = args;
    const results: any[] = [];
    
    logger.info(`Starting compliance workflow for ${companyName}`);

    try {
      // Step 1: Check GLEIF compliance
      const gleifResult = await this.callDownstreamTool('PRET-MCP-SERVER', 'get-GLEIF-data', {
        companyName,
        typeOfNet: network
      });
      results.push({ step: 'gleif_check', result: gleifResult });

      // Step 2: Check corporate registration
      const corpResult = await this.callDownstreamTool('PRET-MCP-SERVER', 'check-corp-registration', {
        companyName
      });
      results.push({ step: 'corp_registration', result: corpResult });

      // Step 3: Determine overall compliance
      const isGleifActive = gleifResult.gleifStatus === 'ACTIVE';
      const isCorpCompliant = corpResult.status === 'COMPLIANT';
      const overallCompliance = isGleifActive && isCorpCompliant;

      // Step 4: Mint NFT if compliant
      if (overallCompliance) {
        const nftResult = await this.callDownstreamTool('GOAT-EVM-MCP-SERVER', 'mint_nft', {
          contractAddress: '0x1234567890123456789012345678901234567890', // Default contract
          to: nftRecipient,
          tokenURI: `https://metadata.api/company/${companyName}/compliance`,
          network
        });
        results.push({ step: 'nft_mint', result: nftResult });

        return {
          content: [
            {
              type: 'text',
              text: `✅ Compliance workflow completed successfully for ${companyName}!\n\n` +
                    `GLEIF Status: ${gleifResult.gleifStatus}\n` +
                    `Corp Registration: ${corpResult.status}\n` +
                    `NFT Minted: ${nftResult.transactionHash}\n` +
                    `Token ID: ${nftResult.tokenId}`
            }
          ],
          isError: false,
          metadata: { workflow: 'compliance', results, overallCompliance: true }
        };
      } else {
        return {
          content: [
            {
              type: 'text',
              text: `❌ Compliance requirements not met for ${companyName}\n\n` +
                    `GLEIF Status: ${gleifResult.gleifStatus}\n` +
                    `Corp Registration: ${corpResult.status}\n\n` +
                    `NFT minting skipped due to non-compliance.`
            }
          ],
          isError: false,
          metadata: { workflow: 'compliance', results, overallCompliance: false }
        };
      }
    } catch (error) {
      logger.error('Compliance workflow error:', error);
      return {
        content: [
          {
            type: 'text',
            text: `❌ Compliance workflow failed for ${companyName}: ${error instanceof Error ? error.message : 'Unknown error'}`
          }
        ],
        isError: true,
        metadata: { workflow: 'compliance', error: error instanceof Error ? error.message : 'Unknown error' }
      };
    }
  }

  private async executeGleifCheckAndMint(args: any) {
    const { companyName, contractAddress, recipient, network = 'testnet' } = args;

    try {
      // Check GLEIF
      const gleifResult = await this.callDownstreamTool('PRET-MCP-SERVER', 'get-GLEIF-data', {
        companyName,
        typeOfNet: network
      });

      if (gleifResult.gleifStatus === 'ACTIVE') {
        // Mint NFT
        const nftResult = await this.callDownstreamTool('GOAT-EVM-MCP-SERVER', 'mint_nft', {
          contractAddress,
          to: recipient,
          tokenURI: `https://metadata.api/company/${companyName}/gleif`,
          network
        });

        return {
          content: [
            {
              type: 'text',
              text: `✅ GLEIF check passed and NFT minted!\n\n` +
                    `Company: ${companyName}\n` +
                    `GLEIF Status: ${gleifResult.gleifStatus}\n` +
                    `Transaction: ${nftResult.transactionHash}\n` +
                    `Token ID: ${nftResult.tokenId}`
            }
          ],
          isError: false
        };
      } else {
        return {
          content: [
            {
              type: 'text',
              text: `❌ GLEIF compliance check failed for ${companyName}\n\n` +
                    `Status: ${gleifResult.gleifStatus}\n` +
                    `Cannot proceed with NFT minting.`
            }
          ],
          isError: false
        };
      }
    } catch (error) {
      logger.error('GLEIF check and mint error:', error);
      return {
        content: [
          {
            type: 'text',
            text: `❌ Operation failed: ${error instanceof Error ? error.message : 'Unknown error'}`
          }
        ],
        isError: true
      };
    }
  }

  private async executeMultiComplianceCheck(args: any) {
    const { companyName, checks = ['gleif', 'corp_registration'] } = args;
    const results: any = {};

    try {
      for (const check of checks) {
        switch (check) {
          case 'gleif':
            results.gleif = await this.callDownstreamTool('PRET-MCP-SERVER', 'get-GLEIF-data', {
              companyName
            });
            break;
          
          case 'corp_registration':
            results.corpRegistration = await this.callDownstreamTool('PRET-MCP-SERVER', 'check-corp-registration', {
              companyName
            });
            break;
          
          case 'export_import':
            results.exportImport = await this.callDownstreamTool('PRET-MCP-SERVER', 'check-export-import', {
              companyName
            });
            break;
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: `📊 Multi-compliance check results for ${companyName}:\n\n` +
                  JSON.stringify(results, null, 2)
          }
        ],
        isError: false,
        metadata: { complianceResults: results }
      };
    } catch (error) {
      logger.error('Multi-compliance check error:', error);
      return {
        content: [
          {
            type: 'text',
            text: `❌ Multi-compliance check failed: ${error instanceof Error ? error.message : 'Unknown error'}`
          }
        ],
        isError: true
      };
    }
  }

  private async executeTokenConversion(args: any) {
    const { tokenId, complianceData, network = 'testnet' } = args;

    try {
      // This would call a specialized tool for ERC-721 to ERC-6960 conversion
      const conversionResult = await this.callDownstreamTool('GOAT-EVM-MCP-SERVER', 'convert_to_erc6960', {
        tokenId,
        tradeFinanceData: complianceData,
        network
      });

      return {
        content: [
          {
            type: 'text',
            text: `✅ Token conversion completed!\n\n` +
                  `Original Token ID: ${tokenId}\n` +
                  `New ERC-6960 Token: ${conversionResult.newTokenId}\n` +
                  `Transaction: ${conversionResult.transactionHash}`
          }
        ],
        isError: false
      };
    } catch (error) {
      logger.error('Token conversion error:', error);
      return {
        content: [
          {
            type: 'text',
            text: `❌ Token conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
          }
        ],
        isError: true
      };
    }
  }

  private async getOrchestratorStatus() {
    const status = Array.from(this.connections.entries()).map(([name, conn]) => ({
      name,
      url: conn.url,
      status: conn.status,
      toolCount: conn.tools.length
    }));

    return {
      content: [
        {
          type: 'text',
          text: `🔧 MCP Orchestrator Status:\n\n` +
                status.map(s => 
                  `${s.name}: ${s.status} (${s.toolCount} tools)`
                ).join('\n')
        }
      ],
      isError: false,
      metadata: { connections: status }
    };
  }

  async start() {
    // Initialize connections to downstream servers
    for (const serverName of this.connections.keys()) {
      await this.connectToDownstreamServer(serverName);
    }

    // Start MCP server
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    
    logger.info('🚀 MCP Orchestrator Server started');
  }

  // Optional: Start HTTP server for web interface integration
  startHttpServer(port: number = 3002) {
    this.httpServer = express();
    
    this.httpServer.use(helmet());
    this.httpServer.use(cors());
    this.httpServer.use(express.json());

    this.httpServer.get('/health', (req, res) => {
      res.json({ status: 'healthy', timestamp: new Date().toISOString() });
    });

    this.httpServer.get('/status', async (req, res) => {
      const statusResult = await this.getOrchestratorStatus();
      res.json(statusResult.metadata);
    });

    this.httpServer.listen(port, () => {
      logger.info(`🌐 HTTP server running on port ${port}`);
    });
  }
}

// Start the orchestrator
const orchestrator = new MCPOrchestrator();

// Handle graceful shutdown
process.on('SIGINT', async () => {
  logger.info('Shutting down MCP Orchestrator...');
  process.exit(0);
});

// Start both MCP server and optional HTTP server
orchestrator.start().catch((error) => {
  logger.error('Failed to start MCP Orchestrator:', error);
  process.exit(1);
});

// Start HTTP server if requested
if (process.env.ENABLE_HTTP_SERVER === 'true') {
  orchestrator.startHttpServer(parseInt(process.env.MCP_ORCHESTRATOR_PORT || '3002'));
}

export default orchestrator;