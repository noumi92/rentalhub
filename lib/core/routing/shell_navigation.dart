import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pushes [location] safely even when called from a top-level route that sits
/// above a [StatefulShellRoute] (for example `/customer/notifications` pushed
/// on top of `/customer/support` above the customer shell).
///
/// In `go_router` 18.x, `RouteMatchList._cloneBranchAndInsertImperativeMatch`
/// scopes duplicate keys only for `ShellRoute`, not `StatefulShellRoute`. If a
/// top-level route pushes a route that belongs to a `StatefulShellRoute`
/// already present lower in the root `Navigator` stack, `go_router` appends a
/// second `ShellRouteMatch` with the exact same `_ShellRoutePageKey`, tripping
/// `NavigatorState._debugCheckDuplicatedPageKeys` (`!keyReservation.contains(key)`).
///
/// When a shell is already below the current top-level route and [location]
/// resolves inside a shell, this helper pops the top-level overlays back to
/// the shell before pushing [location] into the shell's branch navigator.
Future<T?> safePush<T extends Object?>(
  BuildContext context,
  String location, {
  Object? extra,
}) {
  final router = GoRouter.of(context);
  final matches = router.routerDelegate.currentConfiguration.matches;
  final hasShellBelow = matches.length > 1 &&
      matches.any((m) => m is ShellRouteMatch) &&
      matches.last is! ShellRouteMatch;

  if (hasShellBelow) {
    final target = router.configuration.findMatch(Uri.parse(location));
    final targetUsesShell = target.matches.any((m) => m is ShellRouteMatch);
    if (targetUsesShell) {
      while (router.canPop() &&
          router.routerDelegate.currentConfiguration.matches.last
              is! ShellRouteMatch) {
        router.pop();
      }
    }
  }

  return router.push<T>(location, extra: extra);
}
