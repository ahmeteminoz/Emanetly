import 'package:flutter/material.dart';
import '../../providers/app_state_provider.dart';
import '../main_layout.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final user = appState.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    // Check if email verification is completed (ignored in mock auth, active in firebase auth)
    if (!appState.isEmailVerified) {
      return const EmailVerificationScreen();
    }

    return const MainLayout();
  }
}
