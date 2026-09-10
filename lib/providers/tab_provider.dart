import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation tab indices.
///
/// These must stay in the same order as MainShell's IndexedStack children —
/// that stack keeps every screen alive, so a screen that wants to refresh when
/// it becomes visible has to watch [tabIndexProvider] rather than rely on
/// initState, which only ever runs once.
class AppTab {
  const AppTab._();

  static const int home = 0;
  static const int calendar = 1;
  static const int condition = 2;
  static const int settings = 3;
}

/// Current bottom navigation tab index
final tabIndexProvider = StateProvider<int>((ref) => AppTab.home);
