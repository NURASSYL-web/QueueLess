import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/shared/models/feedback_entry.dart';
import 'package:queue/src/shared/repositories/firestore_feedback_repository.dart';

class FeedbackFormCard extends StatefulWidget {
  const FeedbackFormCard({super.key});

  @override
  State<FeedbackFormCard> createState() => _FeedbackFormCardState();
}

class _FeedbackFormCardState extends State<FeedbackFormCard> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthRepository>();
    final repo = context.read<FirestoreFeedbackRepository>();
    final user = auth.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await repo.submitFeedback(
        FeedbackEntry(
          id: '',
          userId: user.uid,
          email: user.email ?? 'unknown@email.com',
          rating: _rating,
          comment: _controller.text.trim(),
          createdAt: DateTime.now(),
        ),
      );

      _controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback saved for MVP validation')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tester Feedback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture quick validation from real users directly in Firestore.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _rating,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}/5'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _rating = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Experience rating'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What was useful or confusing?',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Saving...' : 'Submit feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
