import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../providers/app_state_provider.dart';
import 'request_chat_screen.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  void _handleNotificationTap(BuildContext context, AppNotification notification, String currentUserId) {
    // 1. Non-blocking update of readAt using serverTimestamp
    if (!notification.isRead && Firebase.apps.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notification.id)
          .update({'readAt': FieldValue.serverTimestamp()})
          .catchError((error) {
            // Silently swallow errors to keep UI navigation responsive even on network hiccups
          });
    }

    // 2. Clean switch-case routing (Non-blocking navigation)
    final requestId = notification.requestId;

    switch (notification.type) {
      case 'chat':
      case 'pendingApproval':
      case 'accepted':
      case 'rejected':
      case 'cancelled':
      case 'completed':
        if (requestId != null && requestId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestChatScreen(requestId: requestId),
            ),
          );
        }
        break;
      default:
        if (requestId != null && requestId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestChatScreen(requestId: requestId),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final currentUserId = appState.currentUser?.uid;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: (currentUserId == null || Firebase.apps.isEmpty)
          ? const Center(child: Text('Lütfen önce giriş yapın.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Bildirimler yüklenirken bir hata oluştu.',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz bildirimiz yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = docs.map((doc) => AppNotification.fromDocument(doc)).toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 64, endIndent: 16),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isUnread = !notif.isRead;

                    IconData leadingIcon = Icons.notifications_rounded;
                    Color iconBgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
                    Color iconColor = theme.colorScheme.primary;

                    switch (notif.type) {
                      case 'chat':
                        leadingIcon = Icons.chat_bubble_rounded;
                        break;
                      case 'accepted':
                        leadingIcon = Icons.check_circle_rounded;
                        iconColor = Colors.green;
                        iconBgColor = Colors.green.withValues(alpha: 0.1);
                        break;
                      case 'rejected':
                      case 'cancelled':
                        leadingIcon = Icons.cancel_rounded;
                        iconColor = Colors.red;
                        iconBgColor = Colors.red.withValues(alpha: 0.1);
                        break;
                      case 'completed':
                        leadingIcon = Icons.verified_rounded;
                        iconColor = Colors.teal;
                        iconBgColor = Colors.teal.withValues(alpha: 0.1);
                        break;
                    }

                    return Material(
                      color: isUnread
                          ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        onTap: () => _handleNotificationTap(context, notif, currentUserId),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: iconBgColor,
                          child: Icon(leadingIcon, color: iconColor, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notif.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: notif.createdAt != null
                            ? Text(
                                _formatTime(notif.createdAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes}dk';
    if (difference.inHours < 24) return '${difference.inHours}s';
    if (difference.inDays < 7) return '${difference.inDays}g';
    return '${date.day}.${date.month}.${date.year}';
  }
}
