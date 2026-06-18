# WaterBuddy Error Handling Report

This report outlines the error mapping schemas, exception hierarchies, and user-safe notifications designed to intercept system and database errors without compromising user experience.

---

## 1. Exception Hierarchy & Mapping

All errors are handled through the [exceptions.dart](file:///c:/Users/Pranav/Desktop/waterbuddy-app/apps/waterbuddy_superapp/lib/core/exceptions/exceptions.dart) base class `AppException`. We map raw Firebase exceptions to specialized user-safe classes via `FirebaseExceptionMapper`:

| Raw Firebase Error Code | Mapped Exception Class | User-Friendly UI Display Message |
| --- | --- | --- |
| `permission-denied` | `PermissionException` | "You do not have permission to perform this action." |
| `unavailable` | `NetworkException` | "The database is currently offline. Your updates will sync when you reconnect." |
| `resource-exhausted` | `NetworkException` | "Rate limit exceeded. Please wait a moment before trying again." |
| `not-found` | `StorageException` | "Requested resource could not be found." |
| `already-exists` | `StorageException` | "This record already exists in the system." |
| `timeout` | `NetworkException` | "Connection timed out. Please check your internet connection." |

---

## 2. Interface Protection & Safety
- **Zero Raw Exposure:** Raw database warnings, Firestore index link requirements, or exception stacks are never shown to the user. Tapping a failing element prints the mapped user-friendly error to screen.
- **Auto-Logging:** Any mapped exception calls `logError()`, which records the stacktrace locally in debug builds and prints telemetry events to Firebase Crashlytics in production release compiles.
