import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/leads/data/datasources/lead_remote_data_source.dart';
import '../../features/leads/data/repositories/lead_repository_impl.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/leads/presentation/bloc/lead_form_bloc.dart';
import '../../features/leads/presentation/bloc/lead_list_bloc.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/dio_api_client.dart';
import '../network/network_info.dart';
import '../network/response_envelope.dart';
import '../session/session_manager.dart';
import '../storage/token_storage.dart';

/// The app's service locator.
///
/// `sl` is short for "service locator" and is only ever referenced at
/// composition roots — `main`, a `BlocProvider`, a route builder. Classes
/// themselves take their dependencies through constructors, which is what
/// keeps them testable: nothing below this file knows GetIt exists.
final GetIt sl = GetIt.instance;

/// Wires the object graph. Call once, before `runApp`.
///
/// [overrides] lets a test or a screenshot harness swap in fakes before the
/// real registrations run — register a stub `ApiClient` there and the whole
/// app runs against it with no other change.
Future<void> configureDependencies({
  ApiConfig? config,
  void Function(GetIt sl)? overrides,
}) async {
  overrides?.call(sl);

  _registerCore(config ?? _configForBuild());
  _registerAuth();
  _registerLeads();

  // Load any persisted tokens before the first frame, so the app opens on the
  // right screen instead of flashing login at an already-signed-in user.
  await sl<SessionManager>().restore();
}

/// Resets everything. Used between tests; harmless in production.
Future<void> resetDependencies() async {
  if (sl.isRegistered<SessionManager>()) {
    await sl<SessionManager>().dispose();
  }
  await sl.reset();
}

// ------------------------------------------------------------------- Core

void _registerCore(ApiConfig config) {
  _eager<ApiConfig>(() => config);
  _lazy<Connectivity>(Connectivity.new);
  _lazy<NetworkInfo>(() => ConnectivityNetworkInfo(sl<Connectivity>()));
  _lazy<TokenStorage>(SecureTokenStorage.standard);
  // Eager, not lazy: the interceptor and the session listener both need the
  // *same* instance from the first moment, and restore() runs against it.
  _eager<SessionManager>(() => SessionManager(sl<TokenStorage>()));
  // Change this one line to match a different backend's response shape.
  _lazy<ResponseEnvelope>(WrappedEnvelope.new);
  _lazy<ApiClient>(
    () => DioApiClient.create(
      config: sl<ApiConfig>(),
      session: sl<SessionManager>(),
      envelope: sl<ResponseEnvelope>(),
    ),
  );
}

// Each registration is skipped if that type is already present, which is what
// makes `overrides` work at the granularity of a single dependency: a test
// registers an in-memory TokenStorage and everything else still wires up as
// normal. An all-or-nothing guard would force a test to rebuild the whole
// graph to replace one leaf.
void _lazy<T extends Object>(T Function() create) {
  if (!sl.isRegistered<T>()) {
    sl.registerLazySingleton<T>(create);
  }
}

void _eager<T extends Object>(T Function() create) {
  if (!sl.isRegistered<T>()) {
    sl.registerSingleton<T>(create());
  }
}

void _factory<T extends Object>(T Function() create) {
  if (!sl.isRegistered<T>()) {
    sl.registerFactory<T>(create);
  }
}

// ------------------------------------------------------------------- Auth

void _registerAuth() {
  _lazy<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl<ApiClient>()));
  _lazy<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      session: sl<SessionManager>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  // Blocs are factories, never singletons: each screen gets a fresh one, and
  // a bloc that outlived its screen would emit into a dead tree.
  _factory<LoginBloc>(() => LoginBloc(sl<AuthRepository>()));
}

// ------------------------------------------------------------------ Leads

void _registerLeads() {
  _lazy<LeadRemoteDataSource>(() => LeadRemoteDataSourceImpl(sl<ApiClient>()));
  _lazy<LeadRepository>(
    () => LeadRepositoryImpl(
      remote: sl<LeadRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  _factory<LeadListBloc>(() => LeadListBloc(sl<LeadRepository>()));

  // Parameterised factory: the edit screen passes the id it is editing, and a
  // null id means "create".
  if (!sl.isRegistered<LeadFormBloc>()) {
    sl.registerFactoryParam<LeadFormBloc, String?, void>(
      (String? leadId, _) => LeadFormBloc(sl<LeadRepository>(), leadId: leadId),
    );
  }
}

/// Picks the environment.
///
/// `--dart-define=FLAVOR=staging` wins when set; otherwise the build mode
/// decides, so a release build can never accidentally ship pointing at a
/// developer's laptop.
ApiConfig _configForBuild() {
  const String flavor = String.fromEnvironment('FLAVOR');
  return switch (flavor) {
    'production' => ApiConfig.production,
    'staging' => ApiConfig.staging,
    'development' => ApiConfig.development,
    _ => kReleaseMode ? ApiConfig.production : ApiConfig.development,
  };
}
