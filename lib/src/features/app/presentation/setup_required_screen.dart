import 'package:flutter/material.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/core/services/bootstrap_service.dart';

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(AppConstants.appName, style: textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'QueueLess is ready for real Firebase data, but it still needs your project credentials.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(message, style: textTheme.bodyMedium),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                ),
                child: SelectableText(
                  BootstrapService.buildRunCommand(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Also add the same Google Maps key to AndroidManifest and AppDelegate/Info.plist for native map tiles.',
                style: textTheme.bodySmall,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
