import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/condition/condition_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/widget_service.dart';
import 'services/notification_scheduler.dart';
import 'services/calendar_sync_service.dart';
import 'services/backup_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/health_sync_provider.dart';
import 'providers/tab_provider.dart';
import 'providers/theme_provider.dart';

class ChangeApp extends ConsumerWidget {
  const ChangeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    // Publish the palette before anything below builds — AppTheme's static
    // getters are what the screens read, not Theme.of(context).
    applyPalette(context, mode);

    return MaterialApp(
      title: 'Change',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      routes: AppRoutes.routes,
      home: const AppEntryPoint(),
    );
  }
}

/// Checks if this is the first launch and shows onboarding if needed
class AppEntryPoint extends ConsumerStatefulWidget {
  const AppEntryPoint({super.key});

  @override
  ConsumerState<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends ConsumerState<AppEntryPoint> {
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
      if (!completed) _offerRestore();
    } catch (_) {
      // SharedPreferences not available (e.g., web without setup)
      setState(() {
        _isFirstLaunch = false;
        _isLoading = false;
      });
    }
  }

  /// On a first launch, a backup in iCloud means this is a reinstall or a new
  /// phone: offer to bring everything back instead of starting from zero.
  Future<void> _offerRestore() async {
    final backup = BackupService.instance;
    if (!backup.isSupported) return;
    final snapshot = await backup.fetch();
    if (snapshot == null || snapshot.recordCount == 0 || !mounted) return;
    // Onboarding may have been finished while the backup was downloading.
    if (!_isFirstLaunch) return;

    final when = DateFormat('yyyy.M.d HH:mm').format(snapshot.createdAt);
    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('iCloud 백업이 있어요'),
        content: Text(
          '$when 백업\n'
          '근무 ${snapshot.count('shifts')}일 · 수면 ${snapshot.count('sleep_records')}건 · '
          '에너지 ${snapshot.count('energy_records')}건\n\n'
          '복원하면 설정까지 그대로 이어서 쓸 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('새로 시작'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (restore != true || !mounted) return;

    try {
      await backup.restore(snapshot);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      await ref.read(themeModeProvider.notifier).reload();
      if (mounted) setState(() => _isFirstLaunch = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원에 실패했어요. 설정에서 다시 시도할 수 있어요')),
        );
      }
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
  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    ConditionScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyDebugInitialTab();
    // Begin receiving shift edits and energy taps from the watch.
    ref.read(healthSyncProvider.notifier).listenToWatch();
    CalendarSyncService.instance.syncIfStale();
    BackupService.instance.backupIfStale();
  }

  /// Debug-only hook for capturing screenshots of a specific tab.
  ///
  /// There is no way to script a tap on the simulator, so set
  /// `flutter.debug_initial_tab` in the app's preferences and relaunch.
  /// Compiled out of release builds.
  Future<void> _applyDebugInitialTab() async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tab = prefs.getInt('debug_initial_tab');
      if (tab != null && tab >= 0 && tab <= AppTab.settings && mounted) {
        ref.read(tabIndexProvider.notifier).state = tab;
      }
    } catch (_) {}
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
      // Reschedule notifications: "today" may have rolled over while the app
      // was backgrounded, so slot→date mappings must be refreshed.
      NotificationScheduler.rescheduleForSchedule(schedule);
      // Pick up any sleep/health data recorded while the app was away.
      // autoSync() also drains the watch's pending energy records — this used
      // to have a second, subtly different copy of that import here, and
      // whichever ran first won because both cleared the same queue.
      ref.read(healthSyncProvider.notifier).autoSync();
      CalendarSyncService.instance.syncIfStale();
      BackupService.instance.backupIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: ref.watch(tabIndexProvider),
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
                _buildNavItem(AppTab.home, Icons.home_rounded, '홈',
                    ref.watch(tabIndexProvider)),
                _buildNavItem(AppTab.calendar, Icons.calendar_month_rounded,
                    '캘린더', ref.watch(tabIndexProvider)),
                _buildNavItem(AppTab.condition, Icons.monitor_heart_rounded,
                    '컨디션', ref.watch(tabIndexProvider)),
                _buildNavItem(AppTab.settings, Icons.settings_rounded, '설정',
                    ref.watch(tabIndexProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => ref.read(tabIndexProvider.notifier).state = index,
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
