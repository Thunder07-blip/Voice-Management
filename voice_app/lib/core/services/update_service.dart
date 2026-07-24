import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final bool isMandatory;
  final String? releaseNotes;
  final String downloadUrl;

  AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.isMandatory,
    this.releaseNotes,
    required this.downloadUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      isMandatory: json['is_mandatory'] as bool,
      releaseNotes: json['release_notes'] as String?,
      downloadUrl: json['download_url'] as String,
    );
  }
}

class UpdateService {
  final SupabaseClient _supabase;
  final Dio _dio = Dio();
  
  // Exposes download progress to UI
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  UpdateService(this._supabase);

  /// Checks if an update is available based on build number
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('status', 'active')
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final latestUpdate = AppUpdateInfo.fromJson(response);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (latestUpdate.buildNumber > currentBuild) {
        return latestUpdate;
      }
      return null;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return null;
    }
  }

  /// Downloads the APK and triggers the installer
  Future<bool> downloadAndInstallUpdate(String url) async {
    try {
      downloadProgress.value = 0.0;
      
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';
      
      // Delete old file if exists
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      final result = await OpenFilex.open(savePath);
      
      if (result.type == ResultType.done) {
        return true;
      } else {
        debugPrint('Failed to open APK: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error downloading update: $e');
      return false;
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(Supabase.instance.client);
});
