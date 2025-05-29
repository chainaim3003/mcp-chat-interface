/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
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
