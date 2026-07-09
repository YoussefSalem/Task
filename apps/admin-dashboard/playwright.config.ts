import { defineConfig } from "@playwright/test";

// Points at the local Next.js dev server, which (only when
// NEXT_PUBLIC_USE_FIREBASE_EMULATORS=true is set by the runner) talks to the
// local Firebase emulator suite instead of production. See e2e/README.md.
export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:3100",
    headless: true,
  },
});
