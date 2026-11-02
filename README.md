# Quran Memorization Supervisor App

A Flutter (Android) mobile app for supervisors of Quran memorization circles. Supervisors log in,
manage their students, track memorization progress and receive notifications.
The UI is Arabic (RTL). The app talks to a Laravel REST API (backend not included).

## Features
- Phone number + password login with token-based auth (Bearer token stored locally)
- Student list with pagination, student details, and add-student form
- Memorization progress chart (`fl_chart`)
- Notifications list and details, with unread counter polled in the background (Provider)
- Offline support: connectivity banner and a local cache that shows the last successful response
  immediately while fresh data loads (stale-while-revalidate)
- Request retry on transient network failures, shimmer loading placeholders,
  and user-friendly translated error messages

## Structure (`lib/`)
| Folder | Purpose |
|--------|---------|
| `constants/` | Colors, strings, dimensions, routes, API settings |
| `services/` | `ApiService` (HTTP), `ApiResponseParser` + `ApiException` (typed errors), `TokenManager` (secure storage), `LocalCache`, `ConnectivityService` |
| `providers/` | `NotificationProvider` (state management with Provider) |
| `model/` | Data models |
| `screens/` | Login, home, students, add student, details, diagram, notifications |
| `widgets/` | Reusable widgets (app bar, offline banner, shimmer, number stepper, student card, sort chip, add-parts dialog) |
| `utils/` | Screen sizing helper, debug-only logger |

## Tech
Flutter, Dart, `provider`, `http`, `flutter_secure_storage`, `shared_preferences`, `fl_chart`, `connectivity_plus`

## Setup
1. Put this `lib/` folder in a Flutter project named `quran` (imports use `package:quran/...`)
   and add the logo at `assets/images/quran_logo.png`.
2. Set your backend URL in `lib/constants/constants.dart` (`ApiSettings.baseUrl`).
3. Add the secure-storage dependency: `flutter pub add flutter_secure_storage`
   (Android needs `minSdkVersion 23` or higher in `android/app/build.gradle`).
4. `flutter pub get` then `flutter run`.

## Tests
`test/` contains unit tests for the API error handling (`ApiResponseParser`, `ApiException`, `userMessageFor`).
Copy the `test/` folder next to `lib/` and run `flutter test`.

> The real backend URL was removed from this public copy. Without a backend the screens
> beyond login cannot load data.

## Design decisions
- **Adaptive, lifecycle-aware polling** (`NotificationProvider`): the unread counter is polled every few seconds,
  slows down step by step while nothing changes, resets to fast polling on new activity, pauses when the app
  goes to the background, and skips requests when offline. This saves battery and data compared with a fixed timer.
- **Stale-while-revalidate cache** (`LocalCache`): screens show the last successful response immediately
  (or when offline) and refresh in the background.
- **Retry only for GET requests**: transient network failures are retried with growing delays
  (1s, 4s). Write requests such as `addStudent` are never retried automatically, to avoid creating duplicate records.
- **Typed errors instead of string matching**: `ApiResponseParser` turns an HTTP status and body into an
  `ApiException` (type + message + status code), and `userMessageFor` maps it to a clear Arabic message.
  Screens no longer inspect exception text, and only network/timeout errors are retried.
- **Secure token storage**: the auth token lives in `flutter_secure_storage` (Android Keystore).
  Users logged in with the old version are migrated once from `shared_preferences`, so nobody is logged out.
- **Debug-only logging** through `appLog`, so no sensitive data reaches release logs.

## Known limitations / next steps
- Student data is passed around as `Map<String, dynamic>`; a typed `Student` model (with `fromJson`) would catch
  key typos at compile time. Only notifications have a model so far.
- `ApiService` is a static class, which makes it hard to mock; injecting it (or wrapping it in a repository)
  would make the screens testable.
- Fetching, pagination and caching for students live inside `students_screen`; moving them into a
  `StudentsProvider`, as done for notifications, would separate logic from UI.
- `diagram_screen` is still large (about 700 lines) and could be split into smaller widgets,
  as was already done for the students screen.
- `LocalCache` stores cached API responses in plain `shared_preferences`; it should be cleared on logout.
- Only the error-handling layer has unit tests; widget and integration tests are the next step.
- The unread-notifications endpoint returns a bare JSON list, so it is parsed separately from the other endpoints.

## Notes
- This repository contains the app source only (`lib/`), not the Android/iOS platform folders.
- Logging goes through `appLog`, which prints in debug builds only and never logs
  response bodies, phone numbers or tokens.

## Author
Rakia Omar Al Labani
