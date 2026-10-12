import 'package:flutter/material.dart';

import 'core/services/services.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/shell_page.dart';

class TaskXApp extends StatelessWidget {
  const TaskXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Task X',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: const ShellPage(),
        );
      },
    );
  }
}
