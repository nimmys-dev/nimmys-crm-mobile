import 'package:flutter_test/flutter_test.dart';
import 'package:nimmys_crm/features/authentication/model/logout_model.dart';
import 'package:nimmys_crm/features/profile/model/profile_model.dart';

/// Verbatim `GET /api/profile` body captured from crm.nimmysonline.com.
const Map<String, dynamic> _profileResponse = <String, dynamic>{
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
};

/// Verbatim `POST /api/logout` body.
const Map<String, dynamic> _logoutResponse = <String, dynamic>{
  'status': true,
  'status_code': 200,
  'message': 'Logout successful',
};

void main() {
  group('ProfileSuccessModel.fromJson', () {
    test('reads the live profile response', () {
      final ProfileSuccessModel model = ProfileSuccessModel.fromJson(
        _profileResponse,
      );

      expect(model.status, isTrue);
      expect(model.statusCode, 200);
      expect(model.message, 'Profile fetched successfully');
      expect(model.user, isNotNull);
      expect(model.user!.id, 2);
      expect(model.user!.employeeCode, 'MGR-001');
      expect(model.user!.name, 'Manager');
      expect(model.user!.email, 'manager@nimmys.test');
      expect(model.user!.role, 'manager');
      expect(model.user!.status, 'active');
      expect(model.user!.isActive, isTrue);
    });

    test('keeps the API nulls as nulls rather than throwing', () {
      final ProfileUser user = ProfileSuccessModel.fromJson(
        _profileResponse,
      ).user!;

      expect(user.shopId, isNull);
      expect(user.phone, isNull);
      expect(user.photo, isNull);
    });

    test('survives a missing user object', () {
      final ProfileSuccessModel model = ProfileSuccessModel.fromJson(
        <String, dynamic>{'status': false, 'status_code': 401},
      );

      expect(model.user, isNull);
      expect(model.status, isFalse);
    });

    test('round trips back to the API field names', () {
      final Map<String, dynamic> json = ProfileSuccessModel.fromJson(
        _profileResponse,
      ).toJson();

      expect(json['status_code'], 200);
      expect(json['user']['employee_code'], 'MGR-001');
      expect(json['user']['shop_id'], isNull);
      expect(ProfileSuccessModel.fromJson(json).user!.name, 'Manager');
    });

    test('parses ids sent as strings', () {
      final ProfileUser user = ProfileUser.fromJson(<String, dynamic>{
        'id': '7',
        'shop_id': '3',
        'name': 'Staff',
      });

      expect(user.id, 7);
      expect(user.shopId, 3);
    });
  });

  group('ProfileUser.initials', () {
    test('takes two letters from a single name', () {
      expect(ProfileUser(name: 'Manager').initials, 'MA');
    });

    test('takes one letter from each of the first two words', () {
      expect(ProfileUser(name: 'Abin Babu Thomas').initials, 'AB');
    });

    test('falls back to a placeholder rather than an empty circle', () {
      expect(ProfileUser(name: null).initials, '?');
      expect(ProfileUser(name: '   ').initials, '?');
    });
  });

  group('LogoutSuccessModel.fromJson', () {
    test('reads the live logout response', () {
      final LogoutSuccessModel model = LogoutSuccessModel.fromJson(
        _logoutResponse,
      );

      expect(model.status, isTrue);
      expect(model.statusCode, 200);
      expect(model.message, 'Logout successful');
      expect(model.toJson()['message'], 'Logout successful');
    });
  });
}
