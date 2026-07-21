import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/borrow_request.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'transaction_success_screen.dart';
import 'widgets/qr_scanner_screen.dart';

class MockRouteScreen extends StatefulWidget {
  final EmanetItem item;
  const MockRouteScreen({super.key, required this.item});

  @override
  State<MockRouteScreen> createState() => _MockRouteScreenState();
}

class _MockRouteScreenState extends State<MockRouteScreen> {
  final _meetingLocationController = TextEditingController();
  final _meetingNoteController = TextEditingController();

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

    // Get fresh item data
    final currentItem = appState.items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    final isLender = currentItem.lenderId == appState.currentUser?.uid;
    final isBorrower = currentItem.borrowerId == appState.currentUser?.uid;

    if (currentItem.status == EmanetStatus.available || currentItem.status == EmanetStatus.archived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeReq = appState.getRequestForActiveItem(widget.item.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              item: currentItem,
              targetUserId: isLender ? (currentItem.borrowerId ?? '') : currentItem.lenderId,
              targetName: isLender ? (currentItem.borrowerName ?? 'Ödünç Alan') : currentItem.lenderName,
              requestId: activeReq?.id ?? '',
            ),
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buluşma & Teslimat Detayları'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Part 2: Buluşma Noktası Bilgisi & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emanet İşlemi: ${currentItem.title}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ortaklar: ${currentItem.lenderName} (Lender) ➔ ${currentItem.borrowerName} (Borrower)',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  
                  // Meeting point card
                  _buildMeetingPointCard(context, currentItem, isLender, appState),
                  const SizedBox(height: 24),
                  
                  // Delivery status timeline
                  Text(
                    'Teslimat Durumu',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryTimeline(context, currentItem.deliveryStatus ?? DeliveryStatus.requestSent),
                  const SizedBox(height: 24),
                  
                  // Simulation helper control buttons
                  _buildSimulationControls(context, currentItem, isLender, isBorrower, appState),
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
  ) {
    final theme = Theme.of(context);
    final activeRequest = appState.getRequestForActiveItem(item.id);
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
            // Header: Counterparty Info
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
                        isLender ? 'Eşyayı Ödünç Alan Öğrenci' : 'Eşya Sahibi (Lender)',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_rounded, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Güvenilir', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Item and Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
              ],
            ),
            const SizedBox(height: 16),

            // Meeting Details Info
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
                          '📝 Ekstra Not (Kıyafet/Zaman vb.)',
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

            // Input form for Lender if status is pendingApproval or accepted
            if (isLender && item.status == EmanetStatus.pendingApproval) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Buluşma Detayı Ekle / Güncelle',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _meetingLocationController,
                decoration: const InputDecoration(
                  labelText: 'Buluşma Noktası',
                  hintText: 'örn. İİBF Kantin Çardaklar',
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
                  hintText: 'örn. Mavi montluyum, 09:15\'te orada olacağım',
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

  Widget _buildDeliveryTimeline(BuildContext context, DeliveryStatus status) {
    final theme = Theme.of(context);
    final steps = [
      {'status': DeliveryStatus.requestSent, 'title': 'Talep Gönderildi'},
      {'status': DeliveryStatus.accepted, 'title': 'Kabul Edildi'},
      {'status': DeliveryStatus.meetingPointSet, 'title': 'Konum Belirlendi'},
      {'status': DeliveryStatus.routingStarted, 'title': 'Rotada / Yolda'},
      {'status': DeliveryStatus.delivered, 'title': 'Eşya Teslim Edildi'},
      {'status': DeliveryStatus.completed, 'title': 'İşlem Tamamlandı'},
    ];

    final activeIndex = steps.indexWhere((step) => step['status'] == status);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        
        final color = isCompleted
            ? Colors.green
            : isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant;
                
        final icon = isCompleted
            ? Icons.check_circle
            : isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_off;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(icon, size: 22, color: color),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: index < activeIndex ? Colors.green : theme.colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  step['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
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

  Widget _buildSimulationControls(
    BuildContext context,
    EmanetItem item,
    bool isLender,
    bool isBorrower,
    AppState appState,
  ) {
    final theme = Theme.of(context);

    // If status is available (not active process), don't show controls
    if (item.status == EmanetStatus.available) {
      return const SizedBox();
    }

    Widget buildButton({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }

    // Timeline control flows based on who clicks what
    if (item.deliveryStatus == DeliveryStatus.requestSent) {
      if (isLender) {
        return buildButton(
          label: 'Talebi Kabul Et',
          icon: Icons.check,
          onPressed: () => appState.approveBorrow(item.id),
          color: Colors.green,
        );
      }
      return const Center(child: Text('Eşya sahibinin talebi kabul etmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.accepted) {
      if (isLender) {
        return const Center(child: Text('Lütfen yukarıdaki panelden bir buluşma noktası belirleyin.'));
      }
      return const Center(child: Text('Eşya sahibinin buluşma noktası girmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.meetingPointSet) {
      if (isBorrower) {
        return buildButton(
          label: 'Rotayı Başlat (Yola Çık)',
          icon: Icons.navigation_outlined,
          onPressed: () => appState.startRouting(item.id),
        );
      }
      return const Center(child: Text('Ödünç alan öğrencinin rotayı başlatıp buluşma noktasına gelmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.routingStarted) {
      if (isLender) {
        return buildButton(
          label: 'QR Göster & Teslim Et',
          icon: Icons.qr_code,
          onPressed: () {
            _showQrBottomSheet(context, item, 'borrow');
          },
          color: Colors.green,
        );
      }
      return buildButton(
        label: 'QR Tara & Teslim Al',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: () async {
          BorrowRequestModel? activeRequest;
          try {
            activeRequest = appState.borrowRequests.firstWhere(
              (r) => r.itemId == item.id && r.status == BorrowRequestStatus.accepted
            );
          } catch (_) {}
          final requestId = activeRequest?.id ?? 'mock';

          final scanned = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => QrScannerScreen(
                action: 'borrow',
                requestId: requestId,
              ),
            ),
          );
          if (scanned == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Eşya başarıyla teslim alındı!'), backgroundColor: Colors.green),
            );
          }
        },
        color: theme.colorScheme.secondary,
      );
    }

    // 1. Handover Complete / Active Borrow State Controls
    if (item.status == EmanetStatus.borrowed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBorrower) ...[
            buildButton(
              label: 'İade Talebi Gönder',
              icon: Icons.settings_backup_restore_rounded,
              onPressed: () {
                appState.requestReturn(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İade talebi gönderildi. Eşyayı sahibine teslim ederken QR kodunuzu gösterebilirsiniz.')),
                );
              },
              color: Colors.deepPurple,
            ),
          ] else if (isLender) ...[
            const Center(
              child: Text(
                'Eşya şu an ödünçte. İade talebi bekleniyor...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      );
    }

    // 2. Return Request Submitted State Controls
    if (item.status == EmanetStatus.pendingReturn) {
      if (isLender) {
        return buildButton(
          label: 'QR Tara & İade Al',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () async {
            BorrowRequestModel? activeRequest;
            try {
              activeRequest = appState.borrowRequests.firstWhere(
                (r) => r.itemId == item.id && r.status == BorrowRequestStatus.accepted
              );
            } catch (_) {}
            final requestId = activeRequest?.id ?? 'mock';

            final scanned = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => QrScannerScreen(
                  action: 'return',
                  requestId: requestId,
                ),
              ),
            );
            if (scanned == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eşya başarıyla iade alındı!'), backgroundColor: Colors.green),
              );
            }
          },
          color: Colors.green,
        );
      }
      return buildButton(
        label: 'QR Göster (İade Ediyorum)',
        icon: Icons.qr_code,
        onPressed: () {
          _showQrBottomSheet(context, item, 'return');
        },
        color: Colors.deepPurple,
      );
    }

    return const SizedBox();
  }

  void _showQrBottomSheet(
    BuildContext parentContext,
    EmanetItem item,
    String action,
  ) {
    final appState = AppStateProvider.of(parentContext);
    final theme = Theme.of(parentContext);

    BorrowRequestModel? activeRequest;
    try {
      activeRequest = appState.borrowRequests.firstWhere(
        (r) => r.itemId == item.id && 
               (r.status == BorrowRequestStatus.accepted ||
                r.status == BorrowRequestStatus.pendingDiscussion ||
                r.status == BorrowRequestStatus.onlyInquiry ||
                r.status == BorrowRequestStatus.completed)
      );
    } catch (_) {}

    final requestId = activeRequest?.id ?? 'mock_request_id_${item.id}';

    final qrData = appState.qrService.generateQrData(
      requestId: requestId,
      action: action,
    );

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                action == 'borrow' ? 'Emanet Teslim QR Kodu' : 'İade Alım QR Kodu',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Text(
                action == 'borrow'
                    ? 'Eşyayı alan öğrencinin bu QR kodu kendi kamerasından taramasını sağlayın.'
                    : 'İade eden öğrencinin size eşyayı getirmesiyle bu QR kodunu taranabilir yapın.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: MockQrPainter(),
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Kod: $qrData',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    
                    final errorMessage = await appState.processQrCode(qrData);

                    if (parentContext.mounted) {
                      if (errorMessage == null) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              action == 'borrow'
                                  ? 'Emanet başarıyla teslim edildi!'
                                  : 'İade başarıyla onaylandı ve eşya geri alındı!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Karşı Taraf Taramasını Simüle Et (Prototip)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter to draw QR code fallback preview
class MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlack = Paint()..color = Colors.black;
    final paintWhite = Paint()..color = Colors.white;

    // Background white box
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintWhite);

    // Three outer position detection boxes
    // Top-Left
    canvas.drawRect(const Rect.fromLTWH(10, 10, 45, 45), paintBlack);
    canvas.drawRect(const Rect.fromLTWH(17, 17, 31, 31), paintWhite);
    canvas.drawRect(const Rect.fromLTWH(22, 22, 21, 21), paintBlack);

    // Top-Right
    canvas.drawRect(Rect.fromLTWH(size.width - 55, 10, 45, 45), paintBlack);
    canvas.drawRect(Rect.fromLTWH(size.width - 48, 17, 31, 31), paintWhite);
    canvas.drawRect(Rect.fromLTWH(size.width - 43, 22, 21, 21), paintBlack);

    // Bottom-Left
    canvas.drawRect(Rect.fromLTWH(10, size.height - 55, 45, 45), paintBlack);
    canvas.drawRect(Rect.fromLTWH(17, size.height - 48, 31, 31), paintWhite);
    canvas.drawRect(Rect.fromLTWH(22, size.height - 43, 21, 21), paintBlack);

    // Draw some random pixels inside to look like a QR code
    final double pixelSize = 5.0;
    for (double y = 60; y < size.height - 10; y += pixelSize * 2) {
      for (double x = 60; x < size.width - 10; x += pixelSize * 2) {
        if ((x + y).hashCode % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paintBlack);
        }
        if ((x * y).hashCode % 4 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y + pixelSize, pixelSize, pixelSize), paintBlack);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
