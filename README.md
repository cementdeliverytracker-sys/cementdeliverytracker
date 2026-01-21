# Cement Delivery Tracker

Flutter app with role-based dashboards (super-admin, admin, employee) backed by Firebase (Auth, Firestore, Storage, Messaging).

## Architecture at a Glance

- **Feature-first structure** under `lib/features/*` with `data → domain → presentation` layers.
- **DI**: Providers are wired in [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart) and injected at the app root.
- **Auth bootstrap**: Auth state flows through `AuthNotifier`; profile loading and employee-ID assurance live in the auth domain (no direct Firestore in presentation).
- **Admin module**: Use the modular entry [lib/features/dashboard/presentation/pages/admin/pages/admin_dashboard_page.dart](lib/features/dashboard/presentation/pages/admin/pages/admin_dashboard_page.dart) (the wrapper file is kept only for backward compatibility).
- **Shared UI**: Reusable dashboard widgets live in [lib/features/dashboard/presentation/widgets/dashboard_widgets.dart](lib/features/dashboard/presentation/widgets/dashboard_widgets.dart).

## Development Tips

- Run `dart run tool/architecture_check.dart` to ensure presentation/auth entry points stay free of direct Firebase imports.
- Firebase is initialized in `main.dart`; App Check uses debug providers by default.
- Routes are defined in `AppConstants` and registered in `MaterialApp.routes`.

## Project Setup

1. `flutter pub get`
2. Add platform firebase configs (already checked in for Android/iOS).
3. `flutter run`
