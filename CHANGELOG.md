# CHANGELOG - Emanetly

All notable changes to the Emanetly application will be documented in this file.

---

## [v0.8.0] - 2026-07-30

### 🚀 Added
- **Notification Center (`NotificationCenterScreen`)**:
  - Live unread notification badge (`Badge`) on top-right AppBar bell icon.
  - In-app notification event log persistence in `users/{userId}/notifications/{eventId}` subcollection.
  - **Mark All as Read**: Top-level 3-dot popup menu option to set `readAt: FieldValue.serverTimestamp()` for all unread notifications.
  - **Swipe-to-Dismiss**: Soft-delete via `dismissedAt: FieldValue.serverTimestamp()` with instant synchronous UI removal (`_dismissedIds`) preventing Flutter `Dismissible` tree errors.
  - **Clear All**: Soft-dismiss all notifications with safety confirmation dialog (`AlertDialog`).
  - **Material 3 3-Dot Popup Menu (`PopupMenuButton`)**: Clean UX layout with double-tap protection and linear progress indicator.
  - **Firestore 500-Item Batch Chunking**: `_commitBatchInChunks` helper committing updates in chunks of 450 to prevent Firestore batch limit errors.

### 🛡️ Security & Cloud Functions
- **Dual-Layer Idempotency**: Preserved `notificationEvents/{eventId}` transaction system to prevent duplicate FCM push delivery and duplicate Firestore document creation.
- **Create-If-Absent Semantics**: Cloud Functions `createInAppNotification` uses `docRef.create()` to ensure retries do not overwrite `readAt` timestamps.
- **Strict Firestore Security Rules**: Disallowed client-side `create` and `delete`; strictly restricted `update` to `readAt` and `dismissedAt` transitions from `null -> request.time`.
- **Composite Indexes**: Deployed `firestore.indexes.json` composite indexes for notifications subcollection.

### 🐛 Fixed & Polished
- **Chat Stream Security Rule Fix**: Updated `chatMessages` Firestore rule to allow signed-in users to stream messages without permission errors.
- **Sender Name Fallback & Contrast**: Added fallback email name parser for empty `senderName` fields and improved sender name contrast in Light Mode.
- **Global Time Sync (UTC)**: Standardized message timestamps to UTC (`DateTime.now().toUtc()`) in database and formatted as local device time (`toLocal()`) in UI to ensure accurate chronological message sorting across timezones.

---

## [v0.7.1] - 2026-07-24
- **Cloud Functions Gen 2 Deployment**: Deployed `onMessageCreated` and `onRequestStatusChanged` to `europe-west1` region (Node.js 20).
- **FCM Push Notifications**: Real-time push notifications for chat messages and borrow request status changes.
- **Foreground Silencing**: Silenced push notifications when user is actively inside the matching chat screen (`activeChatRequestId`).

---

## [v0.6.3] - 2026-07-20
- **Secure QR Handover UI**: Camera scanner UI (`mobile_scanner` + `QrScannerScreen`) for physical handover verification.
- **Multi-Image Support**: Multi-image listing gallery (1-5 photos), cropping, and full-screen zoom (`FullScreenImageViewer`).

---

## [v0.6.0] - 2026-07-15
- **Firebase Auth Integration**: Student email domain restriction (`.edu.tr`), login, register, password reset, and auth session persistence.
- **Cloud Firestore & Storage Setup**: Persisted items, user profiles, borrow requests, favorites, and storage bucket uploads.

---

## [v0.1.0 - v0.5.0] - 2026-07-04 to 2026-07-10
- **MVP Marketplace Core**: Material 3 discovery feed, category filtering, search bar, item details, duration selector sheet, favorites tab, trust dashboard, user reviews, and badges.
