import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import '../oldLib/app.dart';
import '../oldLib/core/di/service_locator.dart';
import '../oldLib/core/network/api_config.dart';
import '../oldLib/core/storage/token_storage.dart';
import '../oldLib/core/theme/theme_controller.dart';

/// Boots the real app with only the platform-backed pieces swapped out.
///
/// Doubles as the worked example of testing against the object graph:
/// [configureDependencies] takes an `overrides` hook, and anything registered
/// there wins over the production registration. Here that is
/// [InMemoryTokenStorage] — the secure store needs a Keychain the test
/// binding does not have — while everything else wires up exactly as it does
/// in release.
void main() {
  setUp(() async {
    await resetDependencies();
    await configureDependencies(
      config: ApiConfig.development,
      overrides: (GetIt sl) =>
          sl.registerLazySingleton<TokenStorage>(InMemoryTokenStorage.new),
    );
  });

  tearDown(resetDependencies);

  testWidgets('boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(NimmysCrmApp(themeController: ThemeController()));

    // A single pump rather than `pumpAndSettle`: the splash runs a timed
    // animation, and settling would wait it out for no added confidence.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
