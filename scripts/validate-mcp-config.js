#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

function validateConfig() {
    const configPath = path.join(process.cwd(), 'claude_mcp_config.json');
    
    try {
        if (!fs.existsSync(configPath)) {
            console.error('❌ claude_mcp_config.json not found');
            process.exit(1);
        }
        
        const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
        
        if (!config.mcpServers) {
            console.error('❌ Missing mcpServers section');
            process.exit(1);
        }
        
        let serverCount = 0;
        let enabledCount = 0;
        
        for (const [name, server] of Object.entries(config.mcpServers)) {
            serverCount++;
            if (!server.disabled) {
                enabledCount++;
            }
            
            if (!server.command) {
                console.error(`❌ Server '${name}' missing command`);
                process.exit(1);
            }
        }
        
        console.log('✅ Configuration is valid');
        console.log(`📊 Found ${serverCount} servers (${enabledCount} enabled)`);
        
        // List servers
        console.log('\nConfigured servers:');
        for (const [name, server] of Object.entries(config.mcpServers)) {
            const status = server.disabled ? '(disabled)' : '(enabled)';
            console.log(`  - ${name} ${status}`);
        }
        
    } catch (error) {
        console.error('❌ Configuration validation failed:', error.message);
        process.exit(1);
    }
}

validateConfig();
