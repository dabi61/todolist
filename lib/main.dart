import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'data/models/label.dart';
import 'data/models/task.dart';
import 'data/models/project.dart';

Future<Isar> _initializeDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open([TaskSchema, ProjectSchema, LabelSchema], directory: dir.path);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await _initializeDatabase();

  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWith((ref) => isar)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'My Tasks',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5F3DC4),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5F3DC4),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
