import 'package:flutter/material.dart';
import '../../models/borrow_request.dart';

class BorrowRequestStatusCard extends StatelessWidget {
  final BorrowRequestStatus status;
  final String requestedDurationText;

  const BorrowRequestStatusCard({
    super.key,
    required this.status,
    required this.requestedDurationText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine details based on status
    Color cardColor;
    Color textColor;
    String statusTitle;
    String statusSubtitle;
    IconData icon;

    switch (status) {
      case BorrowRequestStatus.onlyInquiry:
        cardColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        statusTitle = 'Soru Soruluyor / Bilgi Alınıyor';
        statusSubtitle = 'Ödünç talebi göndermeden önce eşya sahibine sorularınızı iletebilirsiniz.';
        icon = Icons.info_outline;
        break;
      case BorrowRequestStatus.pendingDiscussion:
        cardColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        statusTitle = 'Görüşme Aşamasında';
        statusSubtitle = 'Eşya sahibi talebi onaylamadan önce detayları konuşabilirsiniz.';
        icon = Icons.question_answer_outlined;
        break;
      case BorrowRequestStatus.accepted:
        cardColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        statusTitle = 'Talep Kabul Edildi!';
        statusSubtitle = 'Haritayı açarak teslimat rotasını takip edebilirsiniz.';
        icon = Icons.check_circle_outline;
        break;
      case BorrowRequestStatus.rejected:
        cardColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        statusTitle = 'Talep Reddedildi';
        statusSubtitle = 'Eşya sahibi bu talebi reddetti veya sonlandırdı.';
        icon = Icons.cancel_outlined;
        break;
      case BorrowRequestStatus.cancelled:
        cardColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusTitle = 'Talep İptal Edildi';
        statusSubtitle = 'Bu ödünç talebi iptal edildi.';
        icon = Icons.block_outlined;
        break;
      case BorrowRequestStatus.expired:
        cardColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusTitle = 'Talebin Süresi Doldu';
        statusSubtitle = 'Talep yanıtlanmadığı için süresi doldu.';
        icon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İstenen Süre: $requestedDurationText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
