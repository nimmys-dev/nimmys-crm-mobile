import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nimmys_crm/utils/custom_log.dart';

/// The app-icon badge count, persisted so it survives both a restart and the
/// isolate boundary.
///
/// Push notifications arrive on two different isolates: foreground messages on
/// the UI isolate, background/terminated ones on the fresh isolate Firebase
/// spins up for `firebaseMessagingBackgroundHandler`. An `int` field on
/// `NotificationService` is therefore counted twice over — the background
/// isolate gets its own zeroed copy of every static — and both copies are
/// thrown away when the process dies. That is why five notifications could
/// only ever move the badge to one.
///
/// `shared_preferences` is used rather than the app's secure storage because
/// this is a plain counter with nothing to protect, and because sign-out wipes
/// secure storage wholesale — the badge is cleared explicitly there instead.
class BadgeCounter {
  const BadgeCounter._();

  static const String _key = 'notification.badge.count';

  /// Serialises the read-modify-write below. Two pushes landing in the same
  /// isolate milliseconds apart would otherwise both read the same value and
  /// write the same increment, losing one of the two.
  static Future<void> _queue = Future<void>.value();

  /// Bumps the stored count by one and pushes it to the launcher.
  ///
  /// Returns the new count so callers can log or display it.
  static Future<int> increment() {
    return _serialise(() async {
      final SharedPreferences prefs = await _prefs();
      final int next = (prefs.getInt(_key) ?? 0) + 1;
      await prefs.setInt(_key, next);
      await _apply(next);
      CustomLog.debug(BadgeCounter, 'Badge count: $next');
      return next;
    });
  }

  /// The count as last persisted by either isolate.
  static Future<int> current() {
    return _serialise(() async {
      final SharedPreferences prefs = await _prefs();
      return prefs.getInt(_key) ?? 0;
    });
  }

  /// Re-asserts the persisted count over whatever the badge currently shows.
  ///
  /// Needed on resume: notifications that arrived while the app was away were
  /// counted in the background isolate, where awesome_notifications is not
  /// initialised, so its native counter has drifted below the real total and
  /// will publish that stale number the next time it draws anything.
  static Future<int> restore() {
    return _serialise(() async {
      final SharedPreferences prefs = await _prefs();
      final int count = prefs.getInt(_key) ?? 0;
      await _apply(count);
      return count;
    });
  }

  /// Resets to zero and removes the launcher badge.
  static Future<void> clear() {
    return _serialise(() async {
      final SharedPreferences prefs = await _prefs();
      await prefs.setInt(_key, 0);
      await _apply(0);
      CustomLog.debug(BadgeCounter, 'Badge count cleared');
    });
  }

  /// `getInstance` hands back an in-memory cache populated when the isolate
  /// first asked for it, so without the reload the UI isolate would keep
  /// incrementing from whatever it read at launch and silently overwrite every
  /// bump the background isolate made while the app sat in the recents list.
  static Future<SharedPreferences> _prefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  /// Pushes [count] to every system that draws the launcher badge.
  ///
  /// Both have to be written, and neither is redundant:
  ///
  /// * `awesome_notifications` keeps a *native* global badge counter and bumps
  ///   it by itself for any channel declared with `channelShowBadge: true`.
  ///   Leaving that unattended is what made the badge disagree with the real
  ///   count — it only ever saw the foreground notifications it drew, so it
  ///   kept resetting the badge to its own low tally. `setGlobalBadgeCounter`
  ///   overwrites that tally with ours instead of racing it. It is also the
  ///   only one of the two that reaches `applicationIconBadgeNumber` on iOS.
  /// * `app_badge_plus` covers launchers awesome_notifications does not, though
  ///   on Xiaomi/MIUI it is a no-op — its `MiUIBadge` bails out unless a
  ///   `Notification` has been handed to it, which nothing here does.
  ///
  /// Each is guarded separately so a plugin that is unavailable in the calling
  /// isolate — awesome_notifications is not initialised in the FCM background
  /// isolate — cannot stop the other from writing.
  static Future<void> _apply(int count) async {
    try {
      await AwesomeNotifications().setGlobalBadgeCounter(count);
    } catch (e) {
      CustomLog.error(BadgeCounter, 'Awesome badge update failed', e);
    }

    try {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count);
      } else {
        CustomLog.debug(
          BadgeCounter,
          'Launcher badge not supported by app_badge_plus on this device',
        );
      }
    } catch (e) {
      // Launchers that advertise support and then refuse the write must not
      // take down the notification that triggered this.
      CustomLog.error(BadgeCounter, 'Launcher badge update failed', e);
    }
  }

  static Future<T> _serialise<T>(Future<T> Function() action) {
    final Completer<T> result = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        result.complete(await action());
      } catch (e) {
        CustomLog.error(BadgeCounter, 'Badge counter error', e);
        result.completeError(e);
      }
    });
    return result.future;
  }
}
