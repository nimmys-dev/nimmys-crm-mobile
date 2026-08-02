/// Named string constants that more than one layer has to agree on.
///
/// Storage keys live here rather than next to their reader because a typo in a
/// key is silent — the write lands somewhere the read never looks.
class AppString {
  const AppString._();

  /// Keys for values that belong to the signed-in session and are held in
  /// [SecuredSharedPreferences], not in plain SharedPreferences.
  static const SessionKeys sessionKey = SessionKeys();
}

/// See [AppString.sessionKey].
class SessionKeys {
  const SessionKeys();

  /// The FCM registration token last handed to us by Firebase. The backend
  /// needs it to address this install, so it outlives the process.
  final String fcmToken = 'session.fcm_token';
}
