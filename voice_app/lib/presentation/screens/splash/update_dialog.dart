import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/update_service.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  String _errorMessage = '';

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = '';
    });

    final updateService = ref.read(updateServiceProvider);
    final success = await updateService.downloadAndInstallUpdate(widget.updateInfo.downloadUrl);

    if (mounted) {
      if (!success) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Failed to download or install update. Please try again.';
        });
      }
      // If success, the external installer opens, and we just wait.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateService = ref.watch(updateServiceProvider);

    return PopScope(
      canPop: !widget.updateInfo.isMandatory && !_isDownloading,
      child: Dialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.system_update_alt, color: AppTheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Available',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Version ${widget.updateInfo.version}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.updateInfo.releaseNotes?.isNotEmpty == true) ...[
                Text(
                  'What\'s New',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.updateInfo.releaseNotes!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.error),
                ),
                const SizedBox(height: 16),
              ],
              if (_isDownloading) ...[
                ValueListenableBuilder<double>(
                  valueListenable: updateService.downloadProgress,
                  builder: (context, progress, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading...',
                              style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            color: AppTheme.primary,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!widget.updateInfo.isMandatory && !_isDownloading)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                  if (!_isDownloading) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _startUpdate,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                      ),
                      child: const Text('Update Now'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
