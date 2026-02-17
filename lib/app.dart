import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/health/health_coach_screen.dart';
import 'screens/condition/condition_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/widget_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/energy_provider.dart';

class ChangeApp extends ConsumerWidget {
  const ChangeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Change',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: AppRoutes.routes,
      home: const AppEntryPoint(),
    );
  }
}

/// Checks if this is the first launch and shows onboarding if needed
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  static const String _onboardingCompleteKey = 'onboarding_complete';

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_onboardingCompleteKey) ?? false;
      setState(() {
        _isFirstLaunch = !completed;
        _isLoading = false;
      });
    } catch (_) {
      // SharedPreferences not available (e.g., web without setup)
      setState(() {
        _isFirstLaunch = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isFirstLaunch) {
      return OnboardingScreen(
        onComplete: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_onboardingCompleteKey, true);
          } catch (_) {}
          if (mounted) {
            setState(() => _isFirstLaunch = false);
          }
        },
      );
    }

    return const MainShell();
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    ConditionScreen(),
    HealthCoachScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final schedule = ref.read(scheduleProvider);
      WidgetService.instance.updateWidgetData(schedule);
      _importWatchEnergyRecords();
    }
  }

  Future<void> _importWatchEnergyRecords() async {
    final pending = await WidgetService.instance.readWatchEnergyRecords();
    if (pending.isEmpty) return;

    final energyNotifier = ref.read(energyProvider.notifier);
    final schedule = ref.read(scheduleProvider);

    for (final record in pending) {
      final level = record['energy_level'] as int;
      final timestamp = DateTime.parse(record['timestamp'] as String);
      final shiftType = schedule.getShiftTypeForDate(timestamp);

      await energyNotifier.addEnergyRecord(
        energyLevel: level,
        shiftType: shiftType.isEmpty ? null : shiftType,
        source: 'watch',
      );
    }

    await WidgetService.instance.clearWatchEnergyRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, '홈'),
                _buildNavItem(1, Icons.calendar_month_rounded, '캘린더'),
                _buildNavItem(2, Icons.monitor_heart_rounded, '컨디션'),
                _buildNavItem(3, Icons.favorite_rounded, '건강'),
                _buildNavItem(4, Icons.settings_rounded, '설정'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
