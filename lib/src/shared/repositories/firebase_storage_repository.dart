import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class UploadResult {
  const UploadResult({required this.downloadUrl, required this.storagePath});

  final String downloadUrl;
  final String storagePath;
}

class FirebaseStorageRepository {
  FirebaseStorageRepository(this._storage);

  final FirebaseStorage _storage;

  Future<UploadResult> uploadQueueImage({
    required String reportId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final sanitizedExtension = extension.isEmpty ? 'jpg' : extension;
    final storagePath = 'queue_reports/$reportId/image.$sanitizedExtension';
    final reference = _storage.ref(storagePath);

    await reference.putData(bytes, SettableMetadata(contentType: contentType));

    final downloadUrl = await reference.getDownloadURL();
    return UploadResult(downloadUrl: downloadUrl, storagePath: storagePath);
  }

  Future<void> deleteFile(String storagePath) async {
    await _storage.ref(storagePath).delete();
  }
}
