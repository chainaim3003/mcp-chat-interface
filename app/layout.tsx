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
