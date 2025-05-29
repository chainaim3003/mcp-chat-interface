/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    webpackBuildWorker: false
  },
  webpack: (config, { isServer }) => {
    // Exclude backup files and directories from webpack processing
    config.watchOptions = {
      ...config.watchOptions,
      ignored: [
        '**/node_modules/**',
        '**/.git/**',
        '**/.next/**',
        '**/out/**',
        '**/dist/**',
        '**/build/**',
        '**/*.backup/**',
        '**/backup/**',
        '**/*.backup.*',
        '**/mcp-orchestrator.backup/**',
        '**/*.bak',
        '**/*.old'
      ]
    };

    // Exclude backup files from module resolution
    config.resolve.alias = {
      ...config.resolve.alias,
    };

    return config;
  },
  // Exclude backup directories from being processed
  pageExtensions: ['js', 'jsx', 'ts', 'tsx'],
  transpilePackages: [],
};

module.exports = nextConfig;
