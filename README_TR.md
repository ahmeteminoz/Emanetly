# Emanetly

[Click here for English README](README.md)

Üniversite kampüslerinde öğrencilerin ve çalışanların günlük ihtiyaç duydukları eşyaları (şarj aletleri, hesap makineleri, kitaplar, aletler vb.) kampüs ekosistemi içinde güvenli ve verimli bir şekilde ödünç alıp verebilmelerini sağlayan, Flutter ile geliştirilmiş modern, topluluk odaklı bir mobil pazar yeri ve paylaşım uygulamasıdır.

---

## 📌 Proje Genel Durumu (v0.8.0)

Emanetly, canlı Firebase servisleri (Auth, Firestore, Storage, Cloud Functions Gen 2, FCM) ile güçlendirilmiş, gerçek cihazlarda doğrulanmış olgun bir mobil uygulamadır.

### ✅ %100 Canlı ve Entegre Sistemler (Production-Ready)
*   **Firebase Authentication**: Kampüs e-postası (`.edu.tr`) doğrulamalı üyelik, şifre sıfırlama, oturum yönetimi (`FirebaseAuthService`).
*   **Cloud Firestore Database**: İlanlar, kullanıcı profilleri, favoriler, borç alma talepleri ve canlı sohbet mesajları veritabanında kalıcı olarak saklanır ve anlık dinlenir (`FirestoreItemService`, `FirestoreBorrowRequestService`, `FirestoreChatMessageService`).
*   **Firebase Storage**: İlan fotoğrafları ve profil fotoğraflarının bulutta saklanması, 1-5 çoklu görsel yükleme, kırpma ve tam ekran zoom desteği (`v0.6.1 - v0.6.3`).
*   **Cloud Functions Gen 2 (`europe-west1`)**: Mesaj gönderimlerinde ve talep durum değişikliklerinde Eventarc tabanlı anlık FCM Push Bildirimi gönderimi (`onMessageCreated`, `onRequestStatusChanged`).
*   **v0.8.0 Bildirim Merkezi (Notification Center)**: 
    * Sağ üst AppBar canlı okunmamış rozet akışı (`Badge`).
    * Uygulama içi bildirim günlükleri (`users/{userId}/notifications`).
    * **Dual-Layer Idempotency** ve `create-if-absent` koruması (retry durumunda `readAt` sıfırlanmama güvencesi).
    * Sola kaydırarak kaldırma (`dismissedAt` soft delete), Tümünü Okundu İşaretle ve Tümünü Kaldır (onay diyalogları ve 450'şerli batch chunking).
    * Material 3 Üç Nokta Menü (`⋮`), `LinearProgressIndicator` ve mükerrer tıklama koruması.
*   **Güvenlik Kuralları (Firestore Security Rules)**: İstemciden oluşturma/silme kapalı; yalnızca `readAt` ve `dismissedAt` alanlarının `null -> request.time` güncellenmesine izin verilir.

---

### 🚧 Prototipten / Mock Yapıdan Çıkarılması Gerekenler (Gelecek Yol Haritası)

İleride projeye geri dönüldüğünde prototipten çıkarılıp gerçek servise bağlanması gereken parçalar şunlardır:

*   [ ] **1. QR Kod Teslimat Doğrulaması (`MockQrService`)**:
    * Kamera ve tarayıcı arayüzü (`mobile_scanner` + `QrScannerScreen`) %100 tamamlanmıştır.
    * Ancak servis katmanı `main.dart` içinde `MockQrService` kullanmakta, URI parametrelerini bellek içinde (RAM) ayrıştırmaktadır.
    * *Yapılacak:* Firestore `borrowRequests` dokümanına 5 dakika geçerli `handoverToken` yazacak `FirestoreQrService` sınıfı yazılacak.
*   [ ] **2. Harita ve Rota Ekranı (`MockRouteScreen`)**:
    * Buluşma/teslimat yerini gösteren ekran `CustomPainter` ile çizilmiş kampüs maket haritası kullanmaktadır.
    * *Yapılacak:* Gerçek `google_maps_flutter` paketi entegre edilerek canlı kampüs koordinatları gösterilecek.
*   [ ] **3. İşlem Sonrası Puan Verme / Yorum Yapma Ekranı (Review Creation UI)**:
    * `UserProfile` modelinde ve profilde `reviews` (yorumlar ve yıldızlar) görünme altyapısı mevcuttur.
    * *Yapılacak:* İşlem tamamlandıktan sonra kullanıcıya yıldız verdirip yorum yazdıran Modal Sheet UI'ı eklenecek.
*   [ ] **4. Kullanıcı Moderasyonu (Şikayet Et & Engelle)**:
    * İlan detayında ve sohbet ekranında *"Kullanıcıyı Engelle"* ve *"İlanı Şikayet Et"* buton/diyalogları (Play Store yayını için zorunlu).
*   [ ] **5. Firebase Analytics & Crashlytics**:
    * Canlıdaki çökmeleri ve kullanıcı etkileşimlerini izleme altyapısı.

---

## 🛠️ Teknoloji Altyapısı

*   **Çerçeve (Framework)**: [Flutter](https://flutter.dev) (Dart)
*   **Durum Yönetimi (State)**: Reaktif ve hafif yeniden derleme için `AppState` ChangeNotifier Provider mimarisi.
*   **Backend**: Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging (FCM), Cloud Functions Gen 2 (Node.js 20).
*   **Arayüz (UI)**: Material 3 tema yapılandırmaları, özel çizimler (`CustomPainter`) ve akıcı mikro-animasyonlar.

---

## 🚀 Kurulum ve Çalıştırma

### Adımlar
1.  **Depoyu Klonlayın**:
    ```bash
    git clone https://github.com/ahmeteminoz/Emanetly.git
    cd Emanetly
    ```
2.  **Bağımlılıkları Yükleyin**:
    ```bash
    flutter pub get
    ```
3.  **Projeyi Çalıştırın**:
    ```bash
    flutter run
    ```

---

## 📜 Lisans

Bu proje MIT Lisansı ile lisanslanmıştır - detaylar için LICENSE dosyasına bakabilirsiniz.
