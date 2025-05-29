"use strict";(()=>{var e={};e.id=170,e.ids=[170],e.modules={5142:e=>{e.exports=require("dotenv")},145:e=>{e.exports=require("next/dist/compiled/next-server/pages-api.runtime.prod.js")},4195:e=>{e.exports=import("@modelcontextprotocol/sdk/client/index.js")},1646:e=>{e.exports=import("@modelcontextprotocol/sdk/client/stdio.js")},2081:e=>{e.exports=require("child_process")},2361:e=>{e.exports=require("events")},7147:e=>{e.exports=require("fs")},3292:e=>{e.exports=require("fs/promises")},1017:e=>{e.exports=require("path")},2087:(e,t,r)=>{r.r(t),r.d(t,{config:()=>c,default:()=>a,routeModule:()=>u});var s={};r.r(s),r.d(s,{default:()=>handler});var n=r(1802),o=r(7153),i=r(6249),l=r(9927);async function handler(e,t){if("POST"!==e.method)return t.status(405).json({error:"Method not allowed"});try{let{message:r,history:s=[]}=e.body;if(!r||"string"!=typeof r)return t.status(400).json({error:"Message is required"});console.log("\uD83D\uDCAC Processing chat message:",r),console.log("\uD83D\uDD27 Initializing MCP system..."),await (0,l.$h)();let n=(0,l.dV)(),o=(0,l.sw)(),i=l.hT.getConfig();console.log("\uD83D\uDCCA MCP Status:",{initialized:n.initialized,serverCount:Object.keys(o).length,runningServers:n.servers?Object.keys(n.servers).filter(e=>"running"===n.servers[e].status):[]});let a=await processMessageWithLogging(r,n,o,i);t.status(200).json({success:!0,response:a,mcpStatus:{initialized:n.initialized,availableServers:Object.keys(o),runningServers:n.servers?Object.entries(n.servers).filter(([e,t])=>"running"===t.status).map(([e,t])=>({name:e,status:t.status,tools:t.tools||[],toolCount:(t.tools||[]).length,uptime:t.uptime||0})):[]},debugInfo:{messageProcessed:r,timestamp:new Date().toISOString(),processingMethod:"dynamic"}})}catch(e){console.error("❌ Chat API error:",e),t.status(500).json({success:!1,error:e instanceof Error?e.message:"Unknown error",fallbackResponse:`I'm having trouble processing your request. Error: ${e instanceof Error?e.message:"Unknown error"}`})}}async function processMessageWithLogging(e,t,r,s){let n=e.toLowerCase();console.log("\uD83D\uDD0D Processing message:",e),console.log("\uD83D\uDDA5️ Available servers:",Object.keys(r)),console.log("\uD83C\uDFC3 Running servers:",t.servers?Object.keys(t.servers):[]);try{if(n.includes("list")&&(n.includes("server")||n.includes("tool")))return await listServersAndTools(t);if(n.includes("status")||n.includes("system"))return generateDetailedSystemStatus(t,r);if(n.includes("help")||"hi"===n||"hello"===n)return generateDynamicWelcome(t,r);if(n.includes("gleif")||n.includes("compliance"))return await handleGLEIFRequest(e,t);if(n.includes("wallet")||n.includes("address")||n.includes("balance"))return await handleWalletRequest(e,t);if(n.includes("nft")||n.includes("mint"))return await handleNFTRequest(e,t);if(n.includes("file")||n.includes("list")||n.includes("read"))return await handleFileRequest(e,t);return generateHelpfulResponse(t,r)}catch(e){return console.error("\uD83D\uDCA5 Error processing message:",e),`I encountered an error: ${e instanceof Error?e.message:"Unknown error"}`}}async function listServersAndTools(e){if(!e.initialized||!e.servers)return"❌ MCP system not initialized. No servers available.";let t=Object.entries(e.servers),r=t.filter(([e,t])=>"running"===t.status);if(0===r.length)return"❌ No MCP servers are currently running.";let s=`🖥️ **MCP Servers and Tools**

`,n=0;for(let[e,t]of r){let r=t.tools||[];s+=`**${e}** (${t.status})
`,t.pid&&(s+=`  PID: ${t.pid}
`),t.uptime&&(s+=`  Uptime: ${Math.round(t.uptime/1e3)}s
`),r.length>0?(s+=`  Tools (${r.length}):
`,r.forEach(e=>{s+=`    • ${e}
`,n++})):s+=`  No tools available
`,s+=`
`}return s+=`📊 **Summary:** ${r.length} servers, ${n} total tools`}function generateDetailedSystemStatus(e,t){let r=`🚀 **Detailed MCP System Status**

`;if(r+=`**System:** ${e.initialized?"✅ Initialized":"❌ Not Initialized"}
**Configured Servers:** ${Object.keys(t).length}
`,e.servers){let t=Object.entries(e.servers),s=t.filter(([e,t])=>"running"===t.status).length,n=t.filter(([e,t])=>"error"===t.status).length;for(let[e,o]of(r+=`**Running Servers:** ${s}
**Error Servers:** ${n}

**Server Details:**
`,t)){let t="running"===o.status?"✅":"error"===o.status?"❌":"starting"===o.status?"\uD83D\uDD04":"⏸️";r+=`  ${t} **${e}**: ${o.status}`,o.pid&&(r+=` (PID: ${o.pid})`),o.tools&&(r+=` - ${o.tools.length} tools`),r+=`
`,o.error&&(r+=`    Error: ${o.error}
`),o.tools&&o.tools.length>0&&(r+=`    Tools: ${o.tools.join(", ")}
`)}}return r}function generateDynamicWelcome(e,t){let r=e.servers?Object.entries(e.servers).filter(([e,t])=>"running"===t.status):[],s=r.reduce((e,[t,r])=>e+(r.tools?r.tools.length:0),0),n=`🚀 **Welcome to MCP Chat Interface!**

`;if(n+=`I'm connected to **${r.length} MCP servers** with **${s} available tools**.

`,r.length>0){for(let[e,t]of(n+=`**Available Servers:**
`,r))n+=`• **${e}**: ${t.tools?t.tools.length:0} tools
`;n+=`
`}n+=`**Try these commands:**
- "list servers and tools"
- "system status"
`;let o=r.flatMap(([e,t])=>t.tools||[]);return(o.includes("get-GLEIF-data")||o.includes("check_gleif_compliance"))&&(n+=`- "Check GLEIF compliance for [company name]"
`),o.includes("get_xdc_balance")&&(n+=`- "What is my wallet address"
`),o.includes("mint_nft")&&(n+=`- "Mint NFT for [recipient]"
`),n+=`
What would you like me to help you with?`}async function handleGLEIFRequest(e,t){let r=Object.entries(t.servers||{}).filter(([e,t])=>{let r=t.tools||[];return r.includes("get-GLEIF-data")||r.includes("check_gleif_compliance")});if(0===r.length)return"❌ No GLEIF compliance servers are currently running.";let s="";for(let t of[/(?:for|of)\s+(.+?)(?:\s*$|\s+(?:company|corp|corporation|ltd|limited|inc|llc))/i,/compliance\s+(.+?)(?:\s*$)/i,/gleif\s+(.+?)(?:\s*$)/i]){let r=e.match(t);if(r){s=r[1].trim();break}}if(!s)return"Please specify a company name. Example: 'Check GLEIF compliance for Acme Corp'";try{let[e,t]=r[0],n=t.tools||[],o=`🔍 **Checking GLEIF compliance for "${s}"**

`;if(n.includes("get-GLEIF-data"))try{console.log(`Calling get-GLEIF-data for ${s}`);let t=await (0,l.tB)(e,"get-GLEIF-data",{companyName:s});o+=`**GLEIF Data:**
\`\`\`json
${JSON.stringify(t,null,2)}
\`\`\`

`,t&&"object"==typeof t&&(t.gleifStatus&&(o+=`**Status:** ${t.gleifStatus}
`),t.entityId&&(o+=`**Entity ID:** ${t.entityId}
`))}catch(e){o+=`**Error:** ${e instanceof Error?e.message:"Unknown error"}

`}if(n.includes("check_gleif_compliance"))try{console.log(`Calling check_gleif_compliance for ${s}`);let t=await (0,l.tB)(e,"check_gleif_compliance",{company_name:s});o+=`**Compliance Check:**
\`\`\`json
${JSON.stringify(t,null,2)}
\`\`\`
`}catch(e){o+=`**Compliance Check Error:** ${e instanceof Error?e.message:"Unknown error"}
`}return o}catch(e){return`❌ Error checking GLEIF compliance: ${e instanceof Error?e.message:"Unknown error"}`}}async function handleWalletRequest(e,t){let r=Object.entries(t.servers||{}).filter(([e,t])=>{let r=t.tools||[];return r.includes("get_xdc_balance")||r.includes("get_balance")});if(0===r.length)return"❌ No wallet servers are currently running.";try{let[e,t]=r[0],s=t.tools||[],n=`💼 **Wallet Information**

`;if(s.includes("get_xdc_balance"))try{let t=await (0,l.tB)(e,"get_xdc_balance",{});n+=`**XDC Balance:**
\`\`\`json
${JSON.stringify(t,null,2)}
\`\`\`
`}catch(e){n+=`**Balance Error:** ${e instanceof Error?e.message:"Unknown error"}
`}return n}catch(e){return`❌ Error getting wallet information: ${e instanceof Error?e.message:"Unknown error"}`}}async function handleNFTRequest(e,t){let r=Object.entries(t.servers||{}).filter(([e,t])=>{let r=t.tools||[];return r.includes("mint_nft")});return 0===r.length?"❌ No NFT servers are currently running.":`🎨 **NFT Operations Available**

I can help you mint NFTs! Please provide:
- Recipient address
- Token URI/metadata
- Contract address (optional)

Example: "Mint NFT to 0x123... with metadata https://example.com/metadata.json"`}async function handleFileRequest(e,t){return`📁 **File operations would be handled here**

Currently available file operations depend on your configured servers.`}function generateHelpfulResponse(e,t){let r=e.servers?Object.entries(e.servers).filter(([e,t])=>"running"===t.status):[];if(0===r.length)return"❌ No MCP servers are currently running. Please check your configuration.";let s=`🤔 I didn't understand that specific request.

`;s+=`**Available commands:**
- "list servers and tools"
- "system status"
- "help"

**Or try asking about:**
`;let n=r.flatMap(([e,t])=>t.tools||[]);return n.includes("get-GLEIF-data")&&(s+=`- GLEIF compliance checks
`),n.includes("get_xdc_balance")&&(s+=`- Wallet information
`),n.includes("mint_nft")&&(s+=`- NFT operations
`),s}let a=(0,i.l)(s,"default"),c=(0,i.l)(s,"config"),u=new n.PagesAPIRouteModule({definition:{kind:o.x.PAGES_API,page:"/api/chat",pathname:"/api/chat",bundlePath:"",filename:""},userland:s})}};var t=require("../../webpack-api-runtime.js");t.C(e);var __webpack_exec__=e=>t(t.s=e),r=t.X(0,[222,927],()=>__webpack_exec__(2087));module.exports=r})();