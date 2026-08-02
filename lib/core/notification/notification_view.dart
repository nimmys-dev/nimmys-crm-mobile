import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/custom_log.dart';

/// Draws an ordinary (non-critical) push.
///
/// Only the foreground path needs this. Android and iOS both suppress the
/// system tray while the app is in front, so a message that arrives then has to
/// be re-posted by hand or the user never sees it. Background and terminated
/// messages are drawn by the OS from the `notification` block and never reach
/// this class.
class NotificationView {
  const NotificationView();

  /// Must match the channel registered in `NotificationService`.
  static const String channelKey = 'general_channel';

  Future<void> display({
    required RemoteMessage message,
    required Map<String, String?> payload,
  }) async {
    try {
      final RemoteNotification? notification = message.notification;

      // A data-only message has no `notification` block; fall back to the
      // payload, which is where the server puts the copy in that case.
      final String title =
          notification?.title ?? payload['title'] ?? 'NIMMYS CRM';
      final String body =
          notification?.body ?? payload['body'] ?? 'You have a new notification';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          // Wraps every ~100 seconds, which is far longer than a notification
          // stays on screen — collisions replace a notification the user has
          // already dealt with.
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          // Carried through to `onActionReceivedMethod`, which is the only
          // place the tap can be turned back into a route.
          payload: payload,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
        ),
      );
    } catch (e, stackTrace) {
      CustomLog.error(this, 'Failed to display notification', e, stackTrace);
    }
  }
}
