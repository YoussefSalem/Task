#!/usr/bin/env bash
# Orchestrates the full E2E smoke test: starts the Next.js dev server pointed
# at the Firebase emulator suite (never production), seeds temp data, runs
# the Playwright spec, tears the temp data down, then stops the dev server.
# Must be invoked from inside `firebase emulators:exec` so
# FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST / etc. are already set.
set -euo pipefail
cd "$(dirname "$0")/.."

export NEXT_PUBLIC_USE_FIREBASE_EMULATORS=true
export NEXT_PUBLIC_FIREBASE_API_KEY=demo-api-key
export NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=demo-task.firebaseapp.com
export NEXT_PUBLIC_FIREBASE_PROJECT_ID=demo-task
export NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=demo-task.appspot.com
export NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=000000000000
export NEXT_PUBLIC_FIREBASE_APP_ID=1:000000000000:web:0000000000000000000000

echo "[smoke] starting next dev on :3100 against the emulator suite..."
PORT=3100 npx next dev -p 3100 > e2e/.next-dev.log 2>&1 &
DEV_PID=$!
cleanup() {
  echo "[smoke] stopping next dev (pid $DEV_PID)..."
  kill "$DEV_PID" 2>/dev/null || true
  wait "$DEV_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "[smoke] waiting for dev server..."
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:3100/login >/dev/null 2>&1; then
    echo "[smoke] dev server is up."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "[smoke] dev server never came up; last log lines:"
    tail -n 60 e2e/.next-dev.log || true
    exit 1
  fi
  sleep 1
done

echo "[smoke] seeding temp E2E data..."
node --import tsx e2e/seed.ts

echo "[smoke] running Playwright spec..."
set +e
npx playwright test e2e/dashboard-smoke.spec.ts
SPEC_STATUS=$?
set -e

echo "[smoke] tearing down temp E2E data..."
node --import tsx e2e/teardown.ts

rm -f e2e/.manifest.json

exit $SPEC_STATUS
