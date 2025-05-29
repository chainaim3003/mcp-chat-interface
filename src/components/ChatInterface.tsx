// src/components/ChatInterface.tsx
'use client';

import { useState, useRef, useEffect } from 'react';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export default function ChatInterface() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [apiStatus, setApiStatus] = useState<string>('checking...');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Test API connection on load
  useEffect(() => {
    const testAPI = async () => {
      try {
        const response = await fetch('/api/test-chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ test: 'connection' })
        });
        const data = await response.json();
        setApiStatus(data.success ? 'API Connected ✅' : 'API Error ❌');
        
        // Load initial welcome
        await loadWelcome();
      } catch (error) {
        setApiStatus('API Failed ❌');
        console.error('API test failed:', error);
      }
    };
    
    testAPI();
  }, []);

  const loadWelcome = async () => {
    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: 'hello' }),
      });
      
      const data = await response.json();
      console.log('Welcome API response:', data);
      
      if (data.success) {
        setMessages([{
          id: '1',
          role: 'assistant',
          content: data.response,
          timestamp: new Date()
        }]);
      } else {
        setMessages([{
          id: '1',
          role: 'assistant', 
          content: `API Error: ${data.error || 'Unknown error'}`,
          timestamp: new Date()
        }]);
      }
    } catch (error) {
      console.error('Failed to load welcome:', error);
      setMessages([{
        id: '1',
        role: 'assistant',
        content: `Connection Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date()
      }]);
    }
  };

  const sendMessage = async () => {
    if (!inputValue.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = inputValue;
    setInputValue('');
    setIsLoading(true);

    try {
      console.log('Sending message to /api/chat:', currentInput);
      
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: currentInput,
          history: messages
        }),
      });

      console.log('Chat API response status:', response.status);
      const data = await response.json();
      console.log('Chat API response data:', data);

      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: data.success ? data.response : (data.fallbackResponse || data.error || 'API Error'),
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);

    } catch (error) {
      console.error('Chat error:', error);
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: `Connection Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="flex flex-col h-screen max-w-6xl mx-auto bg-white">
      {/* Header with API status */}
      <div className="bg-blue-600 text-white p-4 shadow-md">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-xl font-bold">MCP Chat Interface (Debug Mode)</h1>
            <p className="text-blue-100 text-sm">Dynamic MCP Integration Test</p>
          </div>
          <div className="text-right text-sm">
            <div className="text-blue-100">API Status: {apiStatus}</div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-2xl px-4 py-3 rounded-lg ${
                message.role === 'user'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-800 border'
              }`}
            >
              <div className="whitespace-pre-wrap text-sm">{message.content}</div>
              <div className={`text-xs mt-2 ${
                message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
              }`}>
                {message.timestamp.toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}
        
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-yellow-100 text-yellow-800 px-4 py-3 rounded-lg border">
              <div className="flex items-center space-x-2">
                <div className="animate-spin h-4 w-4 border-2 border-yellow-400 border-t-transparent rounded-full"></div>
                <span>Calling dynamic MCP API...</span>
              </div>
            </div>
          </div>
        )}
        
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="border-t p-4">
        <div className="flex space-x-2">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Type your message... (Try: 'list servers and tools')"
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
          <button
            onClick={sendMessage}
            disabled={isLoading || !inputValue.trim()}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            Send
          </button>
        </div>
        
        {/* Debug buttons */}
        <div className="flex flex-wrap gap-2 mt-2">
          <button
            onClick={() => setInputValue('list servers and tools')}
            className="px-3 py-1 text-sm bg-green-100 hover:bg-green-200 rounded-full text-green-700"
          >
            Test: List Tools
          </button>
          <button
            onClick={() => setInputValue('system status')}
            className="px-3 py-1 text-sm bg-blue-100 hover:bg-blue-200 rounded-full text-blue-700"
          >
            Test: System Status
          </button>
          <button
            onClick={() => setInputValue('Check GLEIF compliance for Test Company')}
            className="px-3 py-1 text-sm bg-purple-100 hover:bg-purple-200 rounded-full text-purple-700"
          >
            Test: GLEIF Check
          </button>
        </div>
      </div>
    </div>
  );
}
