# Flutter Mobile App Template — Usage Guide

> **Audience:** Mobile application teams creating a new Flutter repository from this template,
> platform engineers maintaining CI/CD workflow standards, and release engineers validating
> Android and iOS artifact generation and deployment.

This document is the **template runbook**. It lives in every repository derived from
[`fluttermobile-app-template`](https://github.com/cloudopsworks/fluttermobile-app-template) and
explains how to configure, build, deploy, and upgrade. Replace `README.md` with product-specific
documentation; keep this file as the operational reference.

---

## Table of Contents

1. [What This Template Gives You](#what-this-template-gives-you)
2. [Repository Layout](#repository-layout)
3. [Quick Start](#quick-start)
4. [Versioning & Release Model](#versioning--release-model)
5. [Blueprint Pins](#blueprint-pins)
6. [Configuration Reference — inputs-global.yaml](#configuration-reference--inputs-globalyaml)
7. [Build Matrix](#build-matrix)
8. [Android Configuration](#android-configuration)
9. [iOS Configuration](#ios-configuration)
10. [Per-Environment Inputs](#per-environment-inputs)
11. [Cloud Deployment](#cloud-deployment)
12. [Workflow Reference](#workflow-reference)
13. [Local Development](#local-development)
14. [Customization Checklist](#customization-checklist)
15. [Upgrade Procedure](#upgrade-procedure)
16. [Troubleshooting](#troubleshooting)
17. [Maintenance Policy](#maintenance-policy)

---

## What This Template Gives You

| Feature | Details |
|---|---|
| Flutter skeleton | `android/`, `ios/`, `lib/`, `test/` with working sample screens |
| CI/CD metadata | `.cloudopsworks/` — governance, labeling, versioning, vars |
| GitHub Actions workflows | PR validation, release builds, deploys, scans, ownership, JIRA, cleanup |
| Matrix builds | Android APK/AAB and signed or unsigned iOS from one workflow dispatch |
| Device-farm deploy | AWS Device Farm and GCP Firebase Test Lab |
| GitVersion + Tronador | Semantic versioning helpers via `Makefile` |
| Security integrations | Optional Snyk, Semgrep, SonarQube, DependencyTrack hooks |
| Template marker | `.cloudopsworks/.fluttermobile` consumed by `cd/checkout/check-module-version` |

---

## Repository Layout

```
.
├── .cloudopsworks/
│   ├── .fluttermobile          # Marker: identifies this as a Flutter mobile template repo
│   ├── _VERSION                # Last template version applied (managed by make repos/upgrade)
│   ├── cloudopsworks-ci.yaml   # Branch protection, GitFlow, CD deployment triggers
│   ├── labeler.yml             # PR label rules for platform workflows
│   ├── Makefile                # Cloud Ops Works helper targets
│   └── vars/
│       ├── inputs-global.yaml  # Primary config: Flutter build matrix, quality, cloud
│       ├── inputs-dev.yaml     # Dev environment overrides and device-farm settings
│       ├── inputs-uat.yaml     # UAT environment overrides
│       └── inputs-prod.yaml    # Production environment overrides
├── .github/
│   └── workflows/
│       ├── pr-build.yml        # PR quality checks + platform builds
│       ├── main-build.yml      # Release artifacts, scans, deploy trigger
│       ├── deploy.yml          # Deploy mobile artifacts to device farms
│       ├── scan.yml            # SAST/SCA/DAST security scanning
│       ├── process-owners.yml  # CODEOWNERS/reviewer reconciliation
│       ├── jira-integration.yml
│       ├── pr-close.yaml
│       ├── environment-destroy.yml
│       ├── environment-unlock.yml
│       └── patch-management.yml
├── android/                    # Flutter Android platform project
├── ios/                        # Flutter iOS platform project
├── lib/                        # Flutter/Dart application source
├── test/                       # Flutter tests
├── Makefile                    # Project init and version helpers (do not modify)
├── pubspec.yaml                # Package name, dependencies, version
├── README.md                   # Replace with product-specific documentation
└── README-TEMPLATE.md          # This file — template operational guide
```

> **Protected:** `Makefile`, `.github/`, `.cloudopsworks/labeler.yml`,
> `.cloudopsworks/Makefile`, `.cloudopsworks/LICENSE` — do not edit these manually.

---

## Quick Start

### 1. Create the Repository

Use GitHub's "Use this template" button or the `gh` CLI:

```bash
gh repo create cloudopsworks/my-flutter-app \
  --template cloudopsworks/fluttermobile-app-template \
  --private \
  --clone
cd my-flutter-app
```

### 2. Initialize GitFlow

```bash
make gitflow/init
git checkout develop
```

### 3. Initialize Project Metadata

`make code/init` stamps `pubspec.yaml` with the correct package name and GitVersion-derived
version. Run it before the first commit on `develop`.

```bash
make code/init
```

**Prerequisites:**
- `gh` CLI authenticated to the GitHub organization
- `yq` available (via Tronador or installed locally)
- GitVersion available (via Tronador or installed locally)

**What it updates:**
- `pubspec.yaml` → `name` (derived from repository name)
- `pubspec.yaml` → `version` (derived from GitVersion)

### 4. Configure `.cloudopsworks/vars/inputs-global.yaml`

At minimum replace the four identity placeholders at the top of the file:

```yaml
organization_name: "AcmeCorp"        # was: ORG_NAME
organization_unit: "MobileTeam"      # was: ORG_UNIT
environment_name: "my-flutter-app"   # was: ENV_NAME
repository_owner: "acmecorp"         # was: REPO_OWNER (GitHub org/user)
```

### 5. Replace the Sample Application

```bash
# Option A: Replace source in place (recommended)
# Edit lib/, test/, pubspec.yaml, android/, ios/ directly.

# Option B: Regenerate Flutter project structure (destructive — use carefully)
rm -rf lib test
flutter create \
  --org com.acmecorp \
  --project-name my_flutter_app \
  --platforms android,ios .
make code/init
```

### 6. First Local Validation

```bash
flutter pub get
flutter analyze
flutter test
```

---

## Versioning & Release Model

This template follows **GitFlow** with **GitVersion** for automatic semantic versioning.

### GitVersion Configuration

Two GitVersion configuration files ship with the template:

| File | Purpose |
|---|---|
| `.cloudopsworks/gitversion_gitflow.yaml` | GitFlow (default) — develop → release → main |
| `.cloudopsworks/gitversion_githubflow.yaml` | GitHub Flow — feature branches → main |

### Semver Commit Annotations

Append a semver annotation to commit messages to control version bumps:

| Annotation | Effect |
|---|---|
| `+semver: patch` | Bumps patch version (1.0.0 → 1.0.1) |
| `+semver: minor` / `+semver: feature` | Bumps minor version (1.0.0 → 1.1.0) |
| `+semver: major` / `+semver: breaking` | Bumps major version (1.0.0 → 2.0.0) |
| `+semver: none` / `+semver: skip` | No version bump |

**Commit format (Conventional Commits + semver annotation):**

```
fix: resolve Android keystore path resolution +semver: patch
feat: add biometric authentication flow +semver: minor
chore: upgrade from fluttermobile template v1.0.10 +semver: patch
```

### Branch → Environment Flow

```
feature/* ─────┐
hotfix/*  ─────┤
               ▼
           develop ──── (push) ──── CD: dev environment
               │
           release/* ── (push) ──── CD: uat / test
               │        (tag)  ──── CD: prerelease
               ▼
             main ────── (tag)  ──── CD: prod / release
```

### Template Version File

`.cloudopsworks/_VERSION` holds the last template release applied to the repository.
Never edit this manually — it is managed by `make repos/upgrade`.

---

## Blueprint Pins

All workflow files must reference the `v5.10` blueprint channel. **Do not pin to
individual patch tags** — the channel receives compatible patch fixes without requiring a
template release.

**Required values in every workflow file:**

```yaml
uses: cloudopsworks/blueprints/cd/checkout@v5.10
# and in inputs:
blueprint_ref: v5.10
```

**Validate the pins after cloning or upgrading:**

```bash
grep -R "cloudopsworks/blueprints/cd/checkout@" .github/workflows
grep -R "blueprint_ref:" .github/workflows
```

Both commands must return only `v5.10` references.

---

## Configuration Reference — inputs-global.yaml

`/.cloudopsworks/vars/inputs-global.yaml` is the single source of truth for the build matrix,
quality checks, Android outputs, iOS outputs, and optional integrations.

### Identity Fields

```yaml
organization_name: "AcmeCorp"
organization_unit: "MobileTeam"
environment_name: "my-flutter-app"
repository_owner: "acmecorp"
```

| Field | Description |
|---|---|
| `organization_name` | Organization name used by Cloud Ops Works pipelines (display / tagging) |
| `organization_unit` | Business unit or team owning the application |
| `environment_name` | Logical name for this repository/application; used in deployment resource naming |
| `repository_owner` | GitHub organization or user that owns the repository |

### Flutter Section

```yaml
flutter:
  channel: "stable"       # stable | beta | master
  version: ""             # pin to e.g. "3.22.0"; empty = channel default
  project_path: "."       # relative path to Flutter project root
  target: "lib/main.dart" # Dart entrypoint
  build_mode: "release"   # debug | profile | release

  platforms:
    - android
    - ios
```

| Field | Description |
|---|---|
| `channel` | Flutter SDK channel. Use `stable` for production apps. |
| `version` | Optional exact Flutter version. Leave empty to use the runner's installed version for the chosen channel. Pin only when a specific SDK version is required for reproducibility. |
| `project_path` | Path to the root of the Flutter project relative to the repository root. Use `.` when the project is at the repo root. |
| `target` | Main Dart entrypoint. Use `lib/main.dart` unless the project has multiple entrypoints (e.g. flavors). |
| `build_mode` | `release` for deployable artifacts. Use `debug` or `profile` only for dev/smoke workflows. |
| `platforms` | List of platforms to build. Use `[android]` for Android-only, `[ios]` for iOS-only, or both. |

### Quality Section

```yaml
flutter:
  quality:
    enabled: true
    pub_get: true
    analyze: true
    test: true
    coverage: false
    formatter_check: false
```

| Field | Description |
|---|---|
| `pub_get` | Run `flutter pub get` before build steps. Almost always `true`. |
| `analyze` | Run `flutter analyze`. Fails the pipeline on lint errors. |
| `test` | Run `flutter test`. Required before merging to `develop`. |
| `coverage` | Collect LCOV coverage report when `true`. Requires `flutter test --coverage` support. |
| `formatter_check` | Enforce `dart format --set-exit-if-changed`. Enable for strict style gates. |

### Dart Defines

Pass compile-time constants to the Flutter build via `--dart-define`:

```yaml
flutter:
  dart_defines:
    - API_BASE_URL=https://api.acmecorp.com
    - SENTRY_DSN=https://abc123@sentry.io/456
    - FEATURE_BIOMETRICS=true
  extra_args: "--no-tree-shake-icons"
```

Dart defines are available at runtime via `const String.fromEnvironment('API_BASE_URL')`.
Do **not** put secrets here — they are embedded in the binary.

### Complete inputs-global.yaml Example

```yaml
organization_name: "AcmeCorp"
organization_unit: "MobileTeam"
environment_name: "acmecorp-mobile-app"
repository_owner: "acmecorp"

flutter:
  channel: "stable"
  version: ""
  project_path: "."
  target: "lib/main.dart"
  build_mode: "release"

  platforms:
    - android
    - ios

  quality:
    enabled: true
    pub_get: true
    analyze: true
    test: true
    coverage: false
    formatter_check: false

  dart_defines: []
  extra_args: ""

  matrix:
    fail_fast: false
    pr:
      include_android: true
      include_ios: false   # macOS runners are expensive; enable when iOS PR validation is required

    android:
      enabled: true
      runner_set: "ubuntu-latest"
      sdk: "32"
      destination: "Pixel 6"
      configuration: "Release"
      artifact_types:
        - apk
        - appbundle
      deployable_artifact_type: "apk"
      split_per_abi: false
      build_args: ""

    ios:
      enabled: true
      runner_set: "macos-latest"
      xcode_version: "16.4"
      scheme: "Runner"
      sdk: "iphoneos"
      destination: "generic/platform=iOS"
      configuration: "Release"
      codesign: true
      unsigned: "false"
      export_method: "ad-hoc"
      export_options_plist: ""
      build_for_testing: false
      build_args: ""
      deployable_artifact_type: "ipa"

semgrep:
  enabled: true

preview:
  enabled: false

cloud: aws
cloud_type: device-farm
runner_set: "ubuntu-latest"
```

---

## Build Matrix

The workflows use a **`matrix.include` shape**, not a raw Cartesian product. Each platform
entry describes a complete Android or iOS build target, keeping them independent while
allowing one workflow dispatch to build both.

### Platform Selection

| Goal | `flutter.platforms` | PR dispatch |
|---|---|---|
| Android only | `[android]` | `android` |
| iOS only | `[ios]` | `ios` |
| Android + iOS | `[android, ios]` | `android,ios` |

### PR Build Cost Control

macOS runners cost significantly more than Ubuntu. Keep `pr.include_ios: false` unless
signed or platform-specific iOS validation is required on every PR:

```yaml
flutter:
  matrix:
    pr:
      include_android: true
      include_ios: false   # enable only when iOS CI on every PR is justified
```

---

## Android Configuration

**Location:** `.cloudopsworks/vars/inputs-global.yaml` → `flutter.matrix.android`

```yaml
flutter:
  matrix:
    android:
      enabled: true
      runner_set: "ubuntu-latest"
      sdk: "32"                        # Android API level for the runner
      destination: "Pixel 6"           # Build/deploy dimension label
      configuration: "Release"
      artifact_types:
        - apk
        - appbundle
      deployable_artifact_type: "apk"  # Single artifact type sent to device farm
      split_per_abi: false             # true = separate APKs per ABI (arm64, x86_64, …)
      build_args: ""
```

| Field | Description |
|---|---|
| `enabled` | Set `false` to skip Android entirely from the matrix |
| `runner_set` | GitHub Actions runner label. `ubuntu-latest` for standard Android builds |
| `sdk` | Android API level. Matches the emulator/device OS when running on a device farm |
| `destination` | Informational label used by deployment tracking and artifact naming |
| `configuration` | Xcode-style configuration label forwarded to the build. Use `Release` for production |
| `artifact_types` | One or more of `apk`, `appbundle`. Both can be produced in the same build |
| `deployable_artifact_type` | The **single** artifact sent to the device farm — must be `apk`. AAB is store-only |
| `split_per_abi` | When `true`, Flutter produces separate APKs for each ABI. Device Farm expects a single universal APK unless configured otherwise |
| `build_args` | Extra flags passed verbatim to `flutter build apk` / `flutter build appbundle` |

### Android Build Outputs

| Artifact | Path |
|---|---|
| APK | `build/app/outputs/flutter-apk/*.apk` |
| AAB | `build/app/outputs/bundle/**/*.aab` |

---

## iOS Configuration

**Location:** `.cloudopsworks/vars/inputs-global.yaml` → `flutter.matrix.ios`

```yaml
flutter:
  matrix:
    ios:
      enabled: true
      runner_set: "macos-latest"
      xcode_version: "16.4"
      scheme: "Runner"
      sdk: "iphoneos"
      destination: "generic/platform=iOS"
      configuration: "Release"
      codesign: true         # false = unsigned smoke build; true = signed IPA
      unsigned: "false"      # true = unsigned smoke; false = signed IPA
      export_method: "ad-hoc"
      export_options_plist: ""
      build_for_testing: false
      build_args: ""
      deployable_artifact_type: "ipa"
```

| Field | Description |
|---|---|
| `enabled` | Set `false` to skip iOS entirely from the matrix |
| `runner_set` | Must be a macOS runner (`macos-latest`, `macos-15`, or self-hosted macOS) |
| `xcode_version` | Exact Xcode version selected by the setup action. Must be available on the runner image |
| `scheme` | Xcode scheme to build. `Runner` is the default for Flutter apps. Change for multi-scheme projects |
| `sdk` | `iphoneos` for device/archive builds. Use `iphonesimulator` for simulator-only smoke tests |
| `destination` | `generic/platform=iOS` for archive builds. Required for IPA creation |
| `configuration` | Xcode build configuration. `Release` for production artifacts |
| `codesign` | `true` to produce a signed IPA; `false` for unsigned smoke builds. Requires signing secrets when `true` |
| `unsigned` | Mirror of `codesign` — set `true` when `codesign` is `false` |
| `export_method` | `ad-hoc` (device testing), `app-store` (App Store Connect), `enterprise`, or `development` |
| `export_options_plist` | Optional path to a custom `ExportOptions.plist`. Leave empty to use the blueprint default |
| `build_for_testing` | `true` to produce an XCTest-compatible artifact for XCUITest runs on Firebase Test Lab |
| `build_args` | Extra flags passed verbatim to the iOS build step |
| `deployable_artifact_type` | `ipa` — only valid when `codesign: true` and an IPA is produced |

### iOS Build Outputs

| Artifact | Path | When |
|---|---|---|
| Signed IPA | `build/ios/ipa/*.ipa` | `codesign: true` |
| Unsigned smoke ZIP | `build/ios/smoke/unsigned-ios-app.zip` | `codesign: false`, `unsigned: true` |

### Required GitHub Secrets for iOS Signing

Add these secrets at the organization or repository level before enabling signed builds:

| Secret | Description |
|---|---|
| `APPLE_BUILD_CERTIFICATE_BASE64` | Base64-encoded `.p12` distribution certificate |
| `APPLE_BUILD_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate |
| `APPLE_BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `.mobileprovision` matching the bundle identifier |
| `APPLE_KEYCHAIN_PASSWORD` | Temporary keychain password (can be any strong random string) |

> The bundle identifier in `ios/Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`) and the
> `DEVELOPMENT_TEAM` must exactly match the values in the provisioning profile.

---

## Per-Environment Inputs

**Location:** `.cloudopsworks/vars/inputs-<environment>.yaml`

Each environment file overrides only the fields that differ from `inputs-global.yaml`.
Keep all three standard environments unless a subset is intentional:

| File | GitFlow trigger |
|---|---|
| `inputs-dev.yaml` | Pushes to `develop` |
| `inputs-uat.yaml` | Pushes/tags on `release/**` |
| `inputs-prod.yaml` | Tags on `main`/`master` |

### Minimal Override Example

```yaml
# inputs-dev.yaml — dev environment overrides
environment: "dev"
runner_set: "ubuntu-latest"

android:
  configuration: Release

xcode:
  configuration: Release
```

### Full Example with AWS Device Farm

The `platforms` block under `aws` defines the device(s) used for this environment's
test run. Omit `device_farm_pool` to target a specific device instead of a pool.

```yaml
# inputs-dev.yaml
environment: "dev"
runner_set: "ubuntu-latest"

android:
  configuration: Release

xcode:
  configuration: Release

flutter:
  matrix:
    android:
      enabled: true
      runner_set: "ubuntu-latest"
      sdk: "32"
      destination: "Pixel 6"
      configuration: "Release"
      artifact_types:
        - apk
      deployable_artifact_type: "apk"
      split_per_abi: false
      build_args: ""
    ios:
      enabled: true
      runner_set: "macos-latest"
      xcode_version: "16.4"
      scheme: "Runner"
      sdk: "iphoneos"
      destination: "generic/platform=iOS"
      configuration: "Release"
      codesign: true
      unsigned: "false"
      export_method: "ad-hoc"
      export_options_plist: ""
      build_for_testing: false
      build_args: ""
      deployable_artifact_type: "ipa"

aws:
  region: us-west-2
  build_sts_role_arn: "arn:aws:iam::123456789012:role/build-publisher-products-main-prod-001-usea1"
  deploy_sts_role_arn: "arn:aws:iam::123456789012:role/devicefarm-publisher-products-main-prod-001-usea1"
  device_farm_name: "my-app-products-main-prod-001-uswe2"
  platforms:
    android:
      device:
        form_factor: "PHONE"
        model: "Google Pixel 9"
        os_version: "16"
        max_devices: 1
      test_script_path: "test-scripts"
      test_script_type: "BUILTIN_FUZZ"
    ios:
      device:
        form_factor: "PHONE"
        model: "Apple iPhone 14 Pro"
        os_version: "17.3.1"
        max_devices: 1
      test_script_path: "RunnerUITests"
      test_script_type: "BUILTIN_FUZZ"
```

### Full Example with GCP Firebase Test Lab

```yaml
# inputs-dev.yaml (GCP variant)
environment: "dev"
runner_set: "ubuntu-latest"

android:
  configuration: Release

xcode:
  configuration: Release

gcp:
  region: "us-central"
  project_id: "my-project-001"
  build_impresonate_sa: "build-publisher@my-project-001.iam.gserviceaccount.com"
  deploy_impersonate_sa: "fb-test-lab-runner-prod-001@my-project-001.iam.gserviceaccount.com"
  test_lab_bucket: "test-lab-store-products-gcloudfirebase-prod-001-7831"
  platforms:
    android:
      devices:
        - model_id: "shiba"        # Pixel 8
          version_id: "34"
          locale_id: "en_US"
          orientation: "landscape"
        - model_id: "caiman"       # Pixel 9 Pro
      test_script_path: "test-scripts"
      test_script_type: "robo"
    ios:
      devices:
        - model_id: "iphone11pro"
          version_id: "16.6"
          locale_id: "en_US"
          orientation: "landscape"
        - model_id: "iphone14pro"
      test_script_path: "RunnerUITests"
      test_script_type: "xctest"
```

> **Tip — listing available devices:**
> ```bash
> # AWS Device Farm — Android
> aws devicefarm list-devices --region us-west-2 \
>   --filters attribute=PLATFORM,operator=EQUALS,values=Android \
>   --query 'devices[].[model,formFactor,os]' --output table
>
> # AWS Device Farm — iOS
> aws devicefarm list-devices --region us-west-2 \
>   --filters attribute=PLATFORM,operator=EQUALS,values=IOS \
>   --query 'devices[].[model,formFactor,os]' --output table
>
> # GCP Firebase — Android models
> gcloud firebase test android models list
>
> # GCP Firebase — iOS models
> gcloud firebase test ios models list
> ```

### Template Placeholder Files

The template ships two placeholder files that **must not be used as live environments
without replacing all placeholder values**:

| File | Purpose |
|---|---|
| `inputs-ANDROID-ENV.yaml` | Documents all Android/AWS/GCP fields; rename to `inputs-dev.yaml` etc. |
| `inputs-XCODE-ENV.yaml` | Documents all iOS/AWS/GCP fields; rename to environment files as needed |

Remove files for environments you do not deploy.

---

## Cloud Deployment

### Global Fields

Set these in `inputs-global.yaml` to enable deployment from `main-build.yml`:

```yaml
cloud: "aws"              # aws | gcp
cloud_type: "device-farm" # device-farm (aws) | firebase-test-lab (gcp)
runner_set: "ubuntu-latest"
```

### AWS Device Farm

**Required secrets / IAM:**

| Field | Description |
|---|---|
| `aws.region` | AWS region where Device Farm is available (usually `us-west-2`) |
| `aws.device_farm_name` | The Device Farm project name |
| `aws.build_sts_role_arn` | IAM role ARN with permissions to publish build artifacts |
| `aws.deploy_sts_role_arn` | IAM role ARN with permissions to create Device Farm runs |

Artifact types sent to Device Farm:

| Platform | Type |
|---|---|
| Android | `ANDROID_APP` (APK) |
| iOS | `IOS_APP` (IPA — signed) |

### GCP Firebase Test Lab

**Required:**

| Field | Description |
|---|---|
| `gcp.project_id` | GCP project that owns the Firebase project |
| `gcp.build_impresonate_sa` | Service account for artifact publishing (impersonated by the runner SA) |
| `gcp.deploy_impersonate_sa` | Service account for Test Lab run creation |
| `gcp.test_lab_bucket` | GCS bucket used by Test Lab for result storage (must grant SA access) |

Artifact types:

| Platform | Type |
|---|---|
| Android | APK |
| iOS | IPA or XCTest artifact (set `build_for_testing: true`) |

---

## Workflow Reference

| Workflow | File | Purpose |
|---|---|---|
| PR Build | `.github/workflows/pr-build.yml` | Quality checks (analyze, test) and configured platform builds on every PR |
| Main Build | `.github/workflows/main-build.yml` | Release artifact production, workflow artifact upload, scan trigger, and deploy when enabled |
| Deploy | `.github/workflows/deploy.yml` | Deploys previously built mobile artifacts to configured device farms |
| Scan | `.github/workflows/scan.yml` | SAST/SCA/DAST scanning (Snyk, Semgrep, SonarQube, DependencyTrack) |
| Process Owners | `.github/workflows/process-owners.yml` | Validates and reconciles CODEOWNERS and reviewer rules |
| JIRA Integration | `.github/workflows/jira-integration.yml` | JIRA release lifecycle hooks |
| PR Close | `.github/workflows/pr-close.yaml` | Post-PR cleanup |
| Environment Destroy | `.github/workflows/environment-destroy.yml` | Tears down named environments |
| Environment Unlock | `.github/workflows/environment-unlock.yml` | Unlocks stuck deployment environments |
| Patch Management | `.github/workflows/patch-management.yml` | Automated dependency/security patch PRs |

### Main Build — Manual Dispatch

`main-build.yml` accepts a `platforms` input to control which platform matrix rows run:

| Input value | Builds |
|---|---|
| `android` | Android only |
| `ios` | iOS only |
| `android,ios` | Both platforms |

---

## Local Development

```bash
# Install dependencies
flutter pub get

# Analyze
flutter analyze

# Run tests
flutter test

# Android — release APK (universal)
flutter build apk --release

# Android — release AAB (Play Store)
flutter build appbundle --release

# iOS — unsigned smoke build (no certificate required)
flutter build ios --release --no-codesign
```

> **Notes:**
> - Signed IPA creation requires macOS with Xcode, a valid Apple distribution certificate,
>   and a provisioning profile matching the bundle identifier.
> - Avoid committing `build/`, `.dart_tool/`, `ios/build/`, and `ios/Pods/`.

---

## Customization Checklist

### Before the First CI Run

- [ ] Replace `ORG_NAME`, `ORG_UNIT`, `ENV_NAME`, `REPO_OWNER` in `inputs-global.yaml`
- [ ] Set `flutter.platforms` to `[android]`, `[ios]`, or both
- [ ] Choose `android.artifact_types` and `android.deployable_artifact_type`
- [ ] Set iOS `bundle identifier`, `DEVELOPMENT_TEAM`, signing mode, and export method in `ios/Runner.xcodeproj`
- [ ] Create and configure `inputs-dev.yaml`, `inputs-uat.yaml`, `inputs-prod.yaml`
- [ ] Set `cloud` and `cloud_type` only when device-farm deployment is needed
- [ ] Add required GitHub secrets for signing and cloud deployment
- [ ] Run `make code/init`
- [ ] Run `flutter pub get && flutter analyze && flutter test` locally

### Before iOS Deploy

- [ ] Confirm `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj` matches the provisioning profile
- [ ] Confirm `DEVELOPMENT_TEAM` matches the Apple Developer Team ID in the certificate
- [ ] Set `flutter.matrix.ios.codesign: true`
- [ ] Set `flutter.matrix.ios.unsigned: false`
- [ ] Add `APPLE_BUILD_CERTIFICATE_BASE64`, `APPLE_BUILD_CERTIFICATE_PASSWORD`,
      `APPLE_BUILD_PROVISION_PROFILE_BASE64`, `APPLE_KEYCHAIN_PASSWORD` secrets
- [ ] Set `flutter.matrix.ios.export_method` to `ad-hoc`, `app-store`, or `enterprise`

### Before Android Deploy

- [ ] Confirm `applicationId` in `android/app/build.gradle.kts` is final
- [ ] Keep `split_per_abi: false` unless the deploy workflow is adapted for split APKs
- [ ] Configure `aws.platforms.android` or `gcp.platforms.android` device spec in environment files

---

## Upgrade Procedure

Repositories derived from this template stay in sync with upstream releases using the
`make repos/upgrade*` targets. An agent asked to "upgrade", "update from template",
"sync with template", "apply template changes", or "bump template version" should use
these targets — never fetch or apply template changes manually.

### Available upgrade targets

| Target | When to use |
|---|---|
| `make repos/upgrade` | **Default — patch upgrade.** Pulls the latest patch within the **same minor version**. No breaking changes. Use for routine maintenance. |
| `make repos/upgrade/major` | Pulls the latest release within the **same major version**. May include workflow-level changes. |
| `make repos/upgrade/master` | Pulls from the template's `master` branch tip. Use only when explicitly asked to track the latest unreleased template state. |
| `make repos/upgrade/dev` | Pulls from the template's `develop` branch. Use only for pre-release or preview upgrades. |
| `make repos/available` | Lists the latest available patch and major versions without modifying anything. Run this first to see what is available. |

### What the upgrade does

- Updates `.cloudopsworks/_VERSION` to the latest compatible template tag
- Refreshes `.github/workflows/` from the template
- Refreshes `Makefile` and selected Cloud Ops Works metadata
- **Preserves** `lib/`, `test/`, `android/`, `ios/` (application source is never overwritten)

### Upgrade workflow for agents

1. Run `make repos/available` to see the current and latest available versions.
2. Choose the appropriate target (default: `make repos/upgrade` for a routine patch upgrade).
3. Review the diff — the upgrade overwrites `.github/workflows/` and selected `.cloudopsworks/` metadata; application source files are never touched.
4. Validate after upgrading:

```bash
# 1. Verify all YAML is parseable
ruby -e 'require "yaml"; Dir[".github/workflows/*.{yml,yaml}", ".cloudopsworks/**/*.yaml"].each { |f| YAML.load_file(f) }; puts "yaml-ok"'

# 2. Confirm blueprint channel
grep -R "cloudopsworks/blueprints/cd/checkout@v5.10" .github/workflows

# 3. Verify Flutter still builds
flutter pub get && flutter analyze && flutter test
```

5. Commit the result with: `chore: upgrade from fluttermobile template <old-version> → <new-version> +semver: patch`
6. Use `/cw-release` to create and merge the hotfix PR (see [Release Workflow — use `cw-release`](#release-workflow--use-cw-release)).

> **Note:** `Makefile`, `.github/`, `.cloudopsworks/labeler.yml`, `.cloudopsworks/Makefile`,
> and `.cloudopsworks/LICENSE` are owned by the template and will be overwritten on every upgrade.
> Do not edit these files manually in derived repositories.

---

## Troubleshooting

### Checkout action: "No module marker file found"

**Symptoms:**
- `No module marker file found in .cloudopsworks directory`
- The checkout action attempts to query `https://github.com/.git`

**Checks:**
1. Confirm `.cloudopsworks/.fluttermobile` exists in the repository root
2. Confirm all workflows use `cloudopsworks/blueprints/cd/checkout@v5.10`
3. Confirm `blueprint_ref: v5.10` appears in workflow inputs

---

### Android Build Fails

**Checks:**
1. Run `flutter doctor -v` and resolve any SDK issues
2. Run `flutter pub get`
3. Verify `android/app/build.gradle.kts` — `applicationId`, `compileSdk`, `minSdk`, `targetSdk`
4. Confirm `artifact_types` contains `apk` and/or `appbundle` (not empty)

---

### iOS Build Fails

**Checks:**
1. Confirm the runner image has the requested `xcode_version` (`xcodebuild -version`)
2. Confirm `ios/Runner.xcodeproj` exists; `Runner.xcworkspace` is optional for default Flutter apps
3. For signed builds: verify all four Apple secrets exist and the bundle identifier matches the provisioning profile
4. For smoke builds: confirm `codesign: false` and `unsigned: true` — do not provide signing secrets

---

### Deploy Cannot Find Artifact

**Checks:**
1. For Android: confirm the build produced an APK when `deployable_artifact_type: apk`
   — check `build/app/outputs/flutter-apk/`
2. For iOS: confirm the signed build produced an IPA when `deployable_artifact_type: ipa`
   — check `build/ios/ipa/`
3. Confirm workflows reference the `v5.10` blueprint channel — this version includes
   the nested artifact lookup fixes for mobile deploys

---

### Device Farm Upload Fails

**Checks:**
1. **AWS:** Confirm the `deploy_sts_role_arn` has `devicefarm:CreateUpload`,
   `devicefarm:GetUpload`, `devicefarm:ScheduleRun`, and `devicefarm:GetRun` permissions
2. **GCP:** Confirm the service account has `Firebase Test Lab Admin` and
   `Storage Object Admin` on the test lab bucket
3. Confirm `cloud_type` matches the provider (`device-farm` for AWS, `firebase-test-lab` for GCP)
4. Confirm the environment input file contains the correct `platforms.android` or
   `platforms.ios` device specification

---

## Maintenance Policy

### Simplicity

- Prefer `inputs-global.yaml` and per-environment overrides over editing workflow files directly
- Keep Android and iOS matrix rows explicit — avoid hidden Cartesian products
- Reusable CI behavior belongs in `cloudopsworks/blueprints`; scaffolding belongs in this template

### Reuse Boundaries

| Layer | Belongs in |
|---|---|
| Shared GitHub Action behavior | `cloudopsworks/blueprints` |
| Default workflow configuration, scaffold | This template |
| Bundle IDs, signing profiles, deployment targets | Derived application repositories |

### Maintainability

- Keep workflow blueprint refs on `v5.10` unless intentionally moving to a new minor channel
- Remove unused placeholder environment files from derived repositories
- Use Conventional Commits with `+semver: patch` for all routine changes
- Always run `flutter analyze` and `flutter test` before claiming an upgrade complete
- Validate YAML after any manual edits:
  ```bash
  ruby -e 'require "yaml"; Dir[".github/workflows/*.{yml,yaml}"].each { |f| YAML.load_file(f) }; puts "ok"'
  ```

---

## Upgrading from the Template

Repositories derived from this template stay in sync with upstream releases using the
`make repos/upgrade*` targets. An agent asked to "upgrade", "update from template",
"sync with template", "apply template changes", or "bump template version" should use
these targets — never fetch or apply template changes manually.

### Available upgrade targets

| Target | When to use |
|---|---|
| `make repos/upgrade` | **Default — patch upgrade.** Pulls the latest patch within the **same minor version**. No breaking changes. Use for routine maintenance. |
| `make repos/upgrade/major` | Pulls the latest release within the **same major version**. May include workflow-level changes. |
| `make repos/upgrade/master` | Pulls from the template's `master` branch tip. Use only when explicitly asked to track the latest unreleased template state. |
| `make repos/upgrade/dev` | Pulls from the template's `develop` branch. Use only for pre-release or preview upgrades. |
| `make repos/available` | Lists the latest available patch and major versions without modifying anything. Run this first to see what is available. |

### Upgrade workflow for agents

1. Run `make repos/available` to see the current and latest available versions.
2. Choose the appropriate target (default: `make repos/upgrade` for a routine patch upgrade).
3. Review the diff — the upgrade overwrites `.github/workflows/` and selected `.cloudopsworks/` metadata; application source files are never touched.
4. Commit the result with: `chore: upgrade from <template-name> <old-version> → <new-version> +semver: patch`
5. Use `/cw-release` to create and merge the hotfix PR (see [Release Workflow — use `cw-release`](#release-workflow--use-cw-release)).

> **Note:** `Makefile`, `.github/`, `.cloudopsworks/labeler.yml`, `.cloudopsworks/Makefile`,
> and `.cloudopsworks/LICENSE` are owned by the template and will be overwritten on every upgrade.
> Do not edit these files manually in derived repositories.

---

## AI-assisted upgrade of `.cloudopsworks/vars` configuration files

This section is a machine-readable protocol for AI agents performing a seamless, non-destructive upgrade of all configuration files under `.cloudopsworks/vars/` when a new template version is released. Follow the steps below in order.

### Upgrade overview

The template version locked into this repository is recorded in `.cloudopsworks/_VERSION`. The canonical upstream source is the GitHub repository `cloudopsworks/fluttermobile-app-template`, pinned to the tag that matches the content of `_VERSION`.

An upgrade merges new keys, updated comments, and structural changes from the upstream template into local files **without overwriting values the operator has already set**.

---

### Step 1 — determine current and target versions

1. Read `.cloudopsworks/_VERSION` to get the **current locked version** (e.g., `v1.0.15`).
2. The **target version** is either supplied by the operator or is the latest release tag on `cloudopsworks/fluttermobile-app-template`.
3. Fetch any upstream file from GitHub using the pattern:
   ```
   https://raw.githubusercontent.com/cloudopsworks/fluttermobile-app-template/<version>/<path>
   ```
   Example:
   ```
   https://raw.githubusercontent.com/cloudopsworks/fluttermobile-app-template/v1.0.15/.cloudopsworks/vars/inputs-global.yaml
   ```

---

### Step 2 — identify the deployment type for each environment file

Each `inputs-<name>.yaml` file under `.cloudopsworks/vars/` maps to a specific upstream template. For Flutter mobile repositories the filename is definitive — `cloud` and `cloud_type` in `inputs-global.yaml` are not used for mapping.

**File name → upstream template file:**

| File name                 | Upstream template file    |
|---------------------------|---------------------------|
| `inputs-ANDROID-ENV.yaml` | `inputs-ANDROID-ENV.yaml` |
| `inputs-XCODE-ENV.yaml`   | `inputs-XCODE-ENV.yaml`   |

`inputs-global.yaml` always maps to the upstream `inputs-global.yaml` regardless of platform.

---

### Step 3 — upgrade deployment target files

The deployment target files identified by the Step 2 mapping table — such as `inputs-KUBERNETES-ENV.yaml`, `inputs-LAMBDA-ENV.yaml`, `inputs-BEANSTALK-ENV.yaml`, `inputs-APPENGINE.yaml`, `inputs-CLOUDRUN.yaml`, `inputs-LIB-ENV.yaml`, and mobile equivalents such as `inputs-ANDROID-ENV.yaml` and `inputs-XCODE-ENV.yaml` — are **scaffolding templates**. They provide placeholder structures and documented examples, not finalized operator configuration.

**Do not merge these files. Overwrite them.**

Upgrade procedure for each deployment target file:

1. **Before overwriting** — inspect the local file and record any operator-configured values (keys that have been uncommented and set to non-placeholder values).
2. **Replace the file** — overwrite the local file entirely with the upstream template version.
3. **Re-apply operator values** — after overwriting, set each previously recorded operator-configured value at its corresponding key in the new file.
4. **Copy in absent files** — if a deployment target file is present in the upstream template but absent locally, copy it in from the upstream template as a new file.

---

### Step 4 — merge `inputs-global.yaml`

`inputs-global.yaml` requires special handling because it contains mandatory operator identity fields alongside a large body of optional commented-out sections.

Merge procedure:

1. **Retain the four mandatory identity fields** verbatim at the top of the file:
   ```yaml
   organization_name: "..."
   organization_unit: "..."
   environment_name: "..."
   repository_owner: "..."
   ```
2. **Retain `cloud` and `cloud_type`** exactly as the operator set them.
3. **For every optional commented-out section** in the upstream template, check the local file:
   - If the operator **has uncommented and configured it** — keep the operator's values; update only surrounding comment text if it changed upstream.
   - If the section **is still fully commented out locally** — replace the entire commented block with the upstream version, capturing any new fields or updated documentation within it.
4. **Append new optional sections** that appear in the upstream template but are entirely absent locally, in fully commented-out form, preserving their upstream position and comments.

---

### Step 5 — upgrade subdirectory files

Apply the merge rules from Step 4 to every file in the following subdirectories, matching each local file to its corresponding upstream file at the same relative path:

- `.cloudopsworks/vars/preview/inputs.yaml`
- `.cloudopsworks/vars/preview/values.yaml`
- `.cloudopsworks/vars/apigw/apis-global.yaml`
- `.cloudopsworks/vars/apigw/apis-dev.yaml`
- `.cloudopsworks/vars/apigw/apis-uat.yaml`
- `.cloudopsworks/vars/apigw/apis-prod.yaml`
- `.cloudopsworks/vars/helm/values-dev.yaml`
- `.cloudopsworks/vars/helm/values-uat.yaml`
- `.cloudopsworks/vars/helm/values-prod.yaml`

---

### Step 6 — update `_VERSION`

After all merges are verified correct, write the target version string (e.g., `v1.0.16`) to `.cloudopsworks/_VERSION`. This is the final step.

---

### Upgrade invariants

An agent performing this upgrade must **never**:

- Overwrite a field the operator has explicitly set to a non-placeholder value.
- Remove a commented-out operator value without first reporting it.
- Change the YAML structure of any active (uncommented) operator section.
- Alter a file's opening description comment (`# This file contains...`) unless the upstream version changed it.
- Modify `.cloudopsworks/cloudopsworks-ci.yaml`, `gitversion_*.yaml`, or any file under `.github/workflows/` as part of a vars upgrade — those follow their own upgrade path.
- Update `_VERSION` before all file merges are complete.

---

### Conflict resolution

When a merge cannot be resolved automatically (for example, the upstream template restructured a section that the operator has customized):

1. Emit a diff showing both the upstream template block and the local operator block side by side.
2. Pause and present the conflict to the operator, asking which version to keep or whether a manual merge is needed.
3. Never silently choose one side.

---

## Release Workflow — use `cw-release`

All releases **must** be performed using the `cw-release` skill from the CloudOps Works skill set. Do **not** create release branches, hotfix branches, version tags, or release PRs manually — the skill owns the full GitFlow-aware release lifecycle for this repository.

### When to invoke `cw-release`

Use it whenever you are asked to:
- Release, ship, or publish a new version (patch, minor, or major)
- Create a hotfix or patch release
- Create a release branch or feature-merge PR
- Tag and publish a version

### How to run it

In Claude Code (CLI, IDE extension, or web):

```
/cw-release
```

### What the skill does

1. Detects the GitVersion flow in use (`gitversion_gitflow.yaml` or `gitversion_githubflow.yaml`).
2. Reads the repo-local release policy from `.cloudopsworks/cloudopsworks-ci.yaml`.
3. Drives the shared tronador `make` / `gh` release path end-to-end.
4. Creates the correct branch, PR, tag, and GitHub Release in the right sequence.

> **Do not** run `git tag`, `gh release create`, or `make release` directly. Always let `cw-release` orchestrate these steps to keep version history and CI consistent.
