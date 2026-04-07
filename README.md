# 📚 CourseStream

A Flutter mobile application for managing and delivering online courses, with role-based access for admins, teachers, and students. Supports YouTube video playback, a balance/payment-code system, and secure screen protection.

---

## Features

### Roles
| Role | Capabilities |
|---|---|
| **Admin** | Manage students & teachers, add courses, generate payment codes |
| **Teacher** | View assigned courses, add new courses (auto-assigned), change password |
| **Student** | Browse & purchase courses, watch videos, redeem payment codes, change password |

### Highlights
- Role-based login routing — each role lands on its own home screen
- YouTube video playback via `youtube_player_flutter` with HD and autoplay flags
- Payment code system — admin generates codes, students redeem them to top up balance
- Screen capture protection via `flutter_windowmanager` (`FLAG_SECURE`)
- Fully offline-capable — all data persisted locally with `shared_preferences`
- Portrait-lock enforced at app and post-video level

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — init storage, orientation lock, run app
├── app.dart                   # MaterialApp, theme, root widget
│
├── models/
│   ├── user.dart              # User model + UserRole enum
│   ├── course.dart            # Course model
│   ├── payment_code.dart      # PaymentCode model
│   └── models.dart            # Barrel export
│
├── storage/
│   └── app_storage.dart       # SharedPreferences read/write + seed data
│
├── providers/
│   └── app_provider.dart      # ChangeNotifier — all business logic & state
│
├── pages/
│   ├── login_page.dart        # Login screen with role-based routing
│   ├── student_home.dart      # Student: my courses / available / profile tabs
│   ├── teacher_home.dart      # Teacher: my courses / add course / profile tabs
│   ├── admin_home.dart        # Admin: students / teachers / courses / add / codes
│   ├── video_player_page.dart # YouTube player page
│   └── pages.dart             # Barrel export
│
└── widgets/
    ├── course_card.dart        # Reusable course list tile
    ├── profile_tabs.dart       # StudentProfileTab + TeacherProfileTab
    ├── role_badge.dart         # Colored role chip (Admin / Teacher / Student)
    └── widgets.dart            # Barrel export
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android device or emulator (the `flutter_windowmanager` package is Android-only)

### Installation

```bash
git clone https://github.com/Youssif312/CourseStream.git
cd CourseStream
flutter pub get
flutter run
```

### Default Admin Credentials

```
Username: admin
Password: admin123
```

---

## Dependencies

| Package | Purpose |
|---|---|
| [`provider`](https://pub.dev/packages/provider) | State management |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Local persistence |
| [`youtube_player_flutter`](https://pub.dev/packages/youtube_player_flutter) | Embedded YouTube playback |
| [`flutter_windowmanager`](https://pub.dev/packages/flutter_windowmanager) | Screen capture prevention |
| [`uuid`](https://pub.dev/packages/uuid) | ID and payment code generation |

---

## Data Flow

```
AppStorage (SharedPreferences)
       │  load / save
       ▼
AppProvider (ChangeNotifier)
       │  exposes state + actions
       ▼
Pages & Widgets (Consumer / Provider.of)
```

All data is stored as JSON in `SharedPreferences` under versioned keys (`app_users_v2`, `app_courses_v1`, `app_codes_v1`). There is no remote backend — everything runs on-device.

---

## Security Notes

- Passwords are stored as Base64-encoded strings. (NOT FOR PRODUCTION).
- `FLAG_SECURE` prevents screenshots and screen recording on Android.
- The admin account cannot be deleted.

