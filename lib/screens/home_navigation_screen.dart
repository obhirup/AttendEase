import 'package:flutter/material.dart';
import 'attendance/daily_attendance_screen.dart';
import 'timetable/timetable_screen.dart';
import 'dashboard/combined_dashboard_screen.dart';
import 'settings/settings_screen.dart';
import '../theme/app_colors.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyAttendanceScreen(),
    TimetableScreen(),
    CombinedDashboardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: primary.withOpacity(0.18),
          onDestinationSelected: (idx) {
            setState(() => _currentIndex = idx);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle, color: primary),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: primary),
              label: 'Timetable',
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics, color: primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
