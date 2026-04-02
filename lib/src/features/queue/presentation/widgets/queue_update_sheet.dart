import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/repositories/firebase_storage_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class QueueUpdateSheet extends StatefulWidget {
  const QueueUpdateSheet({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  static Future<void> show(
    BuildContext context, {
    required String placeId,
    required String placeName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueUpdateSheet(placeId: placeId, placeName: placeName),
    );
  }

  @override
  State<QueueUpdateSheet> createState() => _QueueUpdateSheetState();
}

class _QueueUpdateSheetState extends State<QueueUpdateSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  XFile? _selectedImage;
  Uint8List? _previewBytes;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _previewBytes = bytes;
    });
  }

  Future<void> _submit(QueueLevel level) async {
    final authRepository = context.read<AuthRepository>();
    final queueRepository = context.read<FirestoreQueueRepository>();
    final storageRepository = context.read<FirebaseStorageRepository>();
    final currentUser = authRepository.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);
    try {
      final reportId = await queueRepository.createQueueReportDraft(
        placeId: widget.placeId,
        userId: currentUser.uid,
        level: level,
        placeName: widget.placeName,
      );

      if (_selectedImage != null && _previewBytes != null) {
        final extension = _selectedImage!.name.split('.').last.toLowerCase();
        final result = await storageRepository.uploadQueueImage(
          reportId: reportId,
          bytes: _previewBytes!,
          extension: extension,
          contentType: _contentTypeForExtension(extension),
        );

        await queueRepository.attachImageToReport(
          reportId: reportId,
          imageUrl: result.downloadUrl,
          storagePath: result.storagePath,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue updated for ${widget.placeName}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit update: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 32,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'CURRENT STATUS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.8,
                  color: AppColors.accentSoft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How\'s the queue at\n${widget.placeName}?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              if (_previewBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    _previewBytes!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _selectedImage == null ? 'Attach image' : 'Change image',
                ),
              ),
              const SizedBox(height: 18),
              _StatusButton(
                level: QueueLevel.short,
                subtitle: 'Under 5 minutes',
                icon: Icons.check_rounded,
                onTap: _isSubmitting ? null : () => _submit(QueueLevel.short),
              ),
              const SizedBox(height: 12),
              _StatusButton(
                level: QueueLevel.medium,
                subtitle: '5 to 15 minutes',
                icon: Icons.pause_rounded,
                onTap: _isSubmitting ? null : () => _submit(QueueLevel.medium),
              ),
              const SizedBox(height: 12),
              _StatusButton(
                level: QueueLevel.long,
                subtitle: 'Over 15 minutes',
                icon: Icons.priority_high_rounded,
                onTap: _isSubmitting ? null : () => _submit(QueueLevel.long),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.level,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final QueueLevel level;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: level.color.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: level.color,
              ),
              child: Icon(icon, color: AppColors.ink900),
            ),
          ],
        ),
      ),
    );
  }
}
