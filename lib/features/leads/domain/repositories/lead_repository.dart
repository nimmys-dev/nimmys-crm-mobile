import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/result.dart';
import '../entities/lead.dart';

/// What the leads feature can do, stated without saying how.
///
/// Declared in the domain layer and implemented in data, so the dependency
/// points inwards: blocs know this interface, not the API. Swapping the
/// backend, adding an offline cache or handing a fake to a test all happen
/// behind it without a bloc changing.
///
/// Every method returns [Result] rather than throwing — a caller cannot read
/// the value without first deciding what happens when there isn't one.
abstract interface class LeadRepository {
  Future<Result<PaginatedData<Lead>>> getLeads({
    PageParams params,
    LeadStatus? status,
    bool forceRefresh,
    ApiCancelToken? cancelToken,
  });

  /// Leads whose next follow-up falls on or before today.
  Future<Result<PaginatedData<Lead>>> getDueFollowUps({
    PageParams params,
    ApiCancelToken? cancelToken,
  });

  Future<Result<Lead>> getLead(String id, {ApiCancelToken? cancelToken});

  Future<Result<Lead>> createLead(LeadDraft draft);

  Future<Result<Lead>> updateLead(String id, LeadDraft draft);

  Future<Result<void>> deleteLead(String id);
}
