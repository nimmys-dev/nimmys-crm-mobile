import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/authentication/cubit/logout/logout_cubit.dart';
import 'package:nimmys_crm/features/authentication/model/logout_model.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';
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
      'employee_code': 'MGR-001',
      'name': 'Manager',
      'email': 'manager@nimmys.test',
      'role': 'manager',
      'status': 'active',
    },
  },
);

void main() {
  group('ProfileCubit', () {
    late MockProfileRepository repository;
    late ProfileCubit cubit;

    setUp(() {
      repository = MockProfileRepository();
      cubit = ProfileCubit(repository);
    });

    tearDown(() => cubit.close());

    test('emits LOADING then SUCCESS and exposes the user', () async {
      when(
        () => repository.getProfile(),
      ).thenAnswer((_) async => Success(_profile()));

      final Future<void> expectation = expectLater(
        cubit.stream.map((ProfileState state) => state.profileUIState?.status),
        emitsInOrder(<Status>[Status.LOADING, Status.SUCCESS]),
      );

      await cubit.getProfile();
      await expectation;

      expect(cubit.state.profileUIState?.data?.user?.name, 'Manager');
      expect(cubit.state.profileUIState?.data?.user?.initials, 'MA');
    });

    test('emits LOADING then ERROR and keeps the error type', () async {
      when(
        () => repository.getProfile(),
      ).thenAnswer((_) async => Error(UnauthenticatedError()));

      final Future<void> expectation = expectLater(
        cubit.stream.map((ProfileState state) => state.profileUIState?.status),
        emitsInOrder(<Status>[Status.LOADING, Status.ERROR]),
      );

      await cubit.getProfile();
      await expectation;

      expect(cubit.state.profileUIState?.errorType, isA<UnauthenticatedError>());
      expect(cubit.state.profileUIState?.data, isNull);
    });

    test('serves the cached profile until a forced refresh', () async {
      when(
        () => repository.getProfile(),
      ).thenAnswer((_) async => Success(_profile()));

      await cubit.getProfile();
      await cubit.getProfile();
      verify(() => repository.getProfile()).called(1);

      await cubit.getProfile(force: true);
      verify(() => repository.getProfile()).called(1);
    });

    test('reset clears the previous user so the next sign-in starts blank',
        () async {
      when(
        () => repository.getProfile(),
      ).thenAnswer((_) async => Success(_profile()));

      await cubit.getProfile();
      cubit.resetProfileState();

      expect(cubit.state.profileUIState?.data, isNull);
      expect(cubit.state.profileUIState?.status, Status.INITIAL);
    });
  });

  group('LogoutCubit', () {
    late MockAuthRepository repository;
    late LogoutCubit cubit;

    setUp(() {
      repository = MockAuthRepository();
      cubit = LogoutCubit(repository);
    });

    tearDown(() => cubit.close());

    test('emits LOADING then SUCCESS with the server message', () async {
      when(() => repository.logout()).thenAnswer(
        (_) async => Success(
          LogoutSuccessModel.fromJson(<String, dynamic>{
            'status': true,
            'status_code': 200,
            'message': 'Logout successful',
          }),
        ),
      );

      final Future<void> expectation = expectLater(
        cubit.stream.map((LogoutState state) => state.logoutUIState?.status),
        emitsInOrder(<Status>[Status.LOADING, Status.SUCCESS]),
      );

      await cubit.logout();
      await expectation;

      expect(cubit.state.logoutUIState?.data?.message, 'Logout successful');
    });

    test('emits ERROR when the call fails — the session is cleared regardless',
        () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => Error(InternetNetworkError()));

      final Future<void> expectation = expectLater(
        cubit.stream.map((LogoutState state) => state.logoutUIState?.status),
        emitsInOrder(<Status>[Status.LOADING, Status.ERROR]),
      );

      await cubit.logout();
      await expectation;

      expect(cubit.state.logoutUIState?.errorType, isA<InternetNetworkError>());
      verify(() => repository.logout()).called(1);
    });
  });
}
