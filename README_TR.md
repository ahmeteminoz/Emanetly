# Emanetly

[Click here for English README](README.md)

Üniversite kampüslerinde öğrencilerin ve çalışanların günlük ihtiyaç duydukları eşyaları (şarj aletleri, hesap makineleri, kitaplar, aletler vb.) kampüs ekosistemi içinde güvenli ve verimli bir şekilde ödünç alıp verebilmelerini sağlayan, Flutter ile geliştirilmiş modern, topluluk odaklı bir mobil pazar yeri ve paylaşım uygulamasıdır.

---

## 📌 Proje Genel Durumu (v0.9.4 - Mağaza Hazırlığı & Beta Cila Aşaması)

Emanetly, canlı Firebase servisleri (Auth, Firestore, Storage, Cloud Functions Gen 2, FCM) ile güçlendirilmiş, gerçek cihazlarda doğrulanmış olgun bir mobil uygulamadır. Yaklaşan kapalı beta sürümü için ölçeklenebilirliği ve sürdürülebilirliği sağlamak adına yakın zamanda büyük bir mimari refaktör (yeniden yapılandırma) sürecinden geçmiştir.

### ✅ %100 Canlı ve Entegre Sistemler (Production-Ready)
*   **Firebase Authentication**: Kampüs e-postası (`.edu.tr`) doğrulamalı üyelik, şifre sıfırlama ve oturum yönetimi.
*   **Cloud Firestore Database**: İlanlar, kullanıcı profilleri, favoriler, borç alma talepleri ve canlı sohbet mesajları veritabanında kalıcı olarak saklanır ve anlık dinlenir. Birleşik indeksler (composite indexes) ve sıkı güvenlik kuralları (security rules) ile optimize edilmiştir.
*   **Firebase Storage**: İlan fotoğrafları ve profil fotoğraflarının bulutta saklanması, 1-5 çoklu görsel yükleme, kırpma ve tam ekran zoom desteği.
*   **Cloud Functions Gen 2 (`europe-west1`)**: Mesaj gönderimlerinde ve talep durum değişikliklerinde Eventarc tabanlı anlık FCM Push Bildirimi gönderimi.
*   **Bildirim Merkezi (Notification Center)**: 
    * Sağ üst AppBar canlı okunmamış rozet akışı.
    * Uygulama içi bildirim günlükleri ve Dual-Layer Idempotency (retry durumunda zaman damgalarının korunması) koruması.
    * Sola kaydırarak kaldırma, Tümünü Okundu İşaretle ve Tümünü Kaldır (onay diyalogları ile).
*   **Durum Yönetimi Mimarisi (State Management)**: Hafif bir `AppState` cephesi (facade) tarafından yönetilen, özel alanlara ayrılmış (`AuthNotifier`, `ItemNotifier`, `RequestNotifier`) temiz ve ölçeklenebilir Provider mimarisi.
*   **Teslimat ve İade Akışı (Handover Workflow)**: Kullanıcılar arasında eşya aktarımı ve iadesi için güvenli, çift onaylı işlem süreci.
*   **Güven & Moderasyon (Mağaza Hazır)**:
    * İşlem sonrası yıldız (1-5) verme ve yorum yapma sistemi.
    * Güvenli bir topluluk ortamı sağlamak için kullanıcı engelleme ve uygunsuz ilan/davranış şikayet etme mekanizmaları.

---

### 🚧 İleride Tamamlanacak Geliştirme Çeklisti (Kapalı Beta & v1.0 Yol Haritası)

Proje şu anda kapalı beta testlerine hazırlık amacıyla `feature/beta-polish` aşamasındadır.

*   [ ] **1. Kapalı Beta Lansmanı & Analitik**:
    * İlk test kullanıcılarına (5-10 kişi) dağıtım.
    * Firebase Analytics ve Crashlytics veri toplama süreçlerinin doğrulanması.
    * Kullanıcı davranışlarının analizi (örn. Talep Et vs. Soru Sor kullanım oranları).
*   [ ] **2. Push Bildirim Deep-Link İyileştirmeleri**:
    * Uygulama arka planda veya tamamen kapalı (terminated) durumdayken push bildirimlerine tıklandığında gerçekleşen yönlendirmelerin güvenilirliğini artırmak.
*   [ ] **3. Sistem Mesajları İçin Backend Taşıması**:
    * Sistem sohbet mesajlarının (`senderId: 'system'`) oluşturulma işlemini istemci (client) tarafından güvenli Cloud Functions (sunucu) tarafına taşımak.
*   [ ] **4. "Aranıyor/İhtiyaç Var" Modülü (v1.0 Adayı)**:
    * Kullanıcıların platformda bulamadıkları ancak acil ihtiyaç duydukları eşyalar için "Aranıyor" ilanı açabilmelerini sağlamak.

---

## 🛠️ Teknoloji Altyapısı

*   **Çerçeve (Framework)**: [Flutter](https://flutter.dev) (Dart)
*   **Durum Yönetimi (State)**: Reaktif `ChangeNotifier` Provider mimarisi (`AuthNotifier`, `ItemNotifier`, `RequestNotifier`).
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
