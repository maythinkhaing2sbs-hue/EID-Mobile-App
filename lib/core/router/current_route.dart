import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Tracks the route currently on top of the navigator.
///
/// Used only by the desktop phone mockup, which sits *above* the navigator and
/// therefore cannot read anything a screen provides. Observing the navigator
/// keeps that dependency one-directional: no screen has to know the mockup
/// exists.
class CurrentRouteObserver extends NavigatorObserver {
  final ValueNotifier<String?> current = ValueNotifier<String?>(null);
  bool _disposed = false;

  void _set(Route<dynamic>? route) {
    if (route != null && route is! PageRoute) return;
    final name = route?.settings.name;
    if (_disposed || current.value == name) return;

    // The navigator pushes its initial route *during* the first build, and
    // listeners of this notifier live above the navigator. Notifying them
    // synchronously would mark an ancestor dirty mid-build, so the update is
    // deferred to the end of the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) current.value = name;
      });
    } else {
      current.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);

  void dispose() {
    _disposed = true;
    current.dispose();
  }
}
