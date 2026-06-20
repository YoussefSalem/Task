# Task — Home-Services Marketplace

Flutter + Firebase monorepo for **Task**, an on-demand home-services marketplace
for Egypt/MENA. Dark-theme, RTL-first. See the design spec at
[`docs/superpowers/specs/2026-06-21-task-customer-v1-design.md`](docs/superpowers/specs/2026-06-21-task-customer-v1-design.md).

## Structure

```
packages/
  task_core/      Pure Dart — Result/Failure, business-rule constants, utils
  task_design/    Material 3 dark theme, tokens, Cairo typography, RTL
  task_domain/    Entities, enums, repository interfaces, use cases (pure Dart)
  task_data/      Firebase/Dio/Drift implementations, DTOs, enum codecs
apps/
  customer/       Customer app (v1) — Riverpod + GoRouter, flavored entrypoints
  technician/     Phase 2 skeleton
  admin/          Phase 3 skeleton (Flutter Web)
backend/
  functions/      Cloud Functions (TypeScript)
  firestore.rules / firestore.indexes.json / storage.rules
```

Dependency direction: `presentation → domain ← data`. Domain is Flutter/Firebase-free.

## Toolchain

Flutter 3.44+ · Dart 3.12+ · Firebase CLI · Node 20+ · Melos 7. The workspace
uses **native Dart pub workspaces** for resolution; Melos drives task scripts.

## Common commands

```bash
flutter pub get                 # resolve the whole workspace
dart analyze                    # static analysis (CI gate: zero issues)
dart run melos run test         # run tests across packages with tests

# Customer app (Dev flavor)
cd apps/customer && flutter run -t lib/main_dev.dart

# Backend
cd backend/functions && npm install && npm run build
firebase emulators:start --project demo-task
```

Local dev servers are defined in [`.claude/launch.json`](.claude/launch.json):
the Customer web app (:5000), the Firebase Emulator Suite (UI :4000), and the
Cloud Functions TypeScript watcher.

## ⚠️ Pending setup before the Auth phase

Firebase is **not yet wired** — by design. Before auth/data work begins, run:

```bash
flutterfire configure   # generates apps/customer/lib/firebase_options.dart per flavor
```

This requires real `dev` / `staging` / `prod` Firebase projects. The app boots
without Firebase today so the design system, routing, and RTL can be verified
first. `firebase_options.dart`, `google-services.json`, and
`GoogleService-Info.plist` are git-ignored (they carry per-project keys).

## Flavors

`apps/customer` has three entrypoints mapping to the Dev/Staging/Prod Firebase
projects: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`.
