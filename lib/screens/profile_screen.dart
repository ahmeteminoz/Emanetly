import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı girişi yapılmadı.'));
    }

    // Filter items
    final myListedItems = appState.items.where((i) => i.lenderId == currentUser.uid).toList();
    final myBorrowedItems = appState.items.where((i) => i.borrowerId == currentUser.uid).toList();
    final pendingIncomingRequests = myListedItems.where((i) => i.status == EmanetStatus.pendingApproval).toList();
    final pendingIncomingReturns = myListedItems.where((i) => i.status == EmanetStatus.pendingReturn).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Student Profile Card & Mock Switcher
          _buildUserProfileHeader(context, currentUser, appState),
          
          // Tab Headers
          TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Emanetlerim', icon: Icon(Icons.share)),
              Tab(text: 'Ödünçlerim', icon: Icon(Icons.shopping_bag_outlined)),
              Tab(text: 'Aktiviteler', icon: Icon(Icons.history)),
            ],
          ),
          
          // Tab Body
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Listings & Requests
                _buildListingsTab(context, myListedItems, pendingIncomingRequests, pendingIncomingReturns),
                
                // Tab 2: Borrowed items
                _buildBorrowedTab(context, myBorrowedItems),
                
                // Tab 3: Simulation Log
                _buildLogsTab(context, appState.activityLogs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(
    BuildContext context,
    UserProfile user,
    dynamic appState,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.department,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'Öğrenci No: ${user.studentId}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                  tooltip: 'Görünüm Ayarları',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Simulation Swapper Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.swap_horizontal_circle_outlined, color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Test Kullanıcısı Değiştir:',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: user.uid,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  items: appState.availableMockUsers.map<DropdownMenuItem<String>>((UserProfile u) {
                    return DropdownMenuItem<String>(
                      value: u.uid,
                      child: Text(u.name.split(' ')[0]), // Only show first name
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      appState.switchUser(value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsTab(
    BuildContext context,
    List<EmanetItem> items,
    List<EmanetItem> pendingRequests,
    List<EmanetItem> pendingReturns,
  ) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Pending Approvals/Handover requests
        if (pendingRequests.isNotEmpty || pendingReturns.isNotEmpty) ...[
          Text(
            'İşlem Bekleyen Talepler',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange[800]),
          ),
          const SizedBox(height: 8),
          ...pendingRequests.map((item) => _buildRequestCard(context, item, 'borrow')),
          ...pendingReturns.map((item) => _buildRequestCard(context, item, 'return')),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // 2. Active listings
        Text(
          'Yayınladığım İlanlar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Henüz hiç eşya paylaşmadınız.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          )
        else
          ...items.map((item) => _buildItemTile(context, item)),
      ],
    );
  }

  Widget _buildBorrowedTab(BuildContext context, List<EmanetItem> items) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ödünç Aldığım Eşyalar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Şu anda ödünç aldığınız bir eşya bulunmuyor.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          )
        else
          ...items.map((item) => _buildItemTile(context, item)),
      ],
    );
  }

  Widget _buildLogsTab(BuildContext context, List<String> logs) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history_toggle_off, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    logs[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemTile(BuildContext context, EmanetItem item) {
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;

    switch (item.status) {
      case EmanetStatus.available:
        statusText = 'Aktif';
        statusColor = Colors.green;
        break;
      case EmanetStatus.pendingApproval:
        statusText = 'Onay Bekliyor';
        statusColor = Colors.orange;
        break;
      case EmanetStatus.borrowed:
        statusText = 'Ödünçte';
        statusColor = Colors.red;
        break;
      case EmanetStatus.pendingReturn:
        statusText = 'İade Ediliyor';
        statusColor = Colors.deepPurple;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Konum: ${item.location} • ${item.category}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, EmanetItem item, String requestType) {
    final theme = Theme.of(context);

    final isBorrow = requestType == 'borrow';
    final title = isBorrow ? 'Ödünç Talebi' : 'İade Talebi';
    final details = isBorrow
        ? '${item.borrowerName} bu eşyayı ödünç almak istiyor.'
        : '${item.borrowerName} bu eşyayı teslim etmek istiyor.';
    final cardColor = isBorrow ? Colors.orange.withOpacity(0.05) : Colors.deepPurple.withOpacity(0.05);
    final borderColor = isBorrow ? Colors.orange.withOpacity(0.3) : Colors.deepPurple.withOpacity(0.3);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBorrow ? Icons.shopping_bag_outlined : Icons.assignment_return_outlined,
                  color: isBorrow ? Colors.orange : Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBorrow ? Colors.orange[800] : Colors.deepPurple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(item: item),
                      ),
                    );
                  },
                  child: const Text('Detayı Gör & QR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
