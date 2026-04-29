import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

class StorageService {
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  SupabaseClient get _client => SupabaseService.client;

  Future<String> uploadFile(
    File file,
    String bucket, {
    required String pathPrefix,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
      final path = '$pathPrefix/$fileName';

      await _client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(
              upsert: false,
            ),
          );

      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }

  Future<String> uploadProfilePicture(File file, String userId) {
    return uploadFile(
      file,
      'profile-pictures',
      pathPrefix: userId,
    );
  }

  Future<String> uploadCourtImage(File file, String courtId) {
    return uploadFile(
      file,
      'court-images',
      pathPrefix: courtId,
    );
  }

  Future<String> uploadTennisCenterImage(File file, String centerId) {
    return uploadFile(
      file,
      'tennis-center-images',
      pathPrefix: centerId,
    );
  }

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final objectIndex = pathSegments.indexOf('public');
      if (objectIndex == -1 || objectIndex + 2 >= pathSegments.length) {
        throw Exception('Unsupported storage URL');
      }

      final bucket = pathSegments[objectIndex + 1];
      final path = pathSegments.sublist(objectIndex + 2).join('/');
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting file: $e');
      throw Exception('Failed to delete file');
    }
  }
}
