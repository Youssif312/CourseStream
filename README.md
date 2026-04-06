# CourseStream: Learning Management System

CourseStream is a robust Flutter application designed as a Learning Management System (LMS). It features a multi-role architecture supporting **Admins**, **Teachers**, and **Students**, with integrated secure video playback and a local credit-based payment system.

---

## 🚀 Project Overview

The application serves as a platform where teachers can host educational content, students can purchase and view courses, and admins can manage the entire ecosystem. It emphasizes security and offline-first data persistence.

### Key Features

#### 👑 Admin Dashboard
* **User Management:** Create, monitor, and remove Student and Teacher accounts.
* **Course Oversight:** View all courses and their assigned instructors.
* **Monetization:** Generate unique, one-time-use payment codes to top up student balances.
* **Global View:** Monitor payment code usage, including who redeemed them and when.

#### 👨‍🏫 Teacher Portal
* **Content Creation:** Add new courses with descriptions, pricing, and video links.
* **Curriculum Management:** View and manage specific courses assigned by the admin.
* **Course Preview:** Access a dedicated preview mode for their own video content.

#### 🎓 Student Experience
* **Course Marketplace:** Browse available courses and purchase them using an in-app wallet.
* **My Learning:** A dedicated space for purchased courses with progress tracking.
* **Wallet System:** Redeem admin-generated codes to increase account balance.
* **Secure Video Player:** Integrated YouTube playback for course lessons.

---

## 🛠 Technical Stack

* **State Management:** `Provider` for reactive UI updates and centralized business logic.
* **Local Persistence:** `shared_preferences` for storing user data, course lists, and transaction history.
* **Security:** * `flutter_windowmanager`: Prevents screenshots and screen recordings of course content.
    * Simple Base64 password hashing for local data protection.
* **Video Playback:** `Youtubeer_flutter` for seamless streaming.
* **UI/UX:** Flutter Material 3 with a custom indigo/teal theme and responsive tabbed navigation.

---

## 📁 Project Structure

```text
lib/
├── main.dart           # Entry point, AppProvider, Models, and UI Screens
└── videoplayer.dart    # Dedicated secure YouTube player implementation
