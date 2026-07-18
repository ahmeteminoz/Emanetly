import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import 'meeting_point_proposal_card.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String? senderNameOverride;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderNameOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // SYSTEM MESSAGE RENDER
    if (message.type == ChatMessageType.system || message.type == ChatMessageType.requestStatusUpdate) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // MEETING POINT PROPOSAL RENDER
    if (message.type == ChatMessageType.meetingPointProposal) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Buluşma Noktası Önerildi',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (message.customPayload != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MeetingPointProposalCard(
                proposalId: message.customPayload!,
              ),
            ),
        ],
      );
    }

    // STANDARD CHAT MESSAGE BUBBLE
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                senderNameOverride ?? message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: isMe 
                          ? theme.colorScheme.onPrimary.withOpacity(0.7) 
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: message.isRead 
                          ? (theme.brightness == Brightness.dark 
                              ? const Color(0xFF1565C0) // Karanlık modda belirgin koyu mavi
                              : const Color(0xFF80D8FF)) // Aydınlık modda açık mavi/cyan
                          : theme.colorScheme.onPrimary.withOpacity(0.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
