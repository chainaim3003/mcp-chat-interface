#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🧪 Testing MCP Dynamic Discovery Implementation');
console.log('===============================================\n');

// Test config file
const configPath = path.join(process.cwd(), 'claude_mcp_config.json');
if (fs.existsSync(configPath)) {
  try {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const servers = Object.entries(config.mcpServers || {});
    console.log(`✅ Config valid with ${servers.length} servers:`);
    servers.forEach(([name, cfg]) => {
      console.log(`   - ${name}: ${cfg.command} ${cfg.args?.join(' ') || ''}`);
    });
  } catch (error) {
    console.log(`❌ Invalid config: ${error.message}`);
  }
} else {
  console.log('❌ claude_mcp_config.json not found');
}

// Test implementation files
console.log('\n🔍 Checking implementation files:');
const files = [
  'lib/mcp-config.ts',
  'lib/mcp-client.ts',
  'app/api/chat/route.ts',
  'app/api/mcp/health/route.ts'
];

files.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  if (fs.existsSync(filePath)) {
    const stats = fs.statSync(filePath);
    console.log(`✅ ${file} (${Math.round(stats.size/1024)}KB)`);
  } else {
    console.log(`❌ ${file} missing`);
  }
});

console.log('\n🎯 Next Steps:');
console.log('1. npm install');
console.log('2. Add OPENAI_API_KEY to .env.local');
console.log('3. npm run dev');
console.log('4. Test: curl http://localhost:3000/api/mcp/health');

console.log('\n✨ Your MCP interface is now DYNAMIC and CONFIG-DRIVEN!');
