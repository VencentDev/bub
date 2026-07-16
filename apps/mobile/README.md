# app_mobile

Flutter (Dart) mobile client for the monorepo backend. See
[`docs/adr/0007-flutter-for-mobile.md`](../../docs/adr/0007-flutter-for-mobile.md)
for the architecture decisions.

## Prerequisites

- Flutter SDK (stable channel) and Dart
- A running backend (`make dev` from the repo root → backend on `:8080`)
- A Google OAuth client (iOS/Android type) — see below

## Setup

```bash
cd apps/mobile
flutter pub get
make -C ../.. mobile-gen   # or: dart run swagger_parser && dart run build_runner build -d
```

`mobile-gen` generates the typed API client from `packages/api-types/openapi.json`
(the same spec the web app uses). Generated code under `lib/src/api/generated/`
is git-ignored and regenerated in CI.

## Configuration

Auth uses native Google Sign-In; the access token is sent to the backend as a
bearer token (ADR-006). Configure Google Cloud before filling in `.env`:

- Create or keep a **Web application** OAuth client. Its client ID is the value
  for `GOOGLE_CLIENT_ID` because the Android Google Sign-In SDK uses it as
  `serverClientId`.
- Create an **Android** OAuth client in the same Google Cloud project. Android
  debug builds use package name `com.app.app_mobile`.
- Get your debug keystore SHA-1 with:

  ```bash
  keytool -list -v -alias androiddebugkey \
    -keystore ~/.android/debug.keystore \
    -storepass android -keypass android | grep SHA1
  ```

- Add that package name and SHA-1 to the Android OAuth client. The Android
  client ID is not placed in `.env`; it just has to exist in the same project.

Then create a local `.env` from `.env.example`, and run:

```bash
cp .env.example .env
flutter run
```

`make -C ../.. mobile-run` runs the same command. The app loads `.env` at
startup, so IDE launch configurations do not need extra Flutter arguments.

- `10.0.2.2` is the Android emulator's alias for the host's `localhost`.
- AppAuth custom redirect schemes are not used for Android sign-in.

> GitHub sign-in is not implemented on mobile yet — it needs a backend
> code-exchange endpoint (ADR-007).

## Common commands

```bash
make -C ../.. mobile-gen    # regenerate the API client
make -C ../.. mobile-run    # flutter run
make -C ../.. mobile-test   # flutter analyze && flutter test
```

## Layout

```text
lib/
  main.dart                     ProviderScope + MaterialApp
  src/
    core/        env.dart, dio_provider.dart (auth interceptor + providers)
    auth/        auth_service.dart (Google OAuth), token_store.dart, auth_controller.dart
    features/    home/home_screen.dart (sign-in + profile)
    api/generated/              generated OpenAPI client (git-ignored)
```
