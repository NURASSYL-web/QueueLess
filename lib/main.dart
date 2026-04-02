import 'package:flutter/material.dart';
import 'package:queue/src/core/services/bootstrap_service.dart';
import 'package:queue/src/features/app/presentation/queueless_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapState = await BootstrapService.initialize();
  runApp(QueueLessApp(bootstrapState: bootstrapState));
}
