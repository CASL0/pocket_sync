import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.navFiles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sync_outlined),
            selectedIcon: const Icon(Icons.sync),
            label: l10n.navActivity,
          ),
        ],
      ),
    );
  }
}
