import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appNotificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(db.notificationsTable)
                    ..where((item) => item.readAt.isNull()))
                  .write(NotificationsTableCompanion(readAt: drift.Value(DateTime.now())));
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load notifications: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: item.readAt == null
                    ? AppTheme.primaryContainer.withValues(alpha: 0.45)
                    : AppTheme.surfaceContainerLowest,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryContainer,
                    child: Icon(Icons.event_note, color: AppTheme.onPrimaryContainer),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${item.body}\n${DateFormat('d MMM, h:mm a').format(item.createdAt)}',
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    if (item.readAt != null) return;
                    final db = ref.read(databaseProvider);
                    await (db.update(db.notificationsTable)
                          ..where((row) => row.id.equals(item.id)))
                        .write(NotificationsTableCompanion(readAt: drift.Value(DateTime.now())));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
