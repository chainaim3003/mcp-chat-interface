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
  onSuccess?: string;
  onFailure?: string;
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
