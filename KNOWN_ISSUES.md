# Known Issues & Technical Debt (v0.9.4)

Bu doküman v0.9.4 dondurulmuş sürümündeki bilinen teknik borçları ve küçük sorunları takip eder. Büyük refaktör açmadan, kapalı beta / sonraki küçük sürümlerde ele alınacaktır.

## Bilinen Sorunlar (Known Issues)

### 1. Push Bildirim Deep-Link Yönlendirmesi 🔔
- **Açıklama:** Uygulama tamamen kapalıyken (terminated) veya bazı arka plan durumlarında bildirime tıklandığında sohbet odasına yönlendirme %100 oranında güvenilir çalışmayabiliyor.
- **Durum:** Beklemede (Bir sonraki `feature/beta-polish` task'ı olarak ele alınacak).
- **Öncelik:** Orta

### 2. İstemci Tarafı Sistem Mesajları 💬
- **Açıklama:** Bazı sistem mesajları (`senderId: 'system'`) doğrudan mobil istemciden Firestore'a yazılıyor.
- **Durum:** İlerleyen sürümlerde (v1.0+) Cloud Functions (sunucu) tarafına taşınacak.
- **Öncelik:** Düşük (Security rules ile kısıtlı)

### 3. Firestore Chat Query/Index Gözlemi 🔍
- **Açıklama:** `chatMessages` için `requestId + createdAt` indeks yapısı yeni kuruldu ve canlıya alındı.
- **Durum:** Canlıda performans takibinde.
- **Öncelik:** Düşük
