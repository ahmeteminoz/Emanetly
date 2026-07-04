import 'package:flutter/material.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_state.dart';
import '../models/item.dart';
import 'mock_route_screen.dart';

class ActiveTransactionsScreen extends StatelessWidget {
  const ActiveTransactionsScreen({super.key});

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

    // Filter items in active delivery or return progress
    final activeItems = appState.items.where((item) {
      // Current user is either borrower or lender
      final isParticipant = item.borrowerId == currentUser.uid || item.lenderId == currentUser.uid;
      // Item is not available and in delivery flow
      final inProgress = item.status != EmanetStatus.available;
      
      return isParticipant && inProgress;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktif Takip & Teslimatlar'),
        centerTitle: true,
      ),
      body: activeItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aktif işlem bulunmuyor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Ödünç verdiğiniz ya da ödünç aldığınız eşyaların teslimat ve iade rotalarını buradan canlı olarak takip edebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeItems.length,
              itemBuilder: (context, index) {
                final item = activeItems[index];
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
                            Text(
                              item.meetingPoint != null
                                  ? 'Konum: ${item.meetingPoint}'
                                  : 'Konum ayarlanmadı',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MockRouteScreen(item: item),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text('Rota / Takip', style: TextStyle(fontSize: 12)),
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
                );
              },
            ),
    );
  }
}
