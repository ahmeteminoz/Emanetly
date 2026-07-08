import 'package:flutter/material.dart';
import '../models/borrow_request.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/borrow_request_status_card.dart';
import 'mock_route_screen.dart';

class RequestChatScreen extends StatefulWidget {
  final String requestId;

  const RequestChatScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestChatScreen> createState() => _RequestChatScreenState();
}

class _RequestChatScreenState extends State<RequestChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showProposeMeetingSheet(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Buluşma Noktası Öner',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Buluşma Noktası Başlığı',
                    hintText: 'Örn: Mühendislik B Blok Önü',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Detaylı Adres / Açıklama',
                    hintText: 'Örn: Giriş kapısı merdivenleri önü',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Buluşma Saati',
                    hintText: 'Örn: 14:30 veya Ders Bitimi',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        addressController.text.isNotEmpty &&
                        timeController.text.isNotEmpty) {
                      appState.proposeMeetingPoint(
                        widget.requestId,
                        titleController.text.trim(),
                        addressController.text.trim(),
                        timeController.text.trim(),
                      );
                      Navigator.pop(context);
                      _scrollToBottom();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Öneriyi Gönder'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Fetch request
    BorrowRequestModel? request;
    try {
      request = appState.borrowRequests.firstWhere((r) => r.id == widget.requestId);
    } catch (_) {
      request = null;
    }

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Talep Bulunamadı')),
        body: const Center(child: Text('Aradığınız talep veritabanında mevcut değil.')),
      );
    }

    // Fetch item
    EmanetItem? item;
    try {
      item = appState.items.firstWhere((i) => i.id == request!.itemId);
    } catch (_) {
      item = null;
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ürün Bulunamadı')),
        body: const Center(child: Text('Talebe ait ürün bulunamadı.')),
      );
    }

    final isOwner = appState.currentUser?.uid == request.ownerId;
    final messages = appState.getChatMessagesForRequest(widget.requestId);
    final isPendingDiscussion = request.status == BorrowRequestStatus.pendingDiscussion;
    final isAccepted = request.status == BorrowRequestStatus.accepted;
    final isRejected = request.status == BorrowRequestStatus.rejected;

    // Auto scroll bottom when build finishes
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwner ? 'Ödünç Alma Talebi' : 'Ön Görüşme Chat',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (isPendingDiscussion)
            IconButton(
              icon: const Icon(Icons.handshake),
              tooltip: 'Buluşma Noktası Öner',
              onPressed: () => _showProposeMeetingSheet(context, appState),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. PRODUCT MINI HEADER CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Small Image Representative
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(item.mockImageColorValue).withOpacity(0.8),
                            Color(item.mockImageColorValue),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined, size: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 9, 
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_outlined, size: 10, color: theme.colorScheme.outline),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.pickupLocationTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Trust Rating representation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            const Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          isOwner ? 'Talep Eden' : 'Sahip Puanı',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 8, color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status Card Banner
                BorrowRequestStatusCard(
                  status: request.status,
                  requestedDurationText: request.requestedDurationText,
                ),
              ],
            ),
          ),

          // 2. CONVERSATION MESSAGES LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == appState.currentUser?.uid;
                return ChatMessageBubble(
                  message: message,
                  isMe: isMe,
                );
              },
            ),
          ),

          // 3. ACTIONS PANEL DRAWER (Accept/Reject, Rota redirect)
          if (isPendingDiscussion && isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Eşya Sahibi Karar Paneli:',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => appState.rejectBorrowRequest(widget.requestId),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Talebi Reddet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => appState.acceptBorrowRequest(widget.requestId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('Talebi Kabul Et'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (isAccepted)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Talep kabul edildi! Teslimat süreci başladı.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MockRouteScreen(item: item!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_run_rounded),
                      label: const Text('Teslimat & Rota Takibine Git'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isRejected)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded, color: theme.colorScheme.error, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu talep reddedildiği için görüşme sonlandırıldı.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. MESSAGE INPUT BOX BAR
          if (isPendingDiscussion)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    // Suggest button shortcut
                    IconButton(
                      icon: Icon(Icons.add_location_alt_outlined, color: theme.colorScheme.primary),
                      tooltip: 'Buluşma Noktası Öner',
                      onPressed: () => _showProposeMeetingSheet(context, appState),
                    ),
                    const SizedBox(width: 8),
                    // Message Text Field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Mesaj yazın...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) {
                          if (_messageController.text.isNotEmpty) {
                            appState.sendChatMessage(widget.requestId, _messageController.text.trim());
                            _messageController.clear();
                            _scrollToBottom();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          appState.sendChatMessage(widget.requestId, _messageController.text.trim());
                          _messageController.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
