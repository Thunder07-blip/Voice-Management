import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class InchargesScreen extends StatefulWidget {
  const InchargesScreen({super.key});

  @override
  State<InchargesScreen> createState() => _InchargesScreenState();
}

class _InchargesScreenState extends State<InchargesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _mockIncharges = [
    {'name': 'HG Ram Das', 'role': 'Hostel Warden'},
    {'name': 'HG Shyam Prabhu', 'role': 'Kitchen Head'},
    {'name': 'HG Govinda Das', 'role': 'Maintenance Incharge'},
    {'name': 'HG Madhava Prabhu', 'role': 'Security Head'},
    {'name': 'HG Hari Das', 'role': 'Library Manager'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredIncharges {
    final query = _searchController.text.toLowerCase();
    return _mockIncharges.where((incharge) {
      final nameMatches = incharge['name']!.toLowerCase().contains(query);
      final roleMatches = incharge['role']!.toLowerCase().contains(query);
      return nameMatches || roleMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedIncharges = _filteredIncharges;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Incharges',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or role...',
                prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${displayedIncharges.length} Incharges Found',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: displayedIncharges.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final incharge = displayedIncharges[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.secondaryContainer,
                          child: Text(
                            incharge['name']![3].toUpperCase(), // Just skipping 'HG ' for initials
                            style: const TextStyle(
                              color: AppTheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incharge['name']!,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                incharge['role']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
