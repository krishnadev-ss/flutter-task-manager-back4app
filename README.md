# Task Manager — Flutter + Back4App

A production-ready Flutter task management app backed by [Back4App](https://www.back4app.com/) (Parse Server BaaS).

## Features

| Category | Detail |
|---|---|
| **Auth** | Email-only sign-up/login, persistent session, Logout |
| **Tasks** | Full CRUD — create, read, update, delete |
| **Status** | Toggle complete / incomplete per task |
| **Due dates** | Optional due date with overdue highlighting |
| **Search** | Real-time title + description search |
| **Filter** | All / Active / Completed tabs with counts |
| **Pull-to-refresh** | Manual refresh from the dashboard |
| **UI** | Material 3, dark mode support, animations |
| **Error handling** | Snackbars, empty states, error screens |

---

## Tech Stack

- **Flutter** (latest stable)
- **Dart** (null-safe, `>=3.3.0`)
- **Back4App** via `parse_server_sdk_flutter`
- **State management**: Provider + ChangeNotifier
- **Date formatting**: `intl`

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Parse init, theme
├── config/
│   ├── app_config.dart        # Back4App credentials (edit this)
│   └── routes.dart            # Named route registry
├── models/
│   ├── task_model.dart        # Task domain model + Parse serialization
│   └── user_model.dart        # User domain model
├── services/
│   ├── auth_service.dart      # Parse sign-up / login / logout / session
│   └── task_service.dart      # Parse CRUD for Task class
├── providers/
│   ├── auth_provider.dart     # Auth state (ChangeNotifier)
│   └── task_provider.dart     # Task list state + filter + search
├── screens/
│   ├── splash_screen.dart     # Session check + animated intro
│   ├── login_screen.dart      # Login form
│   ├── register_screen.dart   # Registration form
│   ├── dashboard_screen.dart  # Task list with tabs + search
│   ├── add_task_screen.dart   # Create task form
│   └── edit_task_screen.dart  # Edit task form
├── widgets/
│   ├── custom_text_field.dart # Reusable styled text field
│   ├── loading_overlay.dart   # Blocking loading scrim
│   ├── empty_state_widget.dart# Centred icon + copy + CTA
│   └── task_card.dart         # Dismissible task list card
└── utils/
    ├── validators.dart        # Form field validators
    └── app_date_utils.dart    # Date formatting helpers
```

---

## Setup

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — latest stable channel
- Dart SDK (bundled with Flutter)
- An Android emulator / iOS simulator, or a physical device
- A [Back4App](https://www.back4app.com/) account (free tier is sufficient)

```bash
# Verify your Flutter installation
flutter doctor
```

---

### 2. Clone & install dependencies

```bash
git clone <your-repo-url>
cd flutter-task-manager-back4app
flutter pub get
```

---

### 3. Set up Back4App

#### 3a. Create an app

1. Log in to [Back4App](https://www.back4app.com/) and click **Build new app**.
2. Choose **Parse** as your backend type and name your app.

#### 3b. Get your credentials

1. Open your app's dashboard.
2. Go to **App Settings → Security & Keys**.
3. Copy the **Application ID** and **Client Key**.

#### 3c. Create the Task class and schema

In your Back4App dashboard, go to **Database → Create a class**:

| Class name | Type |
|---|---|
| `Task` | Custom |

Then add these columns:

| Column | Type | Required |
|---|---|---|
| `title` | String | Yes |
| `description` | String | Yes |
| `isCompleted` | Boolean | Yes (default: `false`) |
| `dueDate` | Date | No |
| `user` | Pointer → `_User` | Yes |

> **Tip:** The SDK will auto-create columns on first save if you have **Client Class Creation** enabled (App Settings → Server Settings). You can also let the app create them on first run.

#### 3d. Set class-level permissions (CLP)

For the `Task` class, set **Class-Level Permissions** so that:

- **Get / Find / Create / Update / Delete** → requires authenticated user
- **Public Read / Write** → disabled

This ensures users can only access their own data (row-level ACLs are set by the app).

---

### 4. Add your credentials

Open `lib/config/app_config.dart` and replace the placeholders:

```dart
class AppConfig {
  static const String applicationId = 'YOUR_APP_ID';   // ← paste here
  static const String clientKey    = 'YOUR_CLIENT_KEY'; // ← paste here
  static const String serverUrl    = 'https://parseapi.back4app.com';
}
```

---

### 5. Run the app

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Or just run on the first available device
flutter run
```

---

### 6. Build for production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires Xcode + Apple Developer account)
flutter build ios --release
```

---

## Environment variables (optional hardening)

Instead of editing `app_config.dart` directly, you can inject credentials at build time via `--dart-define`:

```bash
flutter run \
  --dart-define=APP_ID=your_app_id \
  --dart-define=CLIENT_KEY=your_client_key
```

Then update `app_config.dart` to read them:

```dart
static const String applicationId =
    String.fromEnvironment('APP_ID', defaultValue: 'YOUR_APP_ID');
static const String clientKey =
    String.fromEnvironment('CLIENT_KEY', defaultValue: 'YOUR_CLIENT_KEY');
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Invalid Application ID` | Check `applicationId` in `app_config.dart` |
| Tasks not loading after login | Verify CLP on the `Task` class allows authenticated reads |
| Session not persisting | Ensure `autoSendSessionId: true` in `Parse().initialize` |
| Date picker shows past dates | `firstDate` in `AddTaskScreen` is set to `DateTime.now()` — change if you need past dates |

---

## License

MIT — see [LICENSE](LICENSE).
