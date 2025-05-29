#!/usr/bin/env node
const { initializeMCP, getMCPStatus, shutdownMCP } = require('../src/lib/mcp-integration');

async function checkStatus() {
    try {
        console.log('🔄 Checking MCP system status...');
        
        await initializeMCP();
        const status = getMCPStatus();
        
        console.log('\n📊 MCP System Status:');
        console.log(`Initialized: ${status.initialized ? '✅' : '❌'}`);
        
        if (status.servers) {
            console.log('\n🖥️ Server Status:');
            for (const [name, server] of Object.entries(status.servers)) {
                const statusIcon = server.status === 'running' ? '✅' : 
                                  server.status === 'error' ? '❌' : '⏸️';
                console.log(`  ${statusIcon} ${name}: ${server.status} (PID: ${server.pid || 'N/A'})`);
                
                if (server.tools && server.tools.length > 0) {
                    console.log(`    Tools: ${server.tools.join(', ')}`);
                }
                
                if (server.error) {
                    console.log(`    Error: ${server.error}`);
                }
            }
        }
        
        await shutdownMCP();
        console.log('\n✅ Status check completed');
        
    } catch (error) {
        console.error('❌ Status check failed:', error);
        process.exit(1);
    }
}

checkStatus();
