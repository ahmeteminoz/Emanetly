import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../providers/app_state_provider.dart';

class ReportDialog extends StatefulWidget {
  final String targetType; // 'listing' | 'user' | 'message'
  final String targetId;
  final String targetTitle;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    required String targetTitle,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        targetTitle: targetTitle,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _detailsController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final Map<String, Map<String, String>> _reasonsMap = {
    'listing': {
      'spam': 'Spam veya Sahte İlan',
      'inappropriate_content': 'Uygunsuz İçerik / Görsel',
      'misleading_location': 'Yanıltıcı Konum Bilgisi',
      'other': 'Diğer',
    },
    'user': {
      'harassment': 'Taciz veya Rahatsız Etme',
      'spam': 'Spam / Sahte Hesap',
      'fake_account': 'Taklit / Sahte Profil',
      'other': 'Diğer',
    },
    'message': {
      'abusive_language': 'Hakaret veya Küfür',
      'spam': 'Spam / İstenmeyen Mesaj',
      'harassment': 'Taciz / Tehdit',
      'other': 'Diğer',
    },
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir rapor nedeni seçin.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createReport');

      await callable.call({
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
      });

      appState.analytics.logReportSubmitted(
        targetType: widget.targetType,
        reason: _selectedReason!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Raporunuz alındı. Ekibimiz tarafından incelenecektir.'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir sorun oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mapErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return 'Bu içeriği yakın zamanda raporladınız. Lütfen kısa bir süre bekleyin.';
      case 'unauthenticated':
        return 'Raporlama yapmak için giriş yapmalısınız.';
      case 'not-found':
        return 'Raporlanmak istenen içerik bulunamadı.';
      case 'permission-denied':
        return 'Bu içeriği raporlama yetkiniz bulunmuyor.';
      case 'invalid-argument':
        return e.message ?? 'Lütfen girdiğiniz bilgileri kontrol edin.';
      case 'failed-precondition':
        return 'Kendi içeriğinizi raporlayamazsınız.';
      default:
        return 'Rapor iletilirken bir sorun oluştu. Lütfen tekrar deneyin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reasons = _reasonsMap[widget.targetType] ?? {'other': 'Diğer'};

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              const Text('Şikayet Et', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.targetTitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raporlama Nedeni:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...reasons.entries.map((entry) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                value: entry.key,
                groupValue: _selectedReason,
                onChanged: _isSubmitting ? null : (val) => setState(() => _selectedReason = val),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              enabled: !_isSubmitting,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
                hintText: 'Detaylı bilgi verin...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: const Text('Raporu Gönder'),
        ),
      ],
    );
  }
}
