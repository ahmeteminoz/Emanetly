import 'package:flutter/material.dart';
import '../../models/meeting_point_proposal.dart';
import '../../providers/app_state_provider.dart';

class MeetingPointProposalCard extends StatelessWidget {
  final String proposalId;

  const MeetingPointProposalCard({
    super.key,
    required this.proposalId,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final proposal = appState.getProposal(proposalId);

    if (proposal == null) {
      return const SizedBox.shrink();
    }

    final isProposer = appState.currentUser?.uid == proposal.proposedByUserId;
    final isPending = proposal.status == MeetingPointStatus.pending;
    
    // Determine proposer name
    String proposerName = 'Diğer Kullanıcı';
    if (isProposer) {
      proposerName = 'Siz';
    } else {
      if (proposal.proposedByUserId == 'user_1') proposerName = 'Ahmet Öz';
      if (proposal.proposedByUserId == 'user_2') proposerName = 'Ayşe Yılmaz';
      if (proposal.proposedByUserId == 'user_3') proposerName = 'Can Demir';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: proposal.status == MeetingPointStatus.accepted
              ? Colors.green.shade300
              : proposal.status == MeetingPointStatus.rejected
                  ? Colors.red.shade300
                  : theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      color: proposal.status == MeetingPointStatus.accepted
          ? Colors.green.shade50.withOpacity(0.5)
          : proposal.status == MeetingPointStatus.rejected
              ? Colors.red.shade50.withOpacity(0.5)
              : theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status icon
            Row(
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 20,
                  color: proposal.status == MeetingPointStatus.accepted
                      ? Colors.green
                      : proposal.status == MeetingPointStatus.rejected
                          ? Colors.red
                          : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    proposal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStatusBadge(proposal, theme),
              ],
            ),
            const SizedBox(height: 8),
            // Address details
            Text(
              proposal.addressText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            // Proposed Time & Creator
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Saat: ${proposal.proposedTimeText}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Öneren: $proposerName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            // Interactive Buttons if pending and current user is NOT proposer
            if (isPending && !isProposer) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => appState.rejectMeetingPoint(proposalId),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Reddet'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => appState.acceptMeetingPoint(proposalId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Onayla'),
                  ),
                ],
              ),
            ] else if (isPending && isProposer) ...[
              const SizedBox(height: 8),
              Text(
                'Karşı tarafın onaylaması bekleniyor...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MeetingPointProposalModel proposal, ThemeData theme) {
    switch (proposal.status) {
      case MeetingPointStatus.accepted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Onaylandı',
            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );
      case MeetingPointStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Reddedildi',
            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );
      case MeetingPointStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Beklemede',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}
