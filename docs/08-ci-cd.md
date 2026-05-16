# 08 — CI/CD

## Workflows
Two GitHub Actions workflows live in `.github/workflows/`.

### `ci.yml` — on every PR and push to `main`
The `analyze-and-test` job: checkout → set up Flutter (stable) → `flutter pub
get` → `build_runner build` → `dart format` check → `flutter analyze
--fatal-infos` → `flutter test --coverage` → upload `lcov.info`. A second job,
`build-android`, runs `flutter build apk --debug` so every PR proves the app
still builds to a device target. A pull request cannot merge unless both jobs
are green.

### `build.yml` — on a `v*` tag or manual dispatch
Builds a release Android APK and an unsigned iOS build and uploads them as
artifacts. Signing and store upload are added in milestone M11.

## Branching model
- `main` is always releasable and protected.
- Work happens on short-lived branches named `m<NN>/<task-id>-<slug>`, e.g.
  `m01/m1-t05-core-tables`.
- One pull request per task (or per a small group of tightly-coupled tasks).
  The PR description references the task ID.

## Branch protection (configure on GitHub)
- Require `ci.yml` to pass before merge.
- Require the branch to be up to date with `main`.
- Disallow direct pushes to `main`.

## Commits
Conventional Commits: `feat:`, `fix:`, `test:`, `chore:`, `refactor:`, `docs:`.
The subject line stays under ~72 characters and references the task:
`feat(accounts): add AccountsDao [M1-T13]`.

## Versioning
`pubspec.yaml` holds `version: <semver>+<build>`. Completing a milestone bumps
the minor version; pushing a `v<semver>` tag triggers `build.yml`.

## Reproducible toolchain
CI currently uses Flutter channel `stable`. **Pin an exact version** once the
team settles on one: set `flutter-version:` in `subosito/flutter-action` and add
a project `.fvmrc` so local and CI match.

> Toolchain note: the SDK found at `/Users/emilhansen/code/flutter` reports
> `3.7.0` in its `version` file and its cache is not yet built. Task `M0-T01`
> must run `flutter --version`, confirm it is ≥ 3.24 (Dart ≥ 3.5), and upgrade
> the SDK if it is not — the dependency versions in `pubspec.yaml` require it.

## Secrets (added in M11, never committed)
- Android: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`.
- iOS: an App Store Connect API key, plus a Fastlane `match` git repo and
  passphrase.
All are stored as GitHub Actions repository secrets. `android/key.properties`
and any `*.env` file are git-ignored.

## Future CI additions
- A coverage gate (fail the build under threshold) once coverage is stable.
- Golden-image tests run on a fixed runner.
- Automated TestFlight / Play internal-testing distribution (M11).
