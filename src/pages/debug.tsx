// src/pages/debug.tsx
// Debug page for MCP system

import { useState, useEffect } from 'react';

export default function DebugPage() {
  const [debugInfo, setDebugInfo] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [testResult, setTestResult] = useState<any>(null);
  const [testForm, setTestForm] = useState({
    serverName: '',
    toolName: '',
    args: '{}'
  });

  const loadDebugInfo = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/debug/mcp-tools');
      const data = await response.json();
      setDebugInfo(data.debugInfo);
    } catch (error) {
      console.error('Debug load error:', error);
    } finally {
      setLoading(false);
    }
  };

  const testTool = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/debug/test-server', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          serverName: testForm.serverName,
          toolName: testForm.toolName,
          args: JSON.parse(testForm.args)
        })
      });
      const data = await response.json();
      setTestResult(data);
    } catch (error) {
      setTestResult({ error: error.message });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDebugInfo();
  }, []);

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">MCP System Debug</h1>
      
      <button 
        onClick={loadDebugInfo}
        disabled={loading}
        className="mb-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? 'Loading...' : 'Refresh Debug Info'}
      </button>

      {debugInfo && (
        <div className="space-y-6">
          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-2">System Status</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>MCP Initialized:</strong> {debugInfo.mcpInitialized ? '✅' : '❌'}
              </div>
              <div>
                <strong>Total Tools:</strong> {debugInfo.toolSummary.totalTools}
              </div>
              <div>
                <strong>Configured Servers:</strong> {debugInfo.totalServersConfigured}
              </div>
              <div>
                <strong>Running Servers:</strong> {debugInfo.runningServers}
              </div>
            </div>
          </div>

          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-2">Server Details</h2>
            <div className="space-y-4">
              {Object.entries(debugInfo.serverDetails).map(([name, details]: [string, any]) => (
                <div key={name} className="border p-3 rounded">
                  <h3 className="font-medium">{name}</h3>
                  <div className="grid grid-cols-3 gap-2 text-sm mt-2">
                    <div><strong>Status:</strong> {details.status}</div>
                    <div><strong>PID:</strong> {details.pid || 'N/A'}</div>
                    <div><strong>Tools:</strong> {details.toolCount}</div>
                  </div>
                  {details.tools && details.tools.length > 0 && (
                    <div className="mt-2">
                      <strong>Available Tools:</strong>
                      <ul className="list-disc list-inside ml-4">
                        {details.tools.map((tool: string) => (
                          <li key={tool}>{tool}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {details.error && (
                    <div className="mt-2 text-red-600">
                      <strong>Error:</strong> {details.error}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="bg-gray-100 p-4 rounded">
            <h2 className="text-lg font-semibold mb-4">Test Individual Tool</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Server Name</label>
                  <select 
                    value={testForm.serverName}
                    onChange={(e) => setTestForm({...testForm, serverName: e.target.value})}
                    className="w-full p-2 border rounded"
                  >
                    <option value="">Select Server</option>
                    {Object.keys(debugInfo.serverDetails).map(name => (
                      <option key={name} value={name}>{name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Tool Name</label>
                  <select 
                    value={testForm.toolName}
                    onChange={(e) => setTestForm({...testForm, toolName: e.target.value})}
                    className="w-full p-2 border rounded"
                    disabled={!testForm.serverName}
                  >
                    <option value="">Select Tool</option>
                    {testForm.serverName && debugInfo.serverDetails[testForm.serverName]?.tools?.map((tool: string) => (
                      <option key={tool} value={tool}>{tool}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Arguments (JSON)</label>
                <textarea
                  value={testForm.args}
                  onChange={(e) => setTestForm({...testForm, args: e.target.value})}
                  className="w-full p-2 border rounded h-20"
                  placeholder='{"key": "value"}'
                />
              </div>
              <button
                onClick={testTool}
                disabled={loading || !testForm.serverName || !testForm.toolName}
                className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
              >
                Test Tool
              </button>
            </div>
            
            {testResult && (
              <div className="mt-4 p-3 bg-white rounded border">
                <h3 className="font-medium mb-2">Test Result:</h3>
                <pre className="text-sm overflow-auto">{JSON.stringify(testResult, null, 2)}</pre>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
