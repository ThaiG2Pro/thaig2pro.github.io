import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './specs',
  reporter: [['list']],
  use: {
    ...devices['Desktop Chrome'],
    viewport: { width: 900, height: 900 },
  },
});
