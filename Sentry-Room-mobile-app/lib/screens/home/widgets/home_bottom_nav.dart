import 'package:flutter/material.dart';

import 'home_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.isAdmin,
    required this.onOpenCamera,
    required this.onOpenPeople,
    required this.onOpenEvents,
    required this.onOpenAnalytics,
    required this.onOpenSettings,
  });

  final bool isAdmin;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenPeople;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.grid_view_rounded),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Monitor',
      ),
      const NavigationDestination(
        icon: Icon(Icons.videocam_outlined),
        selectedIcon: Icon(Icons.videocam_rounded),
        label: 'Camera',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded),
        label: 'Analytics',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt_rounded),
          label: 'Access',
        ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded),
        label: 'Events',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_suggest_outlined),
        selectedIcon: Icon(Icons.settings_suggest_rounded),
        label: 'Settings',
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF080D18),
        border: Border(top: BorderSide(color: HomeColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: HomeColors.accent.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            onOpenCamera();
            return;
          }
          if (index == 2) {
            onOpenAnalytics();
            return;
          }
          if (isAdmin) {
            if (index == 3) {
              onOpenPeople();
            } else if (index == 4) {
              onOpenEvents();
            } else {
              onOpenSettings();
            }
            return;
          }
          if (index == 3) {
            onOpenEvents();
          } else {
            onOpenSettings();
          }
        },
      ),
    );
  }
}
