import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:nimmys_crm/features/leads/lead_details_screen.dart';
import 'package:nimmys_crm/features/leads/todays_follow_up_screen.dart';
import 'package:nimmys_crm/utils/app_string.dart';
// Prefixed because this class exposes its own `navigatorKey` and the app's
// global one has the same name — the prefix is what lets the field default to
// the key `MaterialApp.router` is actually using.
import 'package:nimmys_crm/utils/app_global_variables.dart' as app;
import 'package:nimmys_crm/utils/app_route.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/utils/custom_log.dart';
import 'badge_counter.dart';
import 'notification_helper.dart';
import 'notification_payload.dart';
import 'notification_session_manager.dart';
import 'notification_view.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService(SecuredSharedPreferences securedSharedPreferences) => _instance;

  NotificationService._internal();
  static String? deviceToken;

  // Dependencies
  late SecuredSharedPreferences _secureSharedPrefs;

  /// Defaults to the app's key rather than being `late`, so a tap that arrives
  /// before [init] has finished routes instead of throwing
  /// `LateInitializationError`. [init] still overwrites it with whatever the
  /// caller passes.
  static GlobalKey<NavigatorState> navigatorKey = app.navigatorKey;

  final NotificationView _notificationView = const NotificationView();
  final NotificationSessionManager _sessionManager =
      NotificationSessionManager();

  // Flutter Local Notifications (for alert-specific sounds)
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// The launcher badge lives in [BadgeCounter] rather than in a field here:
  /// the background isolate cannot see this object's state, so a field would
  /// only ever count the notifications that arrived while the app was open.
  Future<int> get badgeCount => BadgeCounter.current();

  /// Rebuilt whenever the count changes so in-app badges can follow the
  /// launcher badge. Refreshed on resume, since messages that arrive while the
  /// app is backgrounded are counted in the other isolate.
  static final ValueNotifier<int> unreadNotifications = ValueNotifier<int>(0);

  /// Whether the custom alert tones are bundled in `android/app/src/main/res/raw/`.
  ///
  /// They are not, in this project — the folder does not exist. That matters
  /// because `show()` does not fall back quietly: the Android plugin resolves
  /// the name with `getIdentifier(name, "raw", …)` and raises an
  /// `INVALID_SOUND` PlatformException when it comes back 0, so every critical
  /// alert would throw instead of ringing.
  ///
  /// Drop `sos_sound`, `spymode_sound`, `agora_call` and `powercut` (.mp3 or
  /// .wav, lowercase, no hyphens) into that folder and flip this to `true` —
  /// nothing else needs to change. Until then alerts use each channel's
  /// default tone at max importance, which still makes noise.
  static const bool _hasCustomAlertSounds = false;

  /// Null while [_hasCustomAlertSounds] is false, which the plugin reads as
  /// "use the channel default".
  static RawResourceAndroidNotificationSound? _rawSound(String name) =>
      _hasCustomAlertSounds ? RawResourceAndroidNotificationSound(name) : null;

  /// Same gate for iOS, where the file has to be in the app bundle instead.
  static String? _darwinSound(String name) =>
      _hasCustomAlertSounds ? name : null;

  // Alert-specific notification channels for Android
  static final AndroidNotificationChannel _highAlertsChannel =
      AndroidNotificationChannel(
        'high_alerts',
        'High Alert Notifications',
        description:
            'Used for important notifications like SOS, Power Cut, etc.',
        importance: Importance.max,
        playSound: true,
        sound: _rawSound('sos_sound'),
      );

  static final AndroidNotificationChannel _parkingAlertsChannel =
      AndroidNotificationChannel(
        'parking_alerts',
        'Parking Alert Notifications',
        description: 'Used for parking and spy mode notifications',
        importance: Importance.max,
        playSound: true,
        sound: _rawSound('spymode_sound'),
      );

  static final AndroidNotificationChannel _callAlertsChannel =
      AndroidNotificationChannel(
        'call_alerts',
        'Call Alert Notifications',
        description: 'Used for call and unauthorized parking notifications',
        importance: Importance.max,
        playSound: true,
        sound: _rawSound('agora_call'),
      );

  static final AndroidNotificationChannel _powerCutChannel =
      AndroidNotificationChannel(
        'powercut_alerts',
        'Power Cut Notifications',
        description: 'Used for power cut notifications',
        importance: Importance.max,
        playSound: true,
        sound: _rawSound('powercut'),
      );

  /// Initialize the notification service with all features
  Future<void> init(
    GlobalKey<NavigatorState> key,
    SecuredSharedPreferences secureSharedPrefs,
  ) async {
    navigatorKey = key;
    _secureSharedPrefs = secureSharedPrefs;

    // Initialize session manager
    _sessionManager.initialize(secureSharedPrefs);

    // Initialize all notification systems
    await _initializeFlutterLocalNotifications();
    await _initializeAwesomeNotifications();
    await _requestPermissions();
    await getFcmToken();

    // Set up message handlers
    _setupMessageHandlers();

    // Pick up anything the background isolate counted while the app was not
    // running, and keep doing so on every resume.
    await refreshBadgeCount();
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () => unawaited(refreshBadgeCount()),
    );

    // Check for pending critical alerts after initialization
    _checkForPendingCriticalAlerts();
  }

  /// Held so the singleton keeps one subscription across re-inits.
  AppLifecycleListener? _lifecycleListener;

  /// Check for any pending critical alerts that might have been missed
  void _checkForPendingCriticalAlerts() {
    // This can be used to check for any stored critical alerts
    // that might have been received while the app was terminated
    // and handle them appropriately
    CustomLog.debug(this, "Checking for pending critical alerts");
  }

  /// Initialize Flutter Local Notifications for alert-specific sounds
  Future<void> _initializeFlutterLocalNotifications() async {
    try {
      // Android: Create notification channels for alert-specific sounds
      if (Platform.isAndroid) {
        final androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidImplementation?.createNotificationChannel(
          _highAlertsChannel,
        );
        await androidImplementation?.createNotificationChannel(
          _parkingAlertsChannel,
        );
        await androidImplementation?.createNotificationChannel(
          _callAlertsChannel,
        );
        await androidImplementation?.createNotificationChannel(
          _powerCutChannel,
        );
      }

      // Initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // `settings:` is named as of flutter_local_notifications 20 — the
      // positional form the original project used no longer compiles.
      //
      // No background response handler is registered: it would run in its own
      // isolate with no navigator to push onto, and there are no action
      // buttons for it to service. Taps that launch the app are replayed into
      // the callback below once the engine is up.
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );
      CustomLog.debug(
        this,
        "Flutter Local Notifications initialized successfully",
      );
    } catch (e) {
      CustomLog.error(
        this,
        "Flutter Local Notifications initialization error",
        e,
      );
    }
  }

  /// Initialize Awesome Notifications for general notifications
  Future<void> _initializeAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        'resource://mipmap/ic_launcher',
        [
          NotificationChannel(
            channelGroupKey: 'General',
            channelKey: 'general_channel',
            channelName: 'General notifications',
            channelDescription:
                'All general notification for latest offers & coupon',
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            icon: 'resource://mipmap/ic_launcher',
            playSound: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'General',
            channelGroupName: 'General notifications',
          ),
        ],
        debug: false,
      );

      // Set up awesome notifications listeners
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onAwesomeNotificationReceived,
      );

      CustomLog.debug(this, "Awesome Notifications initialized successfully");
    } catch (e) {
      CustomLog.error(this, "Awesome Notifications initialization error", e);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {

      if (Platform.isIOS) {
        // iOS - Firebase permissions
        NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          sound: true,
          provisional: false,
          criticalAlert: false,
        );

        // Only request AwesomeNotifications if authorized/provisional
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
      }

      if (Platform.isAndroid) {
        // Android 13 (API 33) gates every notification behind the runtime
        // POST_NOTIFICATIONS permission — without it nothing this service
        // posts is ever drawn, silently. firebase_messaging declares the
        // permission in its manifest and raises the system prompt here.
        await FirebaseMessaging.instance.requestPermission();

        // Awesome Notifications keeps its own view of whether it may post.
        // Ask only if the system prompt above did not already grant it, so a
        // user who has allowed notifications is never prompted twice.
        if (!await AwesomeNotifications().isNotificationAllowed()) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
      }

      CustomLog.debug(this, "Notification permissions requested successfully");
    } catch (e) {
      CustomLog.error(this, "Notification permission request error", e);
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    try {
      // Foreground notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background/terminated notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Terminated state
      _handleTerminatedState();

      // FCM rotates the token on reinstall, restore and the occasional server
      // decision. Without this the backend keeps addressing a dead token.
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);

      // Note: Background handler is set up in main.dart to avoid conflicts
      // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      CustomLog.debug(this, "Message handlers setup successfully");
    } catch (e) {
      CustomLog.error(this, "Message handlers setup error", e);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final eventType = message.data['eventType'] ?? 'unknown';
      final mode = message.data['mode'] ?? 'normal';

      // Check if this is a critical alert that needs special sound
      if (_isCriticalAlert(eventType, mode)) {
        await _showCriticalAlert(message);
      } else {
        // Use awesome notifications for general notifications
        await _notificationView.display(
          message: message,
          payload: await _notificationPayload(message),
        );
      }

      // Deliberately after the notification is drawn, not before. The channel
      // is declared `channelShowBadge: true`, so awesome_notifications bumps
      // its own global counter as a side effect of `display` above and writes
      // that number to the launcher. Counting first meant that write always
      // landed last and clobbered the real total.
      await _incrementBadgeCount();
    } catch (e) {
      CustomLog.error(this, "Foreground message handling error", e);
    }
  }

  /// Handle background messages
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      NotificationPayload payload = NotificationPayload.fromJson(message.data);

      // Check if this is a critical alert that needs special handling
      final eventType = payload.eventType ?? 'unknown';
      final mode = payload.mode ?? 'normal';

      if (_isCriticalAlert(eventType, mode)) {
        // For background state, we can show a local notification with custom sound
        // but we can't show a dialog since the app is not in foreground
        await _showCriticalAlert(message);
      }

      _handleNotificationClick(payload, "Background state");
    } catch (e) {
      CustomLog.error(this, "Background message handling error", e);
    }
  }

  /// Handle terminated state
  Future<void> _handleTerminatedState() async {
    try {
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          NotificationPayload payload = NotificationPayload.fromJson(
            message.data,
          );

          // Check if this is a critical alert that needs dialog
          final eventType = payload.eventType ?? 'unknown';
          final mode = payload.mode ?? 'normal';

          if (_isCriticalAlert(eventType, mode)) {
            // Show critical alert dialog for terminated state
            _showCriticalAlertForTerminatedState(message, payload);
          } else {
            // Handle normal navigation
            _handleNotificationClick(payload, "Terminated state");
          }
        }
      });
    } catch (e) {
      CustomLog.error(this, "Terminated state handling error", e);
    }
  }

  /// Background message handler (static method required by Firebase)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // This isolate runs nothing but this handler, so the plugin channels
    // BadgeCounter needs are not wired up until the binding is initialised.
    WidgetsFlutterBinding.ensureInitialized();

    try {
      CustomLog.debug(
        NotificationService,
        "Background notification: ${message.toMap()}",
      );

      // Bump the shared counter rather than pinning the badge to 1 — this
      // isolate has no access to the UI isolate's tally, so the stored value is
      // the only thing the two can agree on.
      await BadgeCounter.increment();

      // Handle payload
      NotificationPayload payload = NotificationPayload.fromJson(message.data);

      // Check if this is a critical alert
      final eventType = payload.eventType ?? 'unknown';
      final mode = payload.mode ?? 'normal';

      // Store critical alert information for when app opens
      if (_isCriticalAlertStatic(eventType, mode)) {
        // Store the critical alert data for when app opens
        // This will be handled in _handleTerminatedState
        CustomLog.debug(
          NotificationService,
          "Critical alert received in background: $eventType, $mode",
        );
      }

      if (payload.route != null) {
        // Store route for when app opens
        // You can implement route storage logic here
      }
    } catch (e) {
      CustomLog.error(NotificationService, "Background handler error", e);
    }
  }

  /// Awesome notifications action received handler
  @pragma("vm:entry-point")
  static Future<void> _onAwesomeNotificationReceived(
    ReceivedAction receivedAction,
  ) async {
    try {
      NotificationPayload payload = NotificationPayload.fromJson(
        receivedAction.payload ?? {},
      );
      CustomLog.debug(
        NotificationService,
        "Awesome notification clicked: $payload",
      );

      if (payload.route != null) {
        _notificationRouting(payload);
      }
    } catch (e) {
      CustomLog.error(
        NotificationService,
        "Awesome notification action error",
        e,
      );
    }
  }

  /// Tap handler for the local notifications raised by [_showCriticalAlert].
  ///
  /// Awesome Notifications and Flutter Local Notifications each own the taps on
  /// the notifications they posted, so both have to land on the same routing.
  @pragma("vm:entry-point")
  static void _onLocalNotificationTapped(NotificationResponse response) {
    final String? raw = response.payload;
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Map<String, dynamic> data =
          json.decode(raw) as Map<String, dynamic>;
      final NotificationPayload payload = NotificationPayload.fromJson(data);
      CustomLog.debug(NotificationService, "Local alert clicked: $payload");
      _notificationRouting(payload);
    } catch (e) {
      CustomLog.error(
        NotificationService,
        "Local notification action error",
        e,
      );
    }
  }

  /// Show critical alert with custom sound and popup
  Future<void> _showCriticalAlert(RemoteMessage message) async {
    final data = message.data;
    final eventType = data['eventType'] ?? 'unknown';
    final mode = data['mode'] ?? 'normal';
    final deviceName =
        data['vehicleName'] ?? data['deviceName'] ?? 'Unknown Device';

    final notification = message.notification;
    final title = '🚨 Alert ${notification?.title ?? ''}';
    final body = notification?.body ?? 'You have a new notification';

    // Save device name and notification type based on event type
    await _saveDeviceNameAndType(eventType, deviceName);

    // Event-based configuration
    final eventConfig = _getEventConfig(eventType, mode);
    final channelId = eventConfig['channelId'] ?? _highAlertsChannel.id;
    final channelName = eventConfig['channelName'] ?? _highAlertsChannel.name;
    final androidSound = eventConfig['sound'] ?? _highAlertsChannel.sound;
    final iosSound = eventConfig['iosSound'];

    // Show local notification with custom sound. Every argument is named as of
    // flutter_local_notifications 20; `payload` is what makes the tap
    // routable, since the plugin hands back nothing else.
    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: eventConfig['description'],
          importance: Importance.max,
          priority: Priority.high,
          sound: androidSound,
        ),
        iOS: DarwinNotificationDetails(sound: iosSound),
      ),
      payload: json.encode(data),
    );

    // Show popup dialog if app is in foreground
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 45,
                        vertical: 6,
                      ),
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  /// Show critical alert dialog for terminated state
  Future<void> _showCriticalAlertForTerminatedState(
    RemoteMessage message,
    NotificationPayload payload,
  ) async {
    try {
      // Wait for app to be fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      final notification = message.notification;
      final eventType = payload.eventType ?? 'unknown';
      final deviceName = await _getDeviceNameForEvent(eventType);

      final title = '🚨 Alert ${notification?.title ?? ''}';
      final body = _getDeviceSpecificMessage(
        eventType,
        deviceName,
        notification?.body ?? 'You have a new notification',
      );

      // Try to show popup dialog for terminated state with retry mechanism
      bool dialogShown = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!dialogShown && retryCount < maxRetries) {
        if (navigatorKey.currentContext != null) {
          dialogShown = true;
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              backgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'DISMISS',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Handle navigation after dialog dismissal
                              if (payload.route != null) {
                                _handleNotificationClick(
                                  payload,
                                  "Terminated state - after dialog",
                                );
                              }
                            },
                            child: const Text(
                              'VIEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          retryCount++;
          if (retryCount < maxRetries) {
            CustomLog.debug(
              this,
              "Context not available, retrying... (attempt $retryCount)",
            );
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      // If dialog couldn't be shown after retries, handle navigation directly
      if (!dialogShown) {
        CustomLog.debug(
          this,
          "Could not show dialog after $maxRetries attempts, handling navigation directly",
        );
        _handleNotificationClick(
          payload,
          "Terminated state - no context after retries",
        );
      }
    } catch (e) {
      CustomLog.error(this, "Terminated state critical alert error", e);
      // Fallback to normal navigation
      _handleNotificationClick(payload, "Terminated state - fallback");
    }
  }

  /// Check if notification is a critical alert
  bool _isCriticalAlert(String eventType, String mode) {
    const criticalEvents = [
      'sos',
      'powercut',
      'power_cut',
      'unauthorized_parking',
      'unauthorised_parking',
      'parking',
      'tow',
      'commandresult', // Fixed to lowercase to match toLowerCase() behavior
    ];

    const criticalModes = ['owl', 'parking', 'alarm'];

    return criticalEvents.contains(eventType.toLowerCase()) ||
        criticalModes.contains(mode.toLowerCase());
  }

  /// Static version of critical alert check for background handler
  static bool _isCriticalAlertStatic(String eventType, String mode) {
    const criticalEvents = [
      'sos',
      'powercut',
      'power_cut',
      'unauthorized_parking',
      'unauthorised_parking',
      'parking',
      'tow',
      'commandresult', // Fixed to lowercase to match toLowerCase() behavior
    ];

    const criticalModes = ['owl', 'parking', 'alarm'];

    return criticalEvents.contains(eventType.toLowerCase()) ||
        criticalModes.contains(mode.toLowerCase());
  }

  /// Get event-specific configuration
  Map<String, dynamic> _getEventConfig(String eventType, String mode) {
    switch (eventType.toLowerCase()) {
      case 'sos':
        return {
          'channelId': _highAlertsChannel.id,
          'channelName': _highAlertsChannel.name,
          'description': 'SOS emergency alerts',
          'sound': _rawSound('sos_sound'),
          'iosSound': _darwinSound('sos_sound.aiff'),
        };

      case 'powercut':
      case 'power_cut':
        return {
          'channelId': _powerCutChannel.id,
          'channelName': _powerCutChannel.name,
          'description': 'Power cut alerts',
          'sound': _rawSound('powercut'),
          'iosSound': _darwinSound('powercut.aiff'),
        };

      case 'unauthorized_parking':
      case 'unauthorised_parking':
        return {
          'channelId': _callAlertsChannel.id,
          'channelName': _callAlertsChannel.name,
          'description': 'Unauthorized parking calls',
          'sound': _rawSound('agora_call'),
          'iosSound': _darwinSound('agora_call.aiff'),
        };

      case 'parking':
      case 'tow':
        return {
          'channelId': _parkingAlertsChannel.id,
          'channelName': _parkingAlertsChannel.name,
          'description': 'Parking and tow alerts',
          'sound': _rawSound('spymode_sound'),
          'iosSound': _darwinSound('spymode_sound.aiff'),
        };

      case 'commandresult':
        return {
          'channelId': _highAlertsChannel.id,
          'channelName': _highAlertsChannel.name,
          'description': 'Command result alerts',
          'sound': _rawSound('sos_sound'),
          'iosSound': _darwinSound('sos_sound.aiff'),
        };

      case 'gps_disconnected':
      case 'engine_on':
      default:
        // Check mode for special cases
        if (mode.toLowerCase() == 'owl' ||
            mode.toLowerCase() == 'parking' ||
            mode.toLowerCase() == 'alarm') {
          return {
            'channelId': _parkingAlertsChannel.id,
            'channelName': _parkingAlertsChannel.name,
            'description': 'Spy mode alerts',
            'sound': _rawSound('spymode_sound'),
            'iosSound': _darwinSound('spymode_sound.aiff'),
          };
        }

        // Default case
        return {
          'channelId': _highAlertsChannel.id,
          'channelName': _highAlertsChannel.name,
          'description': 'General alerts',
          'sound': _rawSound('sos_sound'),
          'iosSound': _darwinSound('sos_sound.aiff'),
        };
    }
  }

  /// Handle notification click
  void _handleNotificationClick(
    NotificationPayload payload,
    String consolePrint,
  ) {
    CustomLog.debug(this, "$consolePrint : $payload");
    if (payload.route != null) {

      if (payload.route != null) {
        _notificationRouting(payload);

      }
    }
  }

  /// Convert notification payload
  Future<Map<String, String?>> _notificationPayload(
    RemoteMessage message,
  ) async {
    Map<String, String> valueMap = {};
    try {
      String raw = message.data.toString();
      String jsonString = NotificationHelper.convertToJsonStringQuotes(
        raw: raw,
      );
      final Map<String, dynamic> result = json.decode(jsonString);
      valueMap = result.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      CustomLog.error(this, "Payload conversion error", e);
    }
    return valueMap;
  }

  /// Get FCM Token
  Future<void> getFcmToken() async {
    try {
      // Don't re-initialize Firebase, just get the token
      await _saveFcmToken(await FirebaseMessaging.instance.getToken());
    } catch (e) {
      CustomLog.error(this, "Get FCM token error", e);
    }
  }

  /// Persist a token, whether it came from [getFcmToken] or a later refresh.
  Future<void> _saveFcmToken(String? token) async {
    final String trimmed = token?.trim() ?? '';
    if (trimmed.isEmpty) {
      CustomLog.debug(this, "FCM Token is null or empty");
      return;
    }
    try {
      await FirebaseMessaging.instance.subscribeToTopic('global');
      CustomLog.debug(this, "FCM Token: $trimmed");
      await _secureSharedPrefs.saveKey(AppString.sessionKey.fcmToken, trimmed);
      deviceToken = await _secureSharedPrefs.get(AppString.sessionKey.fcmToken);
    } catch (e) {
      CustomLog.error(this, "Save FCM token error", e);
    }
  }

  /// Clear FCM Token
  Future<void> clearFcmToken() async {
    try {
      // await FirebaseMessaging.instance.deleteToken();
      CustomLog.debug(this, "FCM token cleared successfully");
    } catch (e) {
      CustomLog.error(this, "Failed to clear FCM token", e);
    }
  }

  /// Increment badge count
  Future<void> _incrementBadgeCount() async {
    unreadNotifications.value = await BadgeCounter.increment();
  }

  /// Re-reads the persisted count into [unreadNotifications].
  ///
  /// Call after a resume: everything that arrived while the app was in the
  /// background was counted by the other isolate, so this isolate's notifier is
  /// stale until it reloads.
  Future<void> refreshBadgeCount() async {
    unreadNotifications.value = await BadgeCounter.restore();
  }

  /// Clear badge count
  Future<void> clearBadgeCount() async {
    await BadgeCounter.clear();
    unreadNotifications.value = 0;
  }

  /// Save device name and notification type based on event type
  Future<void> _saveDeviceNameAndType(
    String eventType,
    String deviceName,
  ) async {
    // Save last notification device name
    _sessionManager.saveLastNotificationDeviceName(deviceName);

    // Save device name based on event type
    switch (eventType.toLowerCase()) {
      case 'sos':
        _sessionManager.saveSOSDeviceName(deviceName);
        _sessionManager.setNewNotificationType('SOS');
        break;
      case 'powercut':
      case 'power_cut':
        _sessionManager.savePowerCutDeviceName(deviceName);
        _sessionManager.setNewNotificationType('PowerCut');
        break;
      case 'unauthorized_parking':
      case 'unauthorised_parking':
      case 'parking':
      case 'tow':
        _sessionManager.saveSpyModeDeviceName(deviceName);
        _sessionManager.setNewNotificationType('SpyMode');
        break;
      case 'commandresult':
        _sessionManager.setNewNotificationType('CommandResult');
        break;
      default:
        _sessionManager.setNewNotificationType(eventType);
        break;
    }
  }

  /// Get device name for specific event type
  Future<String> _getDeviceNameForEvent(String eventType) async {
    switch (eventType.toLowerCase()) {
      case 'sos':
        return await _sessionManager.getSOSDeviceName();
      case 'powercut':
      case 'power_cut':
        return await _sessionManager.getPowerCutDeviceName();
      case 'unauthorized_parking':
      case 'unauthorised_parking':
      case 'parking':
      case 'tow':
        return await _sessionManager.getSpyModeDeviceName();
      default:
        return await _sessionManager.getLastNotificationDeviceName();
    }
  }

  /// Get device-specific message based on event type
  String _getDeviceSpecificMessage(
    String eventType,
    String deviceName,
    String defaultMessage,
  ) {
    switch (eventType.toLowerCase()) {
      case 'sos':
        return deviceName.isNotEmpty
            ? "SOS Alert from $deviceName - Emergency situation detected!"
            : "SOS Alert - Emergency situation detected!";
      case 'powercut':
      case 'power_cut':
        return deviceName.isNotEmpty
            ? "Power cut detected for $deviceName - Device disconnected!"
            : "Power cut detected - Device disconnected!";
      case 'unauthorized_parking':
      case 'unauthorised_parking':
        return deviceName.isNotEmpty
            ? "Unauthorized parking detected for $deviceName!"
            : "Unauthorized parking detected!";
      case 'parking':
      case 'tow':
        return deviceName.isNotEmpty
            ? "Parking/Tow alert for $deviceName!"
            : "Parking/Tow alert detected!";
      case 'commandresult':
        return deviceName.isNotEmpty
            ? "Command result received for $deviceName"
            : "Command result received";
      default:
        return defaultMessage;
    }

  }


  /// Turns the `route` field of a payload into a push.
  ///
  /// The screens the original project routed to (`VpLoadDetailsScreen`,
  /// `DriverLoadsLocationDetailsScreen`) belong to its load-tracking domain and
  /// have no counterpart here, so the table below names this app's screens
  /// instead. Whatever the backend sends as `route` has to match one of these
  /// strings; anything else is logged and ignored rather than crashing.
  ///
  /// Note that `LeadDetailsScreen` currently takes no id — it renders fixed
  /// sample data — so `notification.loadSeriesId` is carried but not yet used.
  static void _notificationRouting(NotificationPayload notification) {
    // The key, not `currentContext`: on a cold start the navigator exists a
    // frame before any route below it does, and pushing through the state
    // avoids reaching for a context that has not been mounted yet.
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) {
      CustomLog.error(
        NotificationService,
        "No navigator yet — dropped route ${notification.route}",
      );
      return;
    }

    switch ((notification.route ?? "").trim()) {
      case "/leadDetailsScreen":
        navigator.push(commonRoute(const LeadDetailsScreen()));
        break;
      // "/leadListScreen" has no destination yet: the bloc-wired list screen
      // was not part of the UI migration. It falls through to the log below.
      case "/todaysFollowUpScreen":
        navigator.push(commonRoute(const TodaysFollowUpScreen()));
        break;
      default:
        CustomLog.debug(
          NotificationService,
          "No screen mapped to route \"${notification.route}\"",
        );
    }
  }
}
