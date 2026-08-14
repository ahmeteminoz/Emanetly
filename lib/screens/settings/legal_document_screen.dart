import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  static void showTOS(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LegalDocumentScreen(
          title: 'Kullanım Şartları',
          content: _tosContent,
        ),
      ),
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LegalDocumentScreen(
          title: 'Gizlilik Politikası',
          content: _privacyContent,
        ),
      ),
    );
  }

  static void showKVKK(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LegalDocumentScreen(
          title: 'KVKK Aydınlatma Metni',
          content: _kvkkContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Son Güncelleme: Ağustos 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 32),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bu metinler bilgilendirme amaçlı hazırlanmıştır. Uygulamanın mağazalarda yayınlanmasından önce yasal mercilerce doğrulanması önerilmektedir.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _tosContent = '''
Emanetly ("Uygulama") platformuna hoş geldiniz. Bu Kullanım Şartları, uygulamaya erişiminiz ve uygulamanın kullanımıyla ilgili yasal haklarınızı ve sorumluluklarınızı belirler.

1. Kabul Edilme Şartları
Uygulamayı kullanarak, bu kullanım şartlarını tamamen kabul etmiş sayılırsınız. Şartları kabul etmiyorsanız, uygulamayı kullanmayı durdurmalısınız.

2. Hizmetin Amacı ve Kapsamı
Emanetly, üniversite kampüslerinde öğrenciler ve personel arasında geçici olarak eşya ödünç alınmasını/verilmesini kolaylaştıran bir yardımlaşma platformudur. Emanetly, taraflar arasındaki eşya transferlerinden, hasarlardan veya süreçlerdeki anlaşmazlıklardan doğrudan ya da dolaylı olarak hukuki veya mali açıdan sorumlu tutulamaz.

3. Kullanıcı Yükümlülükleri
- Üniversite e-posta adresiyle doğrulanmış geçerli bir hesaba sahip olmak.
- Paylaşılan ilanların doğruluğundan ve yasalara uygunluğundan ilan sahibi sorumludur.
- Ödünç alınan eşyanın zamanında, temiz ve hasarsız teslim edilmesi ödünç alanın sorumluluğundadır.

4. Hesap Silme Hakları
Kullanıcılar diledikleri an uygulama içi ayarlar bölümünden veya resmi internet portalımız üzerinden hesap silme talebi oluşturabilirler. Talep oluşturulduğunda kullanıcı verileri güvenli şekilde sunucu tarafında temizlenir ve anonimleştirilir.
''';

  static const String _privacyContent = '''
Emanetly olarak kişisel verilerinizin güvenliği ve gizliliği bizim için en üst düzeyde öneme sahiptir. Bu Gizlilik Politikası, hangi verilerin toplandığını ve nasıl işlendiğini açıklar.

1. Toplanan Veriler
- Kimlik ve İletişim Bilgileri: Ad soyad, üniversite e-posta adresi, profil fotoğrafı.
- Cihaz ve Konum Verileri: FCM token'ları (bildirimler için), yaklaşık konum bilgileri.
- Kullanım Verileri: İlanlar, mesajlaşma geçmişi, değerlendirme puanları.

2. Verilerin İşlenme Amacı
Kişisel verileriniz, kampüs içi güvenli ödünç verme süreçlerini yönetmek, bildirimlerinizi iletmek ve sistem içi moderasyon ile güven puanını hesaplamak amacıyla işlenir.

3. Veri Güvenliği ve Saklama Süresi
Verileriniz Firebase altyapısı üzerinde güvenle saklanır. Hesabınızı sildiğinizde, kimliğinizi doğrudan belirleyen kişisel bilgileriniz (ad, e-posta, avatar) tamamen temizlenir. Geçmiş işlem verileri ve sohbet geçmişi ise diğer kullanıcıların haklarını korumak amacıyla "Eski Kullanıcı" adıyla anonimleştirilerek arşivlenir.
''';

  static const String _kvkkContent = '''
6698 Sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında, veri sorumlusu sıfatıyla Emanetly, kampüs içi yardımlaşma süreçlerinde işlediği verilerle ilgili olarak sizleri bilgilendirmekle yükümlüdür.

1. Kişisel Verilerin Elde Edilme Yöntemi
Kişisel verileriniz, uygulama arayüzü üzerinden kayıt olma, profil düzenleme, ilan paylaşma ve sohbet süreçlerinde tamamen dijital yollarla toplanmaktadır.

2. İşlenen Veriler ve Hukuki Sebepler
Üniversite kimliğinizin doğrulanması ve işlemlerin yürütülmesi, kanun kapsamında "sözleşmenin kurulması ve ifası" hukuki sebebine dayanarak işlenmektedir.

3. İlgili Kişi Hakları
KVKK 11. Maddesi uyarınca dilediğiniz zaman;
- Kişisel verilerinizin işlenip işlenmediğini öğrenme,
- Kişisel verilerinizin silinmesini veya yok edilmesini isteme,
- Verilerinizin kanuna aykırı olarak işlenmesi sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme haklarına sahipsiniz.
''';
}
