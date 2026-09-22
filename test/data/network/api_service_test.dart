import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/service/hasInternet/has_internet_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ApiService apiService;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'status': true},
            ),
          );
        },
      ),
    );
    apiService = ApiService(dio, SecuredSharedPreferences(preferences));
  });

  test(
    'does not reject a CRM request because a stale connectivity flag is false',
    () async {
      // This was the old pre-flight gate. It starts false at launch and could
      // remain false when the unrelated dart.dev probe failed.
      HasInternetConnection.isInternet = false;

      final result = await apiService.get('https://crm.example.test/api/leads');

      expect(result, isA<Success<dynamic>>());
    },
  );
}
