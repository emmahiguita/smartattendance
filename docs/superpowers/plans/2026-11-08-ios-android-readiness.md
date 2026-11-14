# iOS and Android Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove repository-controlled blockers that prevent reproducible, release-ready Flutter builds and reliable layouts on iOS and Android.

**Architecture:** Keep platform credentials external while making their required inputs explicit and fail-fast. Centralize runtime environment selection through compile-time defines, preserve production HTTPS defaults, and fix responsive defects at their owning widgets with regression tests.

**Tech Stack:** Flutter/Dart, Android Gradle Kotlin DSL, Xcode/CocoaPods, GitHub Actions.

**Spec:** Audit findings from the 2026-11-08 iOS/Android readiness review in this chat.

## Global Constraints

- Do not invent or commit Apple, Google OAuth, or Android signing secrets.
- Preserve existing user changes and keep new or modified Dart files below 200 lines where practical.
- Use HTTPS for production defaults and do not add global iOS ATS exceptions.
- Every functional fix follows RED-GREEN verification.
- Respect reduced motion and avoid introducing permanent render loops.

## Review Focus

- Clean checkout contains every asset referenced by `pubspec.yaml` and native launch/icon metadata.
- Release builds cannot silently use development URLs or debug signing.
- 320-360 dp layouts and enlarged text do not overflow.
- OAuth configuration failures are explicit and actionable on both platforms.
- iOS artifacts are signed by the distribution workflow rather than relabeled unsigned bundles.

---

### Task 1: Reproducible assets and release packaging

**Files:**
- Modify: `.gitignore`
- Modify: `smartattendance_app/android/app/build.gradle.kts`
- Modify: `.github/workflows/build_ios.yml`
- Create: `smartattendance_app/android/key.properties.example`

**Interfaces:**
- Consumes: existing Flutter asset declarations and native signing conventions.
- Produces: clean-checkout resources and fail-fast release signing inputs.

- [ ] Add a repository check proving required PNG/JPG resources are not ignored.
- [ ] Verify the check fails against the current ignore rules.
- [ ] Narrow media ignore rules and force-add existing application/native resources.
- [ ] Replace Android debug release signing with external keystore properties and clear failure messages.
- [ ] Replace the unsigned IPA packaging workflow with a genuine signed archive/export flow driven by repository secrets.
- [ ] Verify Android debug/release configuration and repository resource checks.

### Task 2: Runtime environments, transport and OAuth readiness

**Files:**
- Modify: `smartattendance_app/lib/core/config/environment_config.dart`
- Modify: `smartattendance_app/lib/core/location/traccar_service.dart`
- Modify: `smartattendance_app/lib/features/auth/presentation/viewmodels/login_viewmodel.dart`
- Modify: `smartattendance_app/ios/Runner/Info.plist`
- Test: `smartattendance_app/test/unit/config/environment_config_test.dart`

**Interfaces:**
- Consumes: `--dart-define=APP_ENV` and `API_BASE_URL`.
- Produces: deterministic environment selection and HTTPS-safe defaults.

- [ ] Add failing tests for production default selection and iOS-compatible API overrides.
- [ ] Run focused tests and confirm the expected failures.
- [ ] Resolve environment from compile-time values instead of a hardcoded development constant.
- [ ] Change Traccar default/normalization to HTTPS and reject insecure production configuration.
- [ ] Make missing Google OAuth configuration an explicit user-facing failure without committing credentials.
- [ ] Run focused tests and static analysis.

### Task 3: Responsive regressions and stale expectations

**Files:**
- Modify only widgets directly identified by failing tests.
- Modify stale test expectations only when current product wording is authoritative.
- Test: existing `test/widget/*`, `test/app_smoke_test.dart`.

**Interfaces:**
- Consumes: existing responsive tests at 320-360 dp and enlarged text scale.
- Produces: layouts without RenderFlex overflow and tests aligned to intended behavior.

- [ ] Run failing tests individually and classify each failure as product defect or stale assertion.
- [ ] For every product defect, retain the failing test as RED and apply the smallest owning-widget fix.
- [ ] For stale assertions, verify the authoritative product value before updating the expectation.
- [ ] Run each focused test to GREEN, then run the complete Flutter suite.

### Task 4: Cross-platform verification and independent review

**Files:**
- Modify: documentation/configuration only if verification exposes an actionable repository defect.

**Interfaces:**
- Consumes: completed Tasks 1-3.
- Produces: evidence matrix for Android, iOS, tests, and remaining secret/device prerequisites.

- [ ] Run `flutter analyze` and the complete Flutter test suite.
- [ ] Build an Android release artifact with explicit signing behavior verified.
- [ ] Validate iOS project and workflow configuration; record macOS/device-only gates separately.
- [ ] Run backend tests if the Python environment is available.
- [ ] Have a fresh reviewer inspect the complete diff and correct Critical/Important findings.

