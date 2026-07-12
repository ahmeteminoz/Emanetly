import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/app_state_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    // Periodically reload user state to check if email has been verified
    _verificationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkVerificationStatusSilent();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _checkVerificationStatusSilent() async {
    final appState = AppStateProvider.of(context);
    await appState.reloadUser();
    // AuthGate will rebuild and route automatically when verified
  }

  void _checkVerificationStatusManual() async {
    setState(() {
      _isChecking = true;
    });

    final appState = AppStateProvider.of(context);
    await appState.reloadUser();

    setState(() {
      _isChecking = false;
    });

    if (mounted) {
      if (appState.isEmailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta doğrulandı! Hoş geldiniz.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta henüz doğrulanmadı. Lütfen gelen kutunuzu (ve gereksiz kutusunu) kontrol edin.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    final appState = AppStateProvider.of(context);
    try {
      await appState.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama bağlantısı tekrar gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _handleSignOut() async {
    final appState = AppStateProvider.of(context);
    await appState.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final emailAddress = appState.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon layout
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      Icons.mark_email_read_outlined,
                      color: theme.colorScheme.primary,
                      size: 56,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Doğrulama Bağlantısı Gönderildi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Lütfen '),
                    TextSpan(
                      text: emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: ' adresine gönderdiğimiz doğrulama bağlantısına tıklayın.\n\nE-posta onaylandığında uygulama otomatik olarak açılacaktır.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Manual Check Button
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkVerificationStatusManual,
                icon: _isChecking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Doğruladım, Tekrar Kontrol Et'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // Resend Button
              OutlinedButton.icon(
                onPressed: _isResending ? null : _resendVerificationEmail,
                icon: _isResending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Doğrulama E-postasını Yeniden Gönder'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Cancel / Sign out text link
              TextButton(
                onPressed: _handleSignOut,
                child: const Text('Farklı bir e-posta adresiyle giriş yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
