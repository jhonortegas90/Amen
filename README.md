# Amen

Amen is a Flutter/Firebase mobile app for an anonymous global prayer wall. The selected visual direction is `Lightwell`: dark glass, warm amber glow, quiet motion, and no social toxicity.

## What Is Implemented

- Fresh Flutter app scaffold for iOS and Android.
- Firebase-ready bootstrap for project `amen-b2dc0`.
- Riverpod feature architecture for auth, intentions, ads, notifications, moderation, localization, and design system.
- Dark Lightwell UI: pinned prayer, live-style feed, compose sheet, animated Amen button, haptics, and ambient background motion.
- English, Spanish, and French localization strings, plus ARB base files in `lib/l10n`.
- Demo repository fallback so the app runs before real Firebase app credentials are installed.
- Firestore rules, indexes, and TypeScript Cloud Functions for `createIntention`, `sayAmen`, `pinIntention`, and pin expiry.
- AdMob test app IDs and ad-service scaffolding for interstitial and rewarded flows.

## Run Locally

```sh
flutter pub get
flutter run
```

Without Firebase app options, Amen runs in demo mode. To connect the live project, install Firebase CLI and FlutterFire CLI, then configure `amen-b2dc0`:

```sh
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure --project=amen-b2dc0
```

The current bootstrap also supports dart-defines:

```sh
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
```

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug
cd functions && npm install && npm run build
```

## Design Reference

The selected generated mock is saved at `docs/design/lightwell-reference.png`, with notes in `docs/design/lightwell.md`.
