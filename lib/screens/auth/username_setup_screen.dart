import 'package:flutter/material.dart';
import '../../providers/app_state_provider.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Local validations state
  bool _isLengthValid = false;
  bool _isCharactersValid = false;
  bool _isStartEndValid = false;
  bool _isConsecutiveValid = false;
  bool _isNotReserved = true;

  final RegExp _usernameRegex = RegExp(r'^[a-z0-9](?:[a-z0-9]|[._](?=[a-z0-9])){1,18}[a-z0-9]$');

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateUsername);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_validateUsername);
    _usernameController.dispose();
    super.dispose();
  }

  void _validateUsername() {
    final val = _usernameController.text;

    setState(() {
      // 1. Length validation (3-20 chars)
      _isLengthValid = val.length >= 3 && val.length <= 20;

      // 2. Characters validation (lowercase alphanumeric, dot, underscore)
      _isCharactersValid = RegExp(r'^[a-z0-9._]+$').hasMatch(val) || val.isEmpty;

      // 3. Starts and ends alphanumeric
      _isStartEndValid = val.isEmpty || (
        RegExp(r'^[a-z0-9]').hasMatch(val) && 
        RegExp(r'[a-z0-9]$').hasMatch(val)
      );

      // 4. No consecutive special characters (.. or __ or ._ or _.)
      _isConsecutiveValid = !val.contains('..') && 
                            !val.contains('__') && 
                            !val.contains('._') && 
                            !val.contains('_.');

      // 5. Reserved words check
      final normalized = val.toLowerCase();
      final isReservedExact = ['admin', 'support', 'official', 'moderator', 'emanetly'].contains(normalized);
      final containsEmanetly = normalized.contains('emanetly');
      final startsWithReserved = normalized.startsWith('admin') ||
          normalized.startsWith('support') ||
          normalized.startsWith('official') ||
          normalized.startsWith('moderator');

      _isNotReserved = !isReservedExact && !containsEmanetly && !startsWithReserved;
    });
  }

  bool get _isAllValid =>
      _isLengthValid &&
      _isCharactersValid &&
      _isStartEndValid &&
      _isConsecutiveValid &&
      _isNotReserved;

  Future<void> _submitUsername() async {
    if (!_formKey.currentState!.validate() || !_isAllValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = AppStateProvider.of(context);
    final username = _usernameController.text.trim().toLowerCase();

    try {
      await appState.setUsername(username);
    } catch (e) {
      setState(() {
        final errStr = e.toString();
        if (errStr.contains('already-exists')) {
          _errorMessage = 'Bu kullanıcı adı başka bir kullanıcı tarafından alınmış.';
        } else if (errStr.contains('invalid-argument')) {
          _errorMessage = 'Geçersiz kullanıcı adı biçimi veya yasaklı kelime.';
        } else if (errStr.contains('failed-precondition')) {
          _errorMessage = 'E-posta adresiniz doğrulanmamış veya kullanıcı adı zaten ayarlanmış.';
        } else {
          _errorMessage = 'Kullanıcı adı kaydedilirken bir hata oluştu: $e';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? Colors.green[800] : Colors.grey[600],
                fontSize: 14,
                fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final isLegacyUser = appState.currentUser?.usernameSource == 'email_derived';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon and Title
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alternate_email,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isLegacyUser ? 'Kullanıcı Adınızı Güncelleyin' : 'Kullanıcı Adı Belirleyin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLegacyUser
                          ? 'Emanetly v0.9.3 gizlilik politikası gereği, e-posta adresinizden türetilen kullanıcı adınızı benzersiz ve kendinize özgü yeni bir kullanıcı adı ile güncellemeniz gerekmektedir.'
                          : 'Kampüste diğer kullanıcılarla güvenle paylaşım yapabilmeniz için kendinize özgü ve e-posta adresinizi ifşa etmeyen benzersiz bir kullanıcı adı seçin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Text Field
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixText: '@ ',
                        prefixStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'kullanici.adi',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen bir kullanıcı adı girin.';
                        }
                        if (!_usernameRegex.hasMatch(value.trim())) {
                          return 'Lütfen tüm biçim koşullarını karşılayın.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Rules Validation List
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı adı kuralları:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildValidationRow(
                            '3-20 karakter uzunluğunda olmalı',
                            _isLengthValid,
                          ),
                          _buildValidationRow(
                            'Sadece küçük harf, rakam, nokta (.) veya alt çizgi (_)',
                            _isCharactersValid,
                          ),
                          _buildValidationRow(
                            'Harf veya rakam ile başlamalı ve bitmeli',
                            _isStartEndValid,
                          ),
                          _buildValidationRow(
                            'Ardışık özel karakter içermemeli (örn. .. veya __)',
                            _isConsecutiveValid,
                          ),
                          _buildValidationRow(
                            'Sistem tarafından ayrılmış özel kelimeler içermemeli',
                            _isNotReserved,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700], fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 24),

                    // Action Buttons
                    ElevatedButton(
                      onPressed: (_isLoading || !_isAllValid) ? null : _submitUsername,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Kaydet ve Devam Et',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Logout Button (so user isn't trapped on setup screen)
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              await AppStateProvider.of(context).signOut();
                            },
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
