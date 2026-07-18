import 'package:flutter/material.dart';
import '../providers/app_state_provider.dart';
import '../models/item.dart';
import '../models/borrow_request.dart';
import 'mock_route_screen.dart';
import 'request_chat_screen.dart';

class ActiveTransactionsScreen extends StatefulWidget {
  const ActiveTransactionsScreen({super.key});

  @override
  State<ActiveTransactionsScreen> createState() => _ActiveTransactionsScreenState();
}

class _ActiveTransactionsScreenState extends State<ActiveTransactionsScreen> {
  int _selectedTab = 0; // 0: Bize Gelenler, 1: Bizim Sorduklarımız

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın.')),
      );
    }

    // 1. Filter active routing items
    final allActiveItems = appState.items.where((item) {
      final isParticipant = item.borrowerId == currentUser.uid || item.lenderId == currentUser.uid;
      final inProgress = item.status != EmanetStatus.available && item.status != EmanetStatus.archived;
      return isParticipant && inProgress;
    }).toList();

    // 2. Filter requests under pre-agreement chat discussion (include both discussion and onlyInquiry)
    final allDiscussionRequests = appState.borrowRequests.where((req) {
      final isParticipant = req.ownerId == currentUser.uid || req.requesterId == currentUser.uid;
      final isChatting = req.status == BorrowRequestStatus.pendingDiscussion || 
                         req.status == BorrowRequestStatus.onlyInquiry;
      return isParticipant && isChatting;
    }).toList();

    // 3. Segment lists based on selected Tab
    // Tab 0: Bize Gelenler (We are the Lender)
    final incomingChats = allDiscussionRequests.where((r) => r.ownerId == currentUser.uid).toList();
    final incomingDeliveries = allActiveItems.where((i) => i.lenderId == currentUser.uid).toList();

    // Tab 1: Bizim Sorduklarımız (We are the Requester/Borrower)
    final outgoingChats = allDiscussionRequests.where((r) => r.requesterId == currentUser.uid).toList();
    final outgoingDeliveries = allActiveItems.where((i) => i.borrowerId == currentUser.uid).toList();

    // Active arrays for rendering
    final activeChats = _selectedTab == 0 ? incomingChats : outgoingChats;
    final activeDeliveries = _selectedTab == 0 ? incomingDeliveries : outgoingDeliveries;

    final isListEmpty = activeChats.isEmpty && activeDeliveries.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar & Aktif Takip'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Premium Pill-style Segmented Tab Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Tab 0: Bize Gelenler
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Gelen Kutusu',
                            style: TextStyle(
                              color: _selectedTab == 0 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tab 1: Taleplerim
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Taleplerim',
                            style: TextStyle(
                              color: _selectedTab == 1 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Contents Area
            Expanded(
              child: isListEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 80,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0
                                ? 'Gelen kutunuz boş'
                                : 'Aktif talebiniz bulunmuyor',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _selectedTab == 0
                                  ? 'Diğer öğrencilerin sizin ilanlarınıza sorduğu sorular veya ödünç talepleri buraya düşer.'
                                  : 'Ödünç almak için soru sorduğunuz veya talep gönderdiğiniz ilanların durumunu buradan takip edebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        // SECTION 1: Chat Inbox (Sohbetler)
                        if (activeChats.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.mail_outline_rounded, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTab == 0 ? 'Gelen Sorular & Talepler' : 'Giden Sorular & Talepler',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...activeChats.map((request) {
                            // Find matching item details
                            EmanetItem? matchingItem;
                            try {
                              matchingItem = appState.items.firstWhere((i) => i.id == request.itemId);
                            } catch (_) {
                              matchingItem = null;
                            }

                            if (matchingItem == null) return const SizedBox.shrink();

                            final isLender = request.ownerId == currentUser.uid;
                            String partyName = 'Bilinmeyen Kullanıcı';
                            String roleLabel = '';
                            if (isLender) {
                              roleLabel = 'Alıcı Adayı';
                              if (request.requesterId == 'user_1') partyName = 'Ahmet Öz';
                              if (request.requesterId == 'user_2') partyName = 'Ayşe Yılmaz';
                              if (request.requesterId == 'user_3') partyName = 'Can Demir';
                            } else {
                              roleLabel = 'Eşya Sahibi';
                              partyName = matchingItem.lenderName;
                            }

                            // Get last message
                            final messages = appState.getChatMessagesForRequest(request.id);
                            String lastMessageText = 'Henüz mesaj yok';
                            String lastMessageTime = '';
                            if (messages.isNotEmpty) {
                              final lastMsg = messages.last;
                              final senderName = lastMsg.senderId == currentUser.uid ? 'Siz' : lastMsg.senderName;
                              lastMessageText = '$senderName: ${lastMsg.text}';
                              lastMessageTime = lastMsg.createdAt.toLocal().toString().substring(11, 16);
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                              ),
                              color: Colors.orange.shade50.withOpacity(0.08),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestChatScreen(requestId: request.id),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: Text(
                                          partyName.isNotEmpty ? partyName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  partyName,
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (lastMessageTime.isNotEmpty)
                                                  Text(
                                                    lastMessageTime,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.outline,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${matchingItem.title} ($roleLabel)',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessageText,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],

                        // SECTION 2: ACTIVE DELIVERY & ROUTING
                        if (activeDeliveries.isNotEmpty) ...[
                          if (activeChats.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Icon(Icons.directions_walk_rounded, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTab == 0 ? 'Aktif Emanetlerin (Verdiklerin)' : 'Aktif Emanetlerin (Aldıkların)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...activeDeliveries.map((item) {
                            final isLender = item.lenderId == currentUser.uid;
                            
                            // Construct progress message
                            String stageText = 'Talep Gönderildi';
                            IconData stageIcon = Icons.send_outlined;
                            Color stageColor = Colors.orange;

                            if (item.status == EmanetStatus.pendingReturn) {
                              stageText = 'İade Onayı Bekliyor';
                              stageIcon = Icons.settings_backup_restore_rounded;
                              stageColor = Colors.deepPurple;
                            } else {
                              switch (item.deliveryStatus) {
                                case DeliveryStatus.requestSent:
                                  stageText = 'Talep Gönderildi';
                                  stageIcon = Icons.send_outlined;
                                  stageColor = Colors.orange;
                                  break;
                                case DeliveryStatus.accepted:
                                  stageText = 'İstek Kabul Edildi';
                                  stageIcon = Icons.check_circle_outline;
                                  stageColor = Colors.green;
                                  break;
                                case DeliveryStatus.meetingPointSet:
                                  stageText = 'Buluşma Noktası Hazır';
                                  stageIcon = Icons.location_on_outlined;
                                  stageColor = Colors.blue;
                                  break;
                                case DeliveryStatus.routingStarted:
                                  stageText = 'Yolda / Buluşmaya Geliyor';
                                  stageIcon = Icons.directions_walk_rounded;
                                  stageColor = Colors.blue;
                                  break;
                                case DeliveryStatus.delivered:
                                  stageText = 'Teslimat Gerçekleşti';
                                  stageIcon = Icons.done_all_rounded;
                                  stageColor = Colors.green;
                                  break;
                                case DeliveryStatus.completed:
                                  stageText = 'Emanet Sürecinde';
                                  stageIcon = Icons.hourglass_bottom_rounded;
                                  stageColor = Colors.teal;
                                  break;
                                default:
                                  break;
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // Find the request ID associated with this item
                                  String? requestId;
                                  try {
                                    requestId = appState.borrowRequests.firstWhere(
                                      (r) => r.itemId == item.id && 
                                             (r.status == BorrowRequestStatus.accepted || 
                                              r.status == BorrowRequestStatus.completed)
                                    ).id;
                                  } catch (_) {}

                                  if (requestId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RequestChatScreen(requestId: requestId!),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MockRouteScreen(item: item),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: stageColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: stageColor.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(stageIcon, size: 14, color: stageColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  stageText,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: stageColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            isLender ? 'Verdiğin Emanet' : 'Aldığın Emanet',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isLender ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item.title,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            isLender 
                                                ? 'Alıcı: ${item.borrowerName ?? "Bilinmiyor"}'
                                                : 'Sahibi: ${item.lenderName}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.meetingPoint != null
                                                  ? 'Konum: ${item.meetingPoint}'
                                                  : 'Konum ayarlanmadı',
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // Find the request ID associated with this item and navigate to chat
                                              String? requestId;
                                              try {
                                                requestId = appState.borrowRequests.firstWhere(
                                                  (r) => r.itemId == item.id && 
                                                         (r.status == BorrowRequestStatus.accepted || 
                                                          r.status == BorrowRequestStatus.completed)
                                                ).id;
                                              } catch (_) {}

                                              if (requestId != null) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => RequestChatScreen(requestId: requestId!),
                                                  ),
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => MockRouteScreen(item: item),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.forum_outlined, size: 16),
                                            label: const Text('Detay & Sohbet', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
