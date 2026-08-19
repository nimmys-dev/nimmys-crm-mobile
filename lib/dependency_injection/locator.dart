import 'package:dio/dio.dart';
import 'package:nimmys_crm/data/network/api_service.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/features/authentication/cubit/login/login_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/logout/logout_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/authentication/repository/login_repository.dart';
import 'package:nimmys_crm/features/authentication/repository/user_information_repository.dart';
import 'package:nimmys_crm/features/authentication/service/auth_service.dart';
import 'package:nimmys_crm/features/authentication/service/login_service.dart';
import 'package:nimmys_crm/features/profile/cubit/company/company_profile_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/profile/repository/profile_repository.dart';
import 'package:nimmys_crm/features/profile/service/profile_service.dart';
import 'package:nimmys_crm/features/splash/splash_repository.dart';
import 'package:nimmys_crm/features/splash/splash_service.dart';
import 'package:nimmys_crm/features/splash/splash_view_mode.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/features/staff/repository/staff_repository.dart';
import 'package:nimmys_crm/features/staff/service/staff_service.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/repository/lead_repository.dart';
import 'package:nimmys_crm/features/leads/service/lead_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:nimmys_crm/service/push_notification/notification_service.dart';
import 'package:nimmys_crm/utils/custom_log.dart';

var locator = GetIt.instance;

void initLocator() {
  try {
    CustomLog.info(locator, "Registering services with GetIt...");

    // Shared Manager
    locator.registerLazySingleton(() => const FlutterSecureStorage());
    locator.registerLazySingleton(() => SecuredSharedPreferences(locator<FlutterSecureStorage>()));

    // Firebase
    //locator.registerLazySingleton(() => AnalyticsHelper());

    // Auth Services
    locator.registerLazySingleton<Dio>(() => Dio());
    locator.registerLazySingleton(() => ApiService(locator<Dio>(), locator<SecuredSharedPreferences>()));

    // Service
    locator.registerLazySingleton(() => SplashService(locator<UserInformationRepository>()));
    locator.registerLazySingleton(() => NotificationService(locator<SecuredSharedPreferences>()));
    locator.registerLazySingleton(() => LoginService(locator<ApiService>()));
    locator.registerLazySingleton(() => AuthService(locator<ApiService>()));
    locator.registerLazySingleton(() => ProfileService(locator<ApiService>()));
    locator.registerLazySingleton(() => StaffService(locator<ApiService>()));
    locator.registerLazySingleton(() => LeadService(locator<ApiService>()));

    // Repository
    locator.registerLazySingleton(() => UserInformationRepository(locator<SecuredSharedPreferences>()));
    locator.registerLazySingleton(() => SplashRepository(locator<SplashService>()));
    locator.registerLazySingleton(() => AuthRepository(locator<SecuredSharedPreferences>(), locator<NotificationService>(), locator<AuthService>()));
    locator.registerLazySingleton(() => LoginRepository(locator<LoginService>()));
    locator.registerLazySingleton(() => ProfileRepository(locator<ProfileService>()));
    locator.registerLazySingleton(() => StaffRepository(locator<StaffService>()));
    locator.registerLazySingleton(() => LeadRepository(locator<LeadService>()));

    // View Model
    locator.registerLazySingleton(() => SplashViewModel(locator<SplashRepository>(), locator<AuthRepository>()));

    // Cubit
    locator.registerLazySingleton(() => LoginCubit(locator<LoginRepository>(), locator<AuthRepository>()));
    locator.registerLazySingleton(() => LogoutCubit(locator<AuthRepository>()));
    locator.registerLazySingleton(() => SessionCubit(locator<UserInformationRepository>()));
    locator.registerLazySingleton(() => ProfileCubit(locator<ProfileRepository>()));
    locator.registerLazySingleton(() => StaffCubit(locator<StaffRepository>()));
    locator.registerLazySingleton(() => LeadsCubit(locator<LeadRepository>()));
    locator.registerLazySingleton(() => CompanyProfileCubit(locator<ProfileRepository>()));


    CustomLog.info(locator, "All instances registered.");
  } catch (e) {
    CustomLog.error(locator, "ERROR : All instances are not registered.", e);
  }

}
