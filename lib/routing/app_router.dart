import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/core/scaffold_with_nav_bar.dart';
import 'package:pocket_sync/ui/features/file_detail/views/file_detail_view.dart';
import 'package:pocket_sync/ui/features/file_list/views/file_list_view.dart';
import 'package:pocket_sync/ui/features/settings/views/settings_view.dart';
import 'package:pocket_sync/ui/features/sync_activity/views/sync_activity_view.dart';

final appRouter = GoRouter(
  initialLocation: '/files',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/files',
              builder: (context, state) => const FileListView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => FileDetailView(
                    fileId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (context, state) => const SyncActivityView(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsView(),
    ),
  ],
  errorBuilder: (context, state) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.errorTitle)),
      body: Center(
        child: Text(l10n.errorPageNotFound(state.uri.toString())),
      ),
    );
  },
);
