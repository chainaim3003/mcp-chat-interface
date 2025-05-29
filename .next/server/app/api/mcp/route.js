"use strict";(()=>{var e={};e.id=694,e.ids=[694],e.modules={517:e=>{e.exports=require("next/dist/compiled/next-server/app-route.runtime.prod.js")},7840:(e,t,o)=>{o.r(t),o.d(t,{headerHooks:()=>p,originalPathname:()=>d,requestAsyncStorage:()=>c,routeModule:()=>i,serverHooks:()=>m,staticGenerationAsyncStorage:()=>l,staticGenerationBailout:()=>u});var a={};o.r(a),o.d(a,{GET:()=>GET,POST:()=>POST});var r=o(884),s=o(6132),n=o(5798);async function POST(e){try{let{message:t}=await e.json(),o={id:crypto.randomUUID(),role:"assistant",content:"",timestamp:new Date().toISOString(),toolCalls:[]},a=t.toLowerCase();if(a.includes("gleif")){let e=t.match(/(?:for|company)\s+([A-Za-z][A-Za-z0-9\s&.-]+?)(?:\s|$|,|\.|!|\?)/i),a=e?e[1].trim():"Unknown Company",r=Math.random()>.5?"ACTIVE":"INACTIVE",s="LEI-"+Math.random().toString(36).substring(2,20).toUpperCase(),n={id:crypto.randomUUID(),toolName:"get-GLEIF-data",serverName:"PRET-MCP-SERVER",parameters:{companyName:a},status:"success",result:{companyName:a,gleifStatus:r,entityId:s,lastUpdated:new Date().toISOString()}};o.content=`**GLEIF Compliance Check for ${a}**

Status: ${r}
Entity ID: ${s}

${"ACTIVE"===r?"✅ Company is GLEIF compliant!":"❌ Company needs GLEIF registration."}`,o.toolCalls=[n]}else if(a.includes("mint")){let e="0x"+Array.from({length:64},()=>Math.floor(16*Math.random()).toString(16)).join(""),t=Math.floor(1e6*Math.random()),a={id:crypto.randomUUID(),toolName:"mint_nft",serverName:"GOAT-EVM-MCP-SERVER",parameters:{network:"testnet",contractAddress:"0x1234567890123456789012345678901234567890"},status:"success",result:{transactionHash:e,tokenId:t,network:"testnet",gasUsed:"84000"}};o.content=`**NFT Minted Successfully!**

Transaction Hash: ${e}
Token ID: ${t}
Network: testnet`,o.toolCalls=[a]}else if(a.includes("balance")){let e=t.match(/(0x[a-fA-F0-9]{40})/),a=e?e[1]:"0x1234567890123456789012345678901234567890",r=(1e3*Math.random()).toFixed(6),s={id:crypto.randomUUID(),toolName:"get_xdc_balance",serverName:"GOAT-EVM-MCP-SERVER",parameters:{address:a,network:"testnet"},status:"success",result:{address:a,balance:r,currency:"XDC",network:"testnet"}};o.content=`**XDC Balance Check**

Address: ${a}
Balance: ${r} XDC
Network: testnet`,o.toolCalls=[s]}else a.includes("status")?o.content=`🔧 **MCP System Status**

✅ PRET-MCP-SERVER: Connected (Demo)
✅ GOAT-EVM-MCP-SERVER: Connected (Demo)
✅ Available Tools: 4
✅ All systems operational!

*Note: This is a demo interface with simulated MCP operations.*`:o.content=`🤖 **Welcome to MCP Chat Interface Demo!**

I can help you with:

**🔍 Compliance Operations:**
- "Check GLEIF compliance for Acme Corp"
- "Run compliance workflow for TechStart"

**🎨 NFT Operations:**
- "Mint NFT for CompanyX"
- "Deploy NFT contract on testnet"

**💰 Blockchain Operations:**
- "Check XDC balance for 0x123..."
- "Get balance for wallet"

**🔄 System Operations:**
- "Check system status"
- "List available tools"

**Try asking:** *"Check GLEIF compliance for Acme Corp"*

*This demo uses simulated MCP server responses.*`;return n.Z.json(o)}catch(t){console.error("MCP API Error:",t);let e={id:crypto.randomUUID(),role:"assistant",content:`❌ **Error Processing Request**

${t instanceof Error?t.message:"An unexpected error occurred."}`,timestamp:new Date().toISOString(),toolCalls:[]};return n.Z.json(e,{status:500})}}async function GET(){return n.Z.json({status:"healthy",service:"MCP Chat Interface Demo",version:"1.0.0",mode:"demo",tools:4,servers:["PRET-MCP-SERVER (Demo)","GOAT-EVM-MCP-SERVER (Demo)"],timestamp:new Date().toISOString(),note:"This is a demo interface with simulated MCP operations"})}let i=new r.AppRouteRouteModule({definition:{kind:s.x.APP_ROUTE,page:"/api/mcp/route",pathname:"/api/mcp",filename:"route",bundlePath:"app/api/mcp/route"},resolvedPagePath:"C:\\SATHYA\\CHAINAIM3003\\mcp-servers\\mcp-chat-interface\\app\\api\\mcp\\route.ts",nextConfigOutput:"",userland:a}),{requestAsyncStorage:c,staticGenerationAsyncStorage:l,serverHooks:m,headerHooks:p,staticGenerationBailout:u}=i,d="/api/mcp/route"}};var t=require("../../../webpack-runtime.js");t.C(e);var __webpack_exec__=e=>t(t.s=e),o=t.X(0,[997],()=>__webpack_exec__(7840));module.exports=o})();