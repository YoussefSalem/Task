# Graph Report - .  (2026-06-21)

## Corpus Check
- Corpus is ~21,008 words - fits in a single context window. You may not need a graph.

## Summary
- 498 nodes · 564 edges · 59 communities (41 shown, 18 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.82)
- Token cost: 81,720 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Customer App Bootstrap & Routing|Customer App Bootstrap & Routing]]
- [[_COMMUNITY_iOSSwift Runner Host|iOS/Swift Runner Host]]
- [[_COMMUNITY_Flavor & Result Types|Flavor & Result Types]]
- [[_COMMUNITY_Splash Screen Animation|Splash Screen Animation]]
- [[_COMMUNITY_Localization Delegates|Localization Delegates]]
- [[_COMMUNITY_Business Rules Constants|Business Rules Constants]]
- [[_COMMUNITY_Technician App & Design Colors|Technician App & Design Colors]]
- [[_COMMUNITY_Cloud Functions (Firebase)|Cloud Functions (Firebase)]]
- [[_COMMUNITY_Domain Enums & Wire Codecs|Domain Enums & Wire Codecs]]
- [[_COMMUNITY_Architecture & Design Spec|Architecture & Design Spec]]
- [[_COMMUNITY_Functions TypeScript Config|Functions TypeScript Config]]
- [[_COMMUNITY_Monorepo Packages & Config|Monorepo Packages & Config]]
- [[_COMMUNITY_Failure Type Hierarchy|Failure Type Hierarchy]]
- [[_COMMUNITY_Arabic Localization Strings|Arabic Localization Strings]]
- [[_COMMUNITY_App Widget Tests|App Widget Tests]]
- [[_COMMUNITY_Design Spacing Tokens|Design Spacing Tokens]]
- [[_COMMUNITY_Customer PWA Manifest|Customer PWA Manifest]]
- [[_COMMUNITY_Admin PWA Manifest|Admin PWA Manifest]]
- [[_COMMUNITY_Sign-In Screen|Sign-In Screen]]
- [[_COMMUNITY_English Localization Strings|English Localization Strings]]
- [[_COMMUNITY_Auth Repository Contract|Auth Repository Contract]]
- [[_COMMUNITY_Widget State Mixins|Widget State Mixins]]
- [[_COMMUNITY_Flutter LLDB Helper (A)|Flutter LLDB Helper (A)]]
- [[_COMMUNITY_Flutter LLDB Helper (B)|Flutter LLDB Helper (B)]]
- [[_COMMUNITY_App Shell Widgets|App Shell Widgets]]
- [[_COMMUNITY_Localizations Delegate Impl|Localizations Delegate Impl]]
- [[_COMMUNITY_Android MainActivity|Android MainActivity]]
- [[_COMMUNITY_task_design Theme Barrel|task_design Theme Barrel]]
- [[_COMMUNITY_Android Plugin Registrant (A)|Android Plugin Registrant (A)]]
- [[_COMMUNITY_Android Plugin Registrant (B)|Android Plugin Registrant (B)]]
- [[_COMMUNITY_task_core Barrel|task_core Barrel]]
- [[_COMMUNITY_Swift Package Manifest|Swift Package Manifest]]
- [[_COMMUNITY_iOS Plugin Registrant (A)|iOS Plugin Registrant (A)]]
- [[_COMMUNITY_Customer Dev Entrypoint|Customer Dev Entrypoint]]
- [[_COMMUNITY_iOS Plugin Registrant (B)|iOS Plugin Registrant (B)]]
- [[_COMMUNITY_task_domain Barrel|task_domain Barrel]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]

## God Nodes (most connected - your core abstractions)
1. `_` - 27 edges
2. `_` - 14 edges
3. `compilerOptions` - 13 edges
4. `_` - 13 edges
5. `task_data package` - 8 edges
6. `AppLocalizations` - 7 edges
7. `_` - 7 edges
8. `Admin App pubspec` - 7 edges
9. `Customer App pubspec` - 7 edges
10. `Root Pub Workspace (task)` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Admin App pubspec` --references--> `Root Analysis Options`  [INFERRED]
  apps/admin/pubspec.yaml → analysis_options.yaml
- `Task Customer v1 Design Spec` --references--> `Technician App (Phase 2 skeleton)`  [INFERRED]
  docs/superpowers/specs/2026-06-21-task-customer-v1-design.md → apps/technician/pubspec.yaml
- `Melos Monorepo + Flavors` --references--> `Root Pub Workspace (task)`  [INFERRED]
  docs/superpowers/specs/2026-06-21-task-customer-v1-design.md → pubspec.yaml
- `Result/Failure Error Handling` --references--> `task_core package`  [INFERRED]
  docs/superpowers/specs/2026-06-21-task-customer-v1-design.md → packages/task_core/pubspec.yaml
- `Drift Offline Queue & Sync` --references--> `task_data package`  [INFERRED]
  docs/superpowers/specs/2026-06-21-task-customer-v1-design.md → packages/task_data/pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Shared Workspace Packages Consumed by Apps** — readme_task_core, readme_task_design, readme_task_domain, readme_task_data, pubspec_customer, pubspec_admin [EXTRACTED 0.95]
- **Clean Architecture Layering** — readme_task_domain, readme_task_data, readme_dependency_direction [EXTRACTED 0.95]
- **Shared Melos Business-Logic Packages** — task_core_pubspec_task_core, task_domain_pubspec_task_domain, task_data_pubspec_task_data, task_design_pubspec_task_design [EXTRACTED 0.95]
- **Clean Architecture Layer Stack** — specs_2026_06_21_task_customer_v1_design_clean_architecture, specs_2026_06_21_task_customer_v1_design_layer_dependency_rule, task_domain_pubspec_task_domain, task_data_pubspec_task_data [INFERRED 0.85]

## Communities (59 total, 18 thin omitted)

### Community 0 - "Customer App Bootstrap & Routing"
Cohesion: 0.05
Nodes (45): bootstrap, build, CustomerApp, flavor, goRouterProvider, main, ConsumerWidget, dart:async (+37 more)

### Community 1 - "iOS/Swift Runner Host"
Cohesion: 0.08
Nodes (21): Any, Bool, FlutterImplicitEngineBridge, AppDelegate, UIApplication, SceneDelegate, RunnerTests, Any (+13 more)

### Community 2 - "Flavor & Result Types"
Cohesion: 0.09
Nodes (25): @immutable, appTitle, Flavor, isProd, bool get, F, F? get, Failure (+17 more)

### Community 3 - "Splash Screen Animation"
Cohesion: 0.08
Nodes (25): Animation, AnimationController, Offset, _buildLogo, createState, dispose, initState, _intro (+17 more)

### Community 4 - "Localization Delegates"
Cohesion: 0.08
Nodes (23): app_localizations_ar.dart, app_localizations_en.dart, class, continueAction, delegate, getStarted, isSupported, language (+15 more)

### Community 5 - "Business Rules Constants"
Cohesion: 0.09
Nodes (24): _, BusinessRules, chatActiveRetention, chatArchiveRetention, dispatchRadiiKm, dispatchTierDelay, geoEnRouteWriteInterval, geoIdleDistanceMeters (+16 more)

### Community 6 - "Technician App & Design Colors"
Cohesion: 0.10
Nodes (19): build, main, build, main, TechnicianApp, package:flutter/material.dart, package:task_design/task_design.dart, static const Color (+11 more)

### Community 7 - "Cloud Functions (Firebase)"
Cohesion: 0.10
Nodes (19): dependencies, firebase-admin, firebase-functions, @google-cloud/tasks, description, devDependencies, @types/node, typescript (+11 more)

### Community 8 - "Domain Enums & Wire Codecs"
Cohesion: 0.14
Nodes (17): BookingType, JobStatus, KycStatus, PaymentMethod, PaymentStatus, TechnicianTier, UserRole, BookingTypeCodec (+9 more)

### Community 9 - "Architecture & Design Spec"
Cohesion: 0.17
Nodes (18): Melos Workspace Config (task), Root Pub Workspace (task), Firebase App Check (mandatory), Clean Architecture (three layers), Task Customer v1 Design Spec, Data Flow (UI→Riverpod→UseCase→Repo→Impl), Layer Dependency Rule (presentation→domain←data), Melos Monorepo + Flavors (+10 more)

### Community 10 - "Functions TypeScript Config"
Cohesion: 0.12
Nodes (15): compilerOptions, esModuleInterop, lib, module, noImplicitReturns, noUnusedLocals, noUnusedParameters, outDir (+7 more)

### Community 11 - "Monorepo Packages & Config"
Cohesion: 0.22
Nodes (15): Root Analysis Options, Admin Web index.html, Customer Web index.html, Customer l10n Config, Admin App pubspec, Customer App pubspec, Admin App README, Customer App README (+7 more)

### Community 12 - "Failure Type Hierarchy"
Cohesion: 0.21
Nodes (13): Failure, AuthFailure, cause, message, NetworkFailure, OfflineFailure, PaymentFailure, PermissionFailure (+5 more)

### Community 13 - "Arabic Localization Strings"
Cohesion: 0.17
Nodes (11): app_localizations.dart, continueAction, getStarted, language, loading, phoneNumberLabel, signInComingSoon, signInSubtitle (+3 more)

### Community 14 - "App Widget Tests"
Cohesion: 0.20
Nodes (10): main, main, package:admin/main.dart, package:flutter_test/flutter_test.dart, package:google_fonts/google_fonts.dart, package:task_design/src/theme/app_colors.dart, package:task_design/src/theme/app_spacing.dart, package:technician/main.dart (+2 more)

### Community 15 - "Design Spacing Tokens"
Cohesion: 0.18
Nodes (12): static const double, _, AppSpacing, lg, md, radiusLg, radiusMd, radiusSm (+4 more)

### Community 16 - "Customer PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 17 - "Admin PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 18 - "Sign-In Screen"
Cohesion: 0.18
Nodes (10): build, createState, dispose, _onContinue, _phone, routeName, routePath, package:customer/features/localization/language_switcher.dart (+2 more)

### Community 19 - "English Localization Strings"
Cohesion: 0.18
Nodes (10): continueAction, getStarted, language, loading, phoneNumberLabel, signInComingSoon, signInSubtitle, signInTitle (+2 more)

### Community 20 - "Auth Repository Contract"
Cohesion: 0.22
Nodes (8): package:task_core/task_core.dart, AuthRepository, authStateChanges, OtpSession, requestOtp, signOut, verifyOtp, typedef

### Community 21 - "Widget State Mixins"
Cohesion: 0.33
Nodes (7): state, SignInScreen, _SignInScreenState, SplashScreen, _SplashScreenState, StatefulWidget, TickerProviderStateMixin

### Community 22 - "Flutter LLDB Helper (A)"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 23 - "Flutter LLDB Helper (B)"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 24 - "App Shell Widgets"
Cohesion: 0.33
Nodes (6): _SignInBackground, AdminApp, _GetStartedButton, _LaunchProgress, _SplashBackground, StatelessWidget

### Community 25 - "Localizations Delegate Impl"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsAr, AppLocalizationsEn, of, LocalizationsDelegate

### Community 26 - "Android MainActivity"
Cohesion: 0.40
Nodes (3): MainActivity, FlutterActivity, MainActivity

### Community 27 - "task_design Theme Barrel"
Cohesion: 0.40
Nodes (4): src/theme/app_colors.dart, src/theme/app_spacing.dart, src/theme/app_theme.dart, src/theme/app_typography.dart

### Community 30 - "task_core Barrel"
Cohesion: 0.50
Nodes (3): src/constants/business_rules.dart, src/failures/failure.dart, src/result/result.dart

## Knowledge Gaps
- **233 isolated node(s):** `main`, `build`, `main`, `name`, `short_name` (+228 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `Business Rules Constants` to `Customer App Bootstrap & Routing`, `Design Spacing Tokens`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **What connects `main`, `build`, `main` to the rest of the system?**
  _238 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Customer App Bootstrap & Routing` be split into smaller, more focused modules?**
  _Cohesion score 0.050314465408805034 - nodes in this community are weakly interconnected._
- **Should `iOS/Swift Runner Host` be split into smaller, more focused modules?**
  _Cohesion score 0.07954545454545454 - nodes in this community are weakly interconnected._
- **Should `Flavor & Result Types` be split into smaller, more focused modules?**
  _Cohesion score 0.09116809116809117 - nodes in this community are weakly interconnected._
- **Should `Splash Screen Animation` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Localization Delegates` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._