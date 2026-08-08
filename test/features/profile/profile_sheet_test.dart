import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/features/authentication/cubit/logout/logout_cubit.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';
import 'package:nimmys_crm/features/profile/profile_sheet.dart';
import 'package:nimmys_crm/features/profile/repository/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

ProfileSuccessModel _profile() => ProfileSuccessModel.fromJson(
  <String, dynamic>{
    'status': true,
    'status_code': 200,
    'message': 'Profile fetched successfully',
    'user': <String, dynamic>{
      'id': 2,
      'shop_id': null,
      'employee_code': 'MGR-001',
      'name': 'Manager',
      'email': 'manager@nimmys.test',
      'phone': null,
      'photo': null,
      'role': 'manager',
      'status': 'active',
    },
  },
);

void main() {
  late MockProfileRepository profileRepository;
  late MockAuthRepository authRepository;

  setUp(() {
    profileRepository = MockProfileRepository();
    authRepository = MockAuthRepository();
  });

  /// Pumps the sheet directly rather than through `showProfileSheet`, so the
  /// test drives the widget without a modal route in the way.
  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ProfileCubit>(
            create: (_) => ProfileCubit(profileRepository),
          ),
          BlocProvider<LogoutCubit>(create: (_) => LogoutCubit(authRepository)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: ProfileSheet())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the profile returned by the API', (
    WidgetTester tester,
  ) async {
    when(
      () => profileRepository.getProfile(),
    ).thenAnswer((_) async => Success(_profile()));

    await pumpSheet(tester);

    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('manager@nimmys.test'), findsOneWidget);
    expect(find.text('MGR-001'), findsOneWidget);
    expect(find.text('MANAGER'), findsOneWidget); // role tag
    expect(find.text('ACTIVE'), findsOneWidget); // status tag
    expect(find.text('LOGOUT'), findsOneWidget);
    // phone and shop_id are null in the response — both render as em dashes.
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('offers a retry when the profile call fails', (
    WidgetTester tester,
  ) async {
    when(
      () => profileRepository.getProfile(),
    ).thenAnswer((_) async => Error(InternetNetworkError()));

    await pumpSheet(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Manager'), findsNothing);

    when(
      () => profileRepository.getProfile(),
    ).thenAnswer((_) async => Success(_profile()));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Manager'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation before calling the API', (
    WidgetTester tester,
  ) async {
    when(
      () => profileRepository.getProfile(),
    ).thenAnswer((_) async => Success(_profile()));

    await pumpSheet(tester);
    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsNothing);
    verifyNever(() => authRepository.logout());
  });
}
