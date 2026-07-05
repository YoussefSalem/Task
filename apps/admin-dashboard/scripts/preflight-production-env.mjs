import { existsSync, readFileSync } from "node:fs";

const envPath = ".env";
const required = [
  "ADMIN_DASHBOARD_URL",
  "RESEND_API_KEY",
  "RESEND_FROM_EMAIL",
  "RESEND_FROM_NAME",
];

function parseEnv(text) {
  return Object.fromEntries(
    text
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#") && line.includes("="))
      .map((line) => {
        const index = line.indexOf("=");
        return [
          line.slice(0, index),
          line.slice(index + 1).replace(/^"|"$/g, "").trim(),
        ];
      }),
  );
}

if (!existsSync(envPath)) {
  console.error(
    [
      "Production deploy blocked: project-root .env is missing.",
      "Firebase Hosting framework deploys load server env vars from .env.",
      "Create .env from .env.example and set RESEND_API_KEY, RESEND_FROM_EMAIL, and RESEND_FROM_NAME before deploying.",
    ].join("\n"),
  );
  process.exit(1);
}

const env = parseEnv(readFileSync(envPath, "utf8"));
const missing = required.filter((name) => !env[name]);
if (missing.length) {
  console.error(
    `Production deploy blocked: missing required server env var(s): ${missing.join(", ")}.`,
  );
  process.exit(1);
}

if (env.RESEND_FROM_EMAIL.includes("<") || env.RESEND_FROM_EMAIL.includes(">")) {
  console.error(
    "Production deploy blocked: RESEND_FROM_EMAIL must be a plain verified email address. Put the display name in RESEND_FROM_NAME.",
  );
  process.exit(1);
}

if (env.RESEND_FROM_EMAIL !== "noreply@jeans-stop.com") {
  console.warn(
    `Warning: RESEND_FROM_EMAIL is ${env.RESEND_FROM_EMAIL}; expected noreply@jeans-stop.com.`,
  );
}

console.log("Production environment preflight passed.");
