import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: Text(
          'Vedic Oasis',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryContainer,
              child: Text(
                'S',
                style: TextStyle(
                  color: AppTheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Dashboard',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Community overview at a glance',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards — Bento-style grid
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.group,
                    label: 'Members',
                    value: '124',
                    color: AppTheme.primaryContainer,
                    iconColor: AppTheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.assignment,
                    label: 'Active Tasks',
                    value: '18',
                    color: AppTheme.secondaryContainer,
                    iconColor: AppTheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.event_busy,
                    label: 'On Leave',
                    value: '3',
                    color: AppTheme.tertiaryContainer,
                    iconColor: AppTheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.campaign,
                    label: 'Notices',
                    value: '7',
                    color: AppTheme.surfaceContainerHigh,
                    iconColor: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Tasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Tasks',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Task preview cards
            _TaskPreviewCard(
              title: 'Prepare Monthly Report',
              priority: 'High',
              dueDate: 'Due: Tomorrow',
              status: 'In Progress',
            ),
            const SizedBox(height: 12),
            _TaskPreviewCard(
              title: 'Organize Workshop Material',
              priority: 'Medium',
              dueDate: 'Due: Oct 28',
              status: 'Pending',
            ),
            const SizedBox(height: 12),
            _TaskPreviewCard(
              title: 'Kitchen Supply Check',
              priority: 'Low',
              dueDate: 'Due: Oct 30',
              status: 'Pending',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.onSurface,
                  fontSize: 32,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskPreviewCard extends StatelessWidget {
  final String title;
  final String priority;
  final String dueDate;
  final String status;

  const _TaskPreviewCard({
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.status,
  });

  Color get _priorityBgColor {
    switch (priority) {
      case 'High':
        return AppTheme.errorContainer;
      case 'Medium':
        return const Color(0xFFFFDDB8); // primary-fixed
      default:
        return AppTheme.surfaceContainerHigh;
    }
  }

  Color get _priorityTextColor {
    switch (priority) {
      case 'High':
        return AppTheme.onErrorContainer;
      case 'Medium':
        return const Color(0xFF2A1700); // on-primary-fixed
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _priorityTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dueDate,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
