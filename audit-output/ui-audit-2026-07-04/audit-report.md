# Amen UI Audit - 2026-07-04

## Scope

Audited the Flutter app for overlap, overflow, centered text issues, responsive widget/text/icon sizing, localization coverage, text clipping, and double-line risks.

Evidence used:

- Live web screenshots from `http://127.0.0.1:5367`
- Source review of screens, modal sheets, routing, localization, and responsive layout patterns
- `flutter analyze`
- `flutter test`

## Captured Steps

1. `01-mobile-start.png` - Mobile onboarding, 390 x 844: unhealthy. Main glass card is clipped off the right edge and auth actions are not visible in the captured viewport.
2. `02-desktop-onboarding.png` - Desktop onboarding, 1440 x 900: unhealthy. Main content occupies the left portion of the viewport, with large unused black space to the right; auth actions are still not visible.
3. `03-mobile-shell-pray.png` - Mobile shell / Pray tab: unhealthy. Header text clips off the right edge instead of wrapping.
4. `04-desktop-shell-pray.png` - Desktop shell / Pray tab: partially healthy. Text fits on desktop, but the page is mostly empty because data/auth startup failed.
5. `06-mobile-hash-library.png` - Mobile Library route: unhealthy. App bar, search hint, card titles, and metadata are clipped off the right edge.
6. `06-mobile-hash-notifications.png` - Mobile Notifications route: blocked/partial. Header renders, but feed content is blocked by startup/auth/provider state.
7. Source localization and layout review: unhealthy. Many user-facing strings are hardcoded outside localization, and several rows use fixed horizontal layouts that will break under longer translations or larger font settings.

## Findings

1. Critical mobile horizontal clipping is visible across multiple screens.

Evidence: `01-mobile-start.png`, `03-mobile-shell-pray.png`, and `06-mobile-hash-library.png`.

Observed impact: users on phone-width viewports cannot read full headings, card text, search hints, or onboarding copy. This affects first-run onboarding, the Pray shell, and Library content.

Relevant code:

- `lib/src/features/auth/presentation/onboarding_screen.dart:83` uses a non-scrollable `Column` with spacers for the whole onboarding layout.
- `lib/src/features/auth/presentation/onboarding_screen.dart:86` scales the logo by `1.5`, increasing layout pressure.
- `lib/src/features/library/presentation/library_screen.dart:41` uses a long all-caps app bar title with letter spacing.
- `lib/src/features/library/presentation/library_screen.dart:197` uses a metadata `Row` without flexible handling around category/read-time text.
- `lib/src/features/pray/presentation/pray_wall_screen.dart:190` uses a header `Row`; the title/subtitle section can still be clipped in the captured mobile render.

2. Onboarding is not resilient to viewport height or long localized text.

Evidence: `01-mobile-start.png`, `02-desktop-onboarding.png`.

Observed impact: the primary auth actions are not visible in the captured states. The layout depends on `Spacer` distribution and has no scroll fallback.

Relevant code:

- `lib/src/features/auth/presentation/onboarding_screen.dart:83`
- `lib/src/features/auth/presentation/onboarding_screen.dart:146`
- `lib/src/features/auth/presentation/onboarding_screen.dart:179`
- `lib/src/features/auth/presentation/onboarding_screen.dart:308` forces auth button labels to one line with fade overflow and no wrapping.

3. Localization coverage is incomplete and inconsistent.

Supported locales are `en`, `es`, and `fr` in `lib/src/localization/app_localizations.dart`, but the ARB files only contain 11 entries each while the custom localization class contains dozens of getters. The app uses the custom class from `lib/src/app.dart`, so the ARB files are stale or misleading.

Hardcoded user-facing examples:

- Onboarding: `lib/src/features/auth/presentation/onboarding_screen.dart:110`, `:131`, `:220`
- Community: `lib/src/features/community/presentation/community_screen.dart:27`, `:33`, `:65`, `:70`, `:127`
- Journal: `lib/src/features/journal/presentation/journal_screen.dart:78`, `:99`, `:104`, `:109`, `:252`
- Library: `lib/src/features/library/presentation/library_screen.dart:42`, `:59`, `:136`, `:213`
- Notifications: `lib/src/features/notifications/presentation/notifications_screen.dart:56`, `:109`, `:120`, `:159`, `:169`, `:179`, `:318`, `:326`
- Profile: `lib/src/features/profile/presentation/profile_screen.dart:57`, `:141`, `:149`, `:199`, `:337`, `:406`, `:464`, `:592`, `:618`, `:652`, `:690`
- Compose sheet: `lib/src/features/intentions/presentation/widgets/compose_sheet.dart:80`, `:147`, `:152`, `:176`, `:185`
- Support message modal: `lib/src/features/notifications/presentation/widgets/send_support_message_modal.dart:45`, `:64`, `:94`, `:186`, `:248`, `:282`, `:310`, `:347`

4. Several fixed horizontal rows are likely to overflow with Spanish/French text or 160% text scale.

High-risk examples:

- `lib/src/features/notifications/presentation/notifications_screen.dart:46` header row combines back button, title, unread badge, and "Read All" button.
- `lib/src/features/notifications/presentation/notifications_screen.dart:155` packs three equal filter chips into one row.
- `lib/src/features/community/presentation/community_screen.dart:287` uses `ListTile.trailing` with two icon buttons.
- `lib/src/features/journal/presentation/journal_screen.dart:169` uses three equal metric tiles in a row.
- `lib/src/features/notifications/presentation/widgets/send_support_message_modal.dart:299` puts a checkbox and long label in a plain row without `Expanded`.
- `lib/src/features/auth/presentation/onboarding_screen.dart:225` puts privacy and terms links in one centered row.

5. Text and icon sizes are mostly fixed instead of responsive.

Examples:

- `lib/src/features/shell/presentation/widgets/water_bottom_navigation.dart:139` fixes nav height at 64.
- `lib/src/features/shell/presentation/widgets/water_bottom_navigation.dart:255` fixes nav icons at 20/22 and labels at 11.
- `lib/src/features/auth/presentation/onboarding_screen.dart:71` fixes logo size and then applies `Transform.scale`.
- `lib/src/features/notifications/presentation/widgets/send_support_message_modal.dart:321` fixes the primary submit button height at 50.
- `lib/src/features/auth/presentation/onboarding_screen.dart:281` fixes auth button height at 58.

6. Runtime startup issues limit the reliability of the visual audit.

Browser console captured:

- `google_sign_in_web`: `serverClientId is not supported on Web`
- `firebase_auth/admin-restricted-operation`: anonymous sign-in is restricted

Relevant code:

- `lib/src/features/auth/data/auth_repository.dart:29` passes `serverClientId` into `GoogleSignIn` even on web.
- `lib/src/app.dart:31` calls `ensureSignedIn()` during app startup.

This prevented a clean full-flow audit of all tabs and some notification states in the live web run.

## Strengths

- The app has a custom localization provider with `en`, `es`, and `fr` support.
- Many main surfaces are built with `CustomScrollView`, `ListView`, `Expanded`, and `Wrap`, which gives a good base for fixing responsiveness.
- Motion code checks reduced-motion settings in key places.
- Bottom navigation uses `FittedBox` for labels, which helps prevent nav label overflow.

## Recommended Fix Order

1. Fix web startup/auth errors so the app can be audited and tested route by route.
2. Add scroll/height resilience to onboarding and remove the large scaled-logo layout pressure.
3. Fix the global mobile horizontal clipping seen in onboarding, shell, and Library.
4. Choose one localization source of truth: generated ARB files or the custom `AppLocalizations` class. Then move all hardcoded user-facing text into it.
5. Add responsive widget tests at 320, 390, and 430 px widths with `textScaleFactor` or `TextScaler` at 1.0, 1.3, and 1.6.
6. Replace fixed packed rows with wrapping, stacked mobile layouts, or adaptive `LayoutBuilder` branches.

## Verification

- `flutter analyze`: 2 info-level deprecation warnings in `report_dialog.dart`; no layout issues caught.
- `flutter test`: all tests passed.

## Evidence Limits

This is not a full WCAG audit. Screenshots can show clipping, overlap, and visible hierarchy problems, but they do not prove keyboard access, screen-reader order, or contrast compliance. The web runtime auth errors also prevented a complete live walkthrough of every tab state.
