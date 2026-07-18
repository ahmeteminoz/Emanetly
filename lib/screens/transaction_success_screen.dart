import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';

class TransactionSuccessScreen extends StatefulWidget {
  final EmanetItem item;
  final String targetUserId;
  final String targetName;
  final String requestId;

  const TransactionSuccessScreen({
    super.key,
    required this.item,
    required this.targetUserId,
    required this.targetName,
    required this.requestId,
  });

  @override
  State<TransactionSuccessScreen> createState() => _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen> {
  double _currentRating = 5.0;
  final _commentController = TextEditingController();
  final List<String> _availableTags = ['Zamanında Teslim', 'Hızlı İletişim', 'Temiz Kullanım', 'Güvenilir'];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview(AppState appState) {
    final comment = _commentController.text.trim();
    String finalComment = comment.isNotEmpty ? comment : 'Sorunsuz ve güvenilir işlem.';
    if (_selectedTags.isNotEmpty) {
      finalComment += ' (${_selectedTags.join(', ')})';
    }

    // Submit review to database
    appState.addUserReview(
      widget.targetUserId,
      finalComment,
      _currentRating,
      widget.requestId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Değerlendirmeniz iletildi, teşekkür ederiz!'),
        backgroundColor: Colors.green,
      ),
    );

    // Redirect to home/main screen clean
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 1. Success Animation/Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Success Text
              Text(
                'Emanet Tamamlandı! 🎉',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.item.title} adlı eşya başarıyla iade edildi ve süreç kapatıldı. Kampüste yardımlaşma kültürünü desteklediğiniz için teşekkürler!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 3. Review Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.targetName} kullanıcısını değerlendirin:',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1.0;
                          return IconButton(
                            icon: Icon(
                              starVal <= _currentRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentRating = starVal;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Comment Field
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Deneyimlerinizi buraya yazın (isteğe bağlı)...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags Selector
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(tag),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.primary,
                            checkmarkColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4. Action Buttons
              ElevatedButton(
                onPressed: () => _submitReview(appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('Değerlendir & Ana Sayfaya Dön', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Jump straight home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Değerlendirmeyi Atla ve Kapat',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
