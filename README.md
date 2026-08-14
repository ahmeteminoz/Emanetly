# Emanetly

[Türkçe README için tıklayın](README_TR.md)

A modern, community-driven campus marketplace and peer-to-peer item sharing mobile application built with Flutter. Emanetly enables university students and staff to lend and borrow everyday items (chargers, calculators, books, tools, etc.) safely and efficiently within their campus ecosystem.

---

## 📌 Project Current Status (v0.9.4 - Store Readiness & Beta Polish)

Emanetly is a mature mobile application powered by live Firebase services (Auth, Firestore, Storage, Cloud Functions Gen 2, FCM) and verified on real connected devices. It has recently undergone a major architectural refactor to ensure scalability and maintainability for its upcoming beta release.

### ✅ 100% Live & Integrated Systems (Production-Ready)
*   **Firebase Authentication**: Restricted to verified campus `.edu.tr` emails, password reset, and auth session management.
*   **Cloud Firestore Database**: Persistent real-time database syncing items, user profiles, favorites, borrow requests, and live chat streams. Optimized with composite indexes and robust security rules.
*   **Firebase Storage**: Cloud hosting for item images and profile pictures, multi-image upload (1-5 images), cropping, and full-screen zoom.
*   **Cloud Functions Gen 2 (`europe-west1`)**: Eventarc-triggered background push notifications for chat creation and request status changes.
*   **Notification Center**: 
    * Top-right AppBar live unread badge stream.
    * In-app notification event logs with dual-layer idempotency (preserves timestamps on function retries).
    * Swipe-to-dismiss, Mark All as Read, and Clear All (with safety confirmation dialogs).
*   **State Management Architecture**: Clean, scalable Provider architecture divided into specialized notifiers (`AuthNotifier`, `ItemNotifier`, `RequestNotifier`) orchestrated by a lightweight `AppState` facade.
*   **Handover & Return Workflow**: Secure double-confirmation process for transferring and returning items between users.
*   **Trust & Moderation (Store-Ready)**:
    * Post-transaction rating and review system (1-5 stars and comments).
    * User blocking and item reporting mechanisms to ensure a safe community environment.

---

### 🚧 Future Development Checklist (Closed Beta & v1.0 Roadmap)

The project is currently in the `feature/beta-polish` phase preparing for closed beta testing.

*   [ ] **1. Closed Beta Launch & Analytics**:
    * Distribute to initial test users (5-10 users).
    * Verify Firebase Analytics and Crashlytics data collection.
    * Analyze user behavior (e.g., Request vs. Ask Question usage).
*   [ ] **2. Push Notification Deep-Link Polish**:
    * Improve deep-link navigation reliability when clicking push notifications from terminated or background app states.
*   [ ] **3. Backend Migration for System Messages**:
    * Move the generation of system chat messages (`senderId: 'system'`) from the client side to secure Cloud Functions.
*   [ ] **4. "Wanted/Needed Items" Module (v1.0 Candidate)**:
    * Allow users to post requests for items they need but cannot find on the platform.

---

## 🛠️ Technical Architecture

*   **Framework**: [Flutter](https://flutter.dev) (Dart)
*   **State Management**: Reactive `ChangeNotifier` Provider architecture (`AuthNotifier`, `ItemNotifier`, `RequestNotifier`).
*   **Backend**: Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging (FCM), Cloud Functions Gen 2 (Node.js 20).
*   **UI System**: Material 3 theme configurations, custom path drawing (`CustomPainter`), and fluid micro-animations.

---

## 🚀 Installation & Setup

### Steps
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/ahmeteminoz/Emanetly.git
    cd Emanetly
    ```
2.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.
