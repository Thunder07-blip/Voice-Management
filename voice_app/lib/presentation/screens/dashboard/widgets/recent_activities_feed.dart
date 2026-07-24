import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../data/local/database.dart';
import '../../../../core/theme/app_theme.dart';

class RecentActivitiesFeed extends ConsumerWidget {
  const RecentActivitiesFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    
    return StreamBuilder<List<Activity>>(
      stream: (db.select(db.activitiesTable)
            ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
            ..limit(10))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];
        
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final todayActivities = activities.where((a) => 
          a.createdAt.year == today.year && 
          a.createdAt.month == today.month && 
          a.createdAt.day == today.day
        ).toList();

        final yesterdayActivities = activities.where((a) => 
          a.createdAt.year == yesterday.year && 
          a.createdAt.month == yesterday.month && 
          a.createdAt.day == yesterday.day
        ).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              if (activities.isEmpty)
                _buildEmptyState('No recent activities.')
              else ...[
                if (todayActivities.isNotEmpty) ...[
                  _buildSectionHeader('Today'),
                  ...todayActivities.map((a) => _buildActivityItem(a)),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildSectionHeader('Today'),
                  _buildEmptyState('No activities yet.'),
                  const SizedBox(height: 16),
                ],

                if (yesterdayActivities.isNotEmpty) ...[
                  const Divider(color: AppTheme.outlineVariant),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Yesterday'),
                  ...yesterdayActivities.map((a) => _buildActivityItem(a)),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    // Add implicit animation using TweenAnimationBuilder for the slide-in effect
    return TweenAnimationBuilder<double>(
      key: ValueKey(activity.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 12),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(activity.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
