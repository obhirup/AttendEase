import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/settings_provider.dart';
import 'providers/timetable_provider.dart';
import 'providers/attendance_provider.dart';
import 'theme/claude_theme.dart';
import 'screens/home_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  final settingsProvider = SettingsProvider(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(
          create: (_) => TimetableProvider(
            storageService,
            initialActiveId: settingsProvider.activeTimetableId,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ClaudeTheme.light(settings.activeColor),
      darkTheme: ClaudeTheme.dark(settings.activeColor),
      themeMode: settings.themeMode,
      home: const HomeNavigationScreen(),
    );
  }
}
