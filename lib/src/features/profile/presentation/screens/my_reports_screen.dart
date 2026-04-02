import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/utils/time_formatter.dart';
import 'package:queue/src/core/widgets/empty_state_view.dart';
import 'package:queue/src/core/widgets/error_view.dart';
import 'package:queue/src/core/widgets/loading_view.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/models/queue_report.dart';
import 'package:queue/src/shared/repositories/firebase_storage_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: EmptyStateView(
          title: 'Not signed in',
          subtitle: 'Sign in to manage your queue reports.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Queue Updates')),
      body: StreamBuilder<List<QueueReport>>(
        stream: context.read<FirestoreQueueRepository>().watchUserReports(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(message: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const LoadingView();
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const EmptyStateView(
              title: 'No updates yet',
              subtitle:
                  'Submit your first queue report from the list or map screen.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final QueueReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.placeName ?? report.placeId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: report.queueLevel.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.queueLevel.label,
                    style: TextStyle(
                      color: report.queueLevel.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              TimeFormatter.queueWindowLabel(report.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (report.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  report.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showLevelEditor(context, report),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteReport(context, report),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLevelEditor(
    BuildContext context,
    QueueReport report,
  ) async {
    final queueRepository = context.read<FirestoreQueueRepository>();
    final selected = await showModalBottomSheet<QueueLevel>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final level in QueueLevel.values) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(level),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: level.color,
                      foregroundColor: level == QueueLevel.medium
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: Text(level.label),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    await queueRepository.updateQueueReportLevel(
      reportId: report.id,
      level: selected,
    );
  }

  Future<void> _deleteReport(BuildContext context, QueueReport report) async {
    final queueRepo = context.read<FirestoreQueueRepository>();
    final storageRepo = context.read<FirebaseStorageRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (report.storagePath != null) {
      await storageRepo.deleteFile(report.storagePath!);
    }
    await queueRepo.deleteQueueReport(report.id);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Queue report deleted')),
    );
  }
}
