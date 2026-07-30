# Emanetly

[Türkçe README için tıklayın](README_TR.md)

A modern, community-driven campus marketplace and peer-to-peer item sharing mobile application built with Flutter. Emanetly enables university students and staff to lend and borrow everyday items (chargers, calculators, books, tools, etc.) safely and efficiently within their campus ecosystem.

---

## 📌 Project Current Status (v0.8.0)

Emanetly is a mature mobile application powered by live Firebase services (Auth, Firestore, Storage, Cloud Functions Gen 2, FCM) and verified on real connected devices.

### ✅ 100% Live & Integrated Systems (Production-Ready)
*   **Firebase Authentication**: Restricted to verified campus `.edu.tr` emails, password reset, and auth session management (`FirebaseAuthService`).
*   **Cloud Firestore Database**: Persistent real-time database syncing items, user profiles, favorites, borrow requests, and live chat streams (`FirestoreItemService`, `FirestoreBorrowRequestService`, `FirestoreChatMessageService`).
*   **Firebase Storage**: Cloud hosting for item images and profile pictures, multi-image upload (1-5 images), cropping, and full-screen zoom (`v0.6.1 - v0.6.3`).
*   **Cloud Functions Gen 2 (`europe-west1`)**: Eventarc-triggered background push notifications for chat creation and request status changes (`onMessageCreated`, `onRequestStatusChanged`).
*   **v0.8.0 Notification Center**: 
    * Top-right AppBar live unread badge stream (`Badge`).
    * In-app notification event logs (`users/{userId}/notifications`).
    * **Dual-Layer Idempotency** and `create-if-absent` semantics (preserves `readAt` timestamps on function retries).
    * Swipe-to-dismiss (`dismissedAt` soft delete), Mark All as Read, and Clear All (with safety confirmation dialogs & 450-item batch chunking).
    * Material 3 3-dot popup menu (`⋮`), `LinearProgressIndicator` loading bar, and double-tap protection.
*   **Security Rules (Firestore Rules)**: Client creation/deletion disabled; strictly allows `readAt` and `dismissedAt` updates from `null -> request.time`.

---

### 🚧 Future Development Checklist (Roadmap Backlog)

The following items represent the planned roadmap backlog for future releases:

*   [ ] **1. QR Code Handover Verification (`FirestoreQrService`)**:
    * Camera scanner UI (`mobile_scanner` + `QrScannerScreen`) is 100% complete and working.
    * Connect service layer from `MockQrService` to `FirestoreQrService` to write 5-minute valid `handoverToken` hashes to `borrowRequests` Firestore collection.
*   [ ] **2. Post-Transaction Review & Rating Modal (Review Creation UI)**:
    * `UserProfile` model and profile screen review cards exist.
    * Add a Modal Bottom Sheet UI allowing users to rate (1-5 stars) and write comments after completing a transaction.
*   [ ] **3. User Moderation (Report & Block)**:
    * Action dialogs for *"Block User"* and *"Report Listing"* (Required for Play Store / App Store release).
*   [ ] **4. Firebase Analytics & Crashlytics**:
    * Infrastructure for tracking real-time crashes and user conversion funnels.

---

## 🛠️ Technical Architecture

*   **Framework**: [Flutter](https://flutter.dev) (Dart)
*   **State Management**: Reactive and lightweight `AppState` ChangeNotifier Provider architecture.
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
