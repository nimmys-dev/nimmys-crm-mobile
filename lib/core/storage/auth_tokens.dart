import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The credential pair plus the clock the refresh flow runs on.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
  }); 

  final String accessToken;

  /// Null for backends that issue a single long-lived token. The auth
  /// interceptor checks for null before attempting any refresh.
  final String? refreshToken;

  /// Absolute expiry in UTC, when the server tells us. Null means "unknown",
  /// which is treated as still valid — the 401 path is the fallback.
  final DateTime? expiresAt;

  final String tokenType;

  String get authorizationHeader => '$tokenType $accessToken';

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.isNotEmpty;

  /// True once the token is past its stated lifetime.
  bool isExpired({DateTime? now}) {
    final DateTime? expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    return !(now ?? DateTime.now().toUtc()).isBefore(expiry);
  }

  /// True shortly *before* expiry, so a refresh can happen ahead of a
  /// failure rather than after one.
  ///
  /// The [leeway] also absorbs clock skew between device and server, which is
  /// routinely tens of seconds on real handsets.
  bool needsRefresh({
    Duration leeway = const Duration(seconds: 60),
    DateTime? now,
  }) {
    final DateTime? expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    return !(now ?? DateTime.now().toUtc()).isBefore(expiry.subtract(leeway));
  }

  /// Builds tokens from a login or refresh response.
  ///
  /// Handles both conventions: an absolute `expires_at` timestamp, or the
  /// more common `expires_in` seconds, which is resolved against the local
  /// clock at the moment of parsing.
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final DateTime? expiresAt = switch (json['expires_at']) {
      final String value => DateTime.tryParse(value)?.toUtc(),
      _ => switch (json['expires_in']) {
        final int seconds => DateTime.now().toUtc().add(
          Duration(seconds: seconds),
        ),
        final String seconds when int.tryParse(seconds) != null => DateTime.now()
            .toUtc()
            .add(Duration(seconds: int.parse(seconds))),
        _ => null,
      },
    };

    return AuthTokens(
      accessToken: (json['access_token'] ?? json['token']) as String,
      refreshToken: (json['refresh_token'] ?? json['refreshToken']) as String?,
      expiresAt: expiresAt,
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt?.toIso8601String(),
    'token_type': tokenType,
  };

  String encode() => jsonEncode(toJson());

  static AuthTokens? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or from an older schema — treat as no session rather than
      // crashing on launch. The user re-authenticates and it self-heals.
      return null;
    }
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) => AuthTokens(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    tokenType: tokenType,
  );

  @override
  List<Object?> get props => <Object?>[
    accessToken,
    refreshToken,
    expiresAt,
    tokenType,
  ];

  /// Redacted on purpose — tokens must never reach a log line or crash report.
  @override
  String toString() =>
      'AuthTokens(type: $tokenType, expiresAt: $expiresAt, '
      'hasRefresh: $hasRefreshToken)';
}
