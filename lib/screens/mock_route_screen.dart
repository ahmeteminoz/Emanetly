import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/borrow_request.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'transaction_success_screen.dart';

class MockRouteScreen extends StatefulWidget {
  final EmanetItem item;
  const MockRouteScreen({super.key, required this.item});

  @override
  State<MockRouteScreen> createState() => _MockRouteScreenState();
}

class _MockRouteScreenState extends State<MockRouteScreen> {
  final _meetingLocationController = TextEditingController();
  final _meetingNoteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final rawMeeting = widget.item.meetingPoint ?? '';
    if (rawMeeting.contains('| Not: ')) {
      final parts = rawMeeting.split('| Not: ');
      _meetingLocationController.text = parts[0].trim();
      _meetingNoteController.text = parts[1].trim();
    } else {
      _meetingLocationController.text = rawMeeting;
    }
  }

  @override
  void dispose() {
    _meetingLocationController.dispose();
    _meetingNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Get fresh item data from memory
    final currentItem = appState.allItems.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    // Find the active request
    BorrowRequestModel? activeRequest;
    try {
      activeRequest = appState.borrowRequests.firstWhere(
        (r) => r.itemId == currentItem.id &&
            (r.status == BorrowRequestStatus.accepted ||
             r.status == BorrowRequestStatus.borrowed ||
             r.status == BorrowRequestStatus.completed),
      );
    } catch (_) {}

    final isLender = currentItem.lenderId == appState.currentUser?.uid;
    final isBorrower = currentItem.borrowerId == appState.currentUser?.uid;
    final requestId = activeRequest?.id ?? '';

    // If transaction is fully completed, navigate to Success Screen
    if (activeRequest?.status == BorrowRequestStatus.completed || currentItem.status == EmanetStatus.archived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Trigger review dialog for borrower or lender before pushing success screen
        final counterpartyName = isLender ? (currentItem.borrowerName ?? 'Ödünç Alan') : currentItem.lenderName;
        final counterpartyId = isLender ? (currentItem.borrowerId ?? '') : currentItem.lenderId;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              item: currentItem,
              targetUserId: counterpartyId,
              targetName: counterpartyName,
              requestId: requestId,
            ),
          ),
        );

        // Auto trigger review popup
        if (counterpartyId.isNotEmpty) {
          _showFeedbackDialog(context, counterpartyId, counterpartyName, appState, requestId);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buluşma ve Teslimat'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primaryContainer.withOpacity(0.12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Buluşma yerini, notları ve teslimat sürecini buradan yönetebilirsiniz.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emanet Eşya: ${currentItem.title}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rolünüz: ${isLender ? "Eşya Sahibi (Veren)" : "Ödünç Alan"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meeting Details Card
                  _buildMeetingPointCard(context, currentItem, isLender, appState, activeRequest),
                  const SizedBox(height: 24),

                  // State Tracker Flow
                  Text(
                    'Onay ve İlerleme Süreci',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStateConfirmationTimeline(context, activeRequest),
                  const SizedBox(height: 24),

                  // Action Buttons Card
                  if (activeRequest != null)
                    _buildDoubleConfirmActionCard(context, activeRequest, currentItem, isLender, isBorrower, appState),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingPointCard(
    BuildContext context,
    EmanetItem item,
    bool isLender,
    AppState appState,
    BorrowRequestModel? activeRequest,
  ) {
    final theme = Theme.of(context);
    final counterpartyName = isLender ? (item.borrowerName ?? 'Ödünç Alan') : item.lenderName;

    final locationText = activeRequest?.meetingLocation ?? 
        (_meetingLocationController.text.isNotEmpty ? _meetingLocationController.text : 'Henüz belirlenmedi');
    final noteText = activeRequest?.meetingNote ?? _meetingNoteController.text;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    counterpartyName.isNotEmpty ? counterpartyName[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterpartyName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLender ? 'Ödünç Alan Öğrenci' : 'Eşya Sahibi',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  'Talep Süresi: ${activeRequest?.requestedDurationText ?? "1 Gün"}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Buluşma Yeri',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: locationText == 'Henüz belirlenmedi' ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                          fontStyle: locationText == 'Henüz belirlenmedi' ? FontStyle.italic : FontStyle.normal,
                          fontWeight: locationText == 'Henüz belirlenmedi' ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (noteText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 Buluşma Notu',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          noteText,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Update meeting location fields
            if (isLender && item.status == EmanetStatus.pendingApproval) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Buluşma Detaylarını Güncelle',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _meetingLocationController,
                decoration: const InputDecoration(
                  labelText: 'Buluşma Noktası',
                  hintText: 'örn. Kütüphane Girişi',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _meetingNoteController,
                decoration: const InputDecoration(
                  labelText: 'Ekstra Not (Opsiyonel)',
                  hintText: 'örn. Kırmızı montluyum',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final loc = _meetingLocationController.text.trim();
                    final note = _meetingNoteController.text.trim();
                    if (loc.isNotEmpty) {
                      await appState.updateMeetingDetails(item.id, loc, note);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Buluşma detayları başarıyla kaydedildi!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Buluşma Notunu Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateConfirmationTimeline(BuildContext context, BorrowRequestModel? request) {
    final theme = Theme.of(context);
    if (request == null) return const SizedBox();

    final hasLenderHandover = request.handoverLenderConfirmedAt != null;
    final hasBorrowerReceipt = request.handoverBorrowerConfirmedAt != null;
    final hasBorrowerReturn = request.returnBorrowerConfirmedAt != null;
    final hasLenderReturnReceipt = request.returnLenderConfirmedAt != null;

    final steps = [
      {
        'title': '1. Sahip Teslim Onayı',
        'subtitle': hasLenderHandover ? 'Teslim edildi' : 'Sahibin teslim onayı bekleniyor',
        'isConfirmed': hasLenderHandover,
      },
      {
        'title': '2. Alan Teslim Onayı',
        'subtitle': hasBorrowerReceipt ? 'Teslim alındı' : 'Alan kişinin teslim onayı bekleniyor',
        'isConfirmed': hasBorrowerReceipt,
      },
      if (request.status == BorrowRequestStatus.borrowed || hasBorrowerReturn || hasLenderReturnReceipt) ...[
        {
          'title': '3. Alan İade Onayı',
          'subtitle': hasBorrowerReturn ? 'İade edildi' : 'Alan kişinin iade etmesi bekleniyor',
          'isConfirmed': hasBorrowerReturn,
        },
        {
          'title': '4. Sahip İade Teslim Onayı',
          'subtitle': hasLenderReturnReceipt ? 'İade teslim alındı' : 'Sahibin iadeyi teslim alması bekleniyor',
          'isConfirmed': hasLenderReturnReceipt,
        },
      ]
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isConfirmed = step['isConfirmed'] as bool;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isConfirmed ? Icons.check_circle : Icons.radio_button_off,
                    color: isConfirmed ? Colors.green : theme.colorScheme.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isConfirmed ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          step['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isConfirmed ? Colors.green.shade700 : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDoubleConfirmActionCard(
    BuildContext context,
    BorrowRequestModel request,
    EmanetItem item,
    bool isLender,
    bool isBorrower,
    AppState appState,
  ) {
    final theme = Theme.of(context);

    final hasLenderHandover = request.handoverLenderConfirmedAt != null;
    final hasBorrowerReceipt = request.handoverBorrowerConfirmedAt != null;
    final hasBorrowerReturn = request.returnBorrowerConfirmedAt != null;
    final hasLenderReturnReceipt = request.returnLenderConfirmedAt != null;

    String? statusInfoText;
    String? buttonLabel;
    String? actionType;
    String? dialogMessage;

    // 1. Handover Delivery Phase (accepted status)
    if (request.status == BorrowRequestStatus.accepted) {
      if (isLender) {
        if (!hasLenderHandover) {
          buttonLabel = 'Eşyayı Teslim Ettim';
          actionType = 'lender_handover';
          dialogMessage = 'Eşyayı ödünç alan öğrenciye fiziksel olarak teslim ettiğinizi onaylıyor musunuz?';
        } else {
          statusInfoText = 'Teslim ettiğinizi onayladınız. Karşı tarafın "Teslim Aldım" onayı bekleniyor...';
        }
      } else if (isBorrower) {
        if (!hasBorrowerReceipt) {
          buttonLabel = 'Eşyayı Teslim Aldım';
          actionType = 'borrower_receipt';
          dialogMessage = 'Eşyayı sahibinden fiziksel olarak teslim aldığınızı onaylıyor musunuz?';
          if (hasLenderHandover) {
            statusInfoText = 'Sahip eşyayı teslim ettiğini onayladı. Siz de teslim aldıysanız onaylayın.';
          }
        } else {
          statusInfoText = 'Teslim aldığınızı onayladınız. Karşı tarafın "Teslim Ettim" onayı bekleniyor...';
        }
      }
    }

    // 2. Return Handover Phase (borrowed status)
    if (request.status == BorrowRequestStatus.borrowed) {
      if (isBorrower) {
        if (!hasBorrowerReturn) {
          buttonLabel = 'Eşyayı İade Ettim';
          actionType = 'borrower_return';
          dialogMessage = 'Eşyayı sahibine fiziksel olarak iade ettiğinizi onaylıyor musunuz?';
        } else {
          statusInfoText = 'İade ettiğinizi onayladınız. Sahibinin "İadeyi Teslim Aldım" onayı bekleniyor...';
        }
      } else if (isLender) {
        if (!hasLenderReturnReceipt) {
          buttonLabel = 'İadeyi Teslim Aldım';
          actionType = 'lender_return_receipt';
          dialogMessage = 'İade edilen eşyayı fiziksel olarak teslim aldığınızı onaylıyor musunuz?';
          if (hasBorrowerReturn) {
            statusInfoText = 'Alan kişi iade ettiğini onayladı. Siz de teslim aldıysanız onaylayın.';
          }
        } else {
          statusInfoText = 'İadeyi teslim aldığınızı onayladınız. Karşı tarafın "İade Ettim" onayı bekleniyor...';
        }
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (statusInfoText != null) ...[
              Text(
                statusInfoText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (buttonLabel != null && actionType != null && dialogMessage != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _confirmAction(context, request.id, actionType!, dialogMessage!, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ] else if (statusInfoText == null) ...[
              const Center(
                child: Text(
                  'Bu aşamada gerçekleştireceğiniz bir onay bulunmamaktadır.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String requestId,
    String action,
    String dialogMessage,
    AppState appState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fiziksel Eylem Onayı'),
          content: Text(dialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                setState(() => _isProcessing = true);
                
                final success = await appState.confirmHandoverAction(requestId, action);
                
                if (mounted) {
                  setState(() => _isProcessing = false);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onayınız başarıyla kaydedildi!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onay gönderilirken hata oluştu.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    String targetUserId,
    String targetName,
    AppState appState,
    String requestId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double currentRating = 5.0;
        final commentController = TextEditingController();
        final List<String> availableTags = ['Zamanında Teslim', 'Hızlı İletişim', 'Temiz Kullanım', 'Güvenilir'];
        final List<String> selectedTags = [];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$targetName Değerlendir')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Lütfen emanet süreç kalitesini değerlendirin:'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1.0;
                        return IconButton(
                          icon: Icon(
                            starVal <= currentRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              currentRating = starVal;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Deneyiminizi buraya yazın (isteğe bağlı)...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
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
                            setDialogState(() {
                              if (val) {
                                  selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: const Text('Atla'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final comment = commentController.text.trim();
                    String finalComment = comment.isNotEmpty ? comment : 'Sorunsuz ve güvenilir işlem.';
                    if (selectedTags.isNotEmpty) {
                      finalComment += ' (${selectedTags.join(', ')})';
                    }

                    appState.addUserReview(
                      targetUserId,
                      finalComment,
                      currentRating,
                      requestId,
                    );

                    Navigator.pop(context); // Close dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Değerlendirmeniz başarıyla eklendi, güven puanı güncellendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
