import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';
import '../datasources/lead_remote_data_source.dart';

/// Turns the data source's throws into [Result]s.
///
/// This is the layer boundary: below it code throws, above it code branches.
/// [guard] does the conversion, which is why every method here is a single
/// expression and why no exception can escape into a bloc even if a new data
/// source starts throwing something unanticipated.
///
/// The connectivity pre-check is the other job. Without it an offline tap
/// spends the full connect timeout before failing; with it the user gets an
/// honest answer immediately.
class LeadRepositoryImpl implements LeadRepository {
  const LeadRepositoryImpl({
    required LeadRemoteDataSource remote,
    required NetworkInfo networkInfo,
  }) : _remote = remote,
       _networkInfo = networkInfo;

  final LeadRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<PaginatedData<Lead>>> getLeads({
    PageParams params = const PageParams(),
    LeadStatus? status,
    bool forceRefresh = false,
    ApiCancelToken? cancelToken,
  }) => guard(() async {
    await _requireConnection();
    return _remote.fetchLeads(
      params: params,
      status: status,
      cancelToken: cancelToken,
    );
  });

  @override
  Future<Result<PaginatedData<Lead>>> getDueFollowUps({
    PageParams params = const PageParams(),
    ApiCancelToken? cancelToken,
  }) => guard(() async {
    await _requireConnection();
    return _remote.fetchLeads(
      params: params,
      dueOnly: true,
      cancelToken: cancelToken,
    );
  });

  @override
  Future<Result<Lead>> getLead(String id, {ApiCancelToken? cancelToken}) =>
      guard(() async {
        await _requireConnection();
        return _remote.fetchLead(id, cancelToken: cancelToken);
      });

  @override
  Future<Result<Lead>> createLead(LeadDraft draft) => guard(() async {
    await _requireConnection();
    return _remote.createLead(draft);
  });

  @override
  Future<Result<Lead>> updateLead(String id, LeadDraft draft) =>
      guard(() async {
        await _requireConnection();
        return _remote.updateLead(id, draft);
      });

  @override
  Future<Result<void>> deleteLead(String id) => guard(() async {
    await _requireConnection();
    return _remote.deleteLead(id);
  });

  /// Fails fast when the device has no route out, rather than waiting for a
  /// connect timeout to reach the same conclusion 15 seconds later.
  Future<void> _requireConnection() async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException();
    }
  }
}
