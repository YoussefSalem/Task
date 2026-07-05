import { loadEnvConfig } from "@next/env";

loadEnvConfig(process.cwd());

async function main() {
  const { resetDemoData } = await import("../lib/firebase/demo-seed");
  const result = await resetDemoData({
    id: "cli",
    name: "Demo seed script",
  });
  console.log(
    `Demo workspace reset complete. Deleted ${result.deleted} old demo docs and seeded ${result.seeded} demo docs.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
