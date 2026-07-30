import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/lead.dart';
import '../models/lead_model.dart';

/// The leads endpoints, one method each.
///
/// An interface so the repository can be tested against a fake without a
/// mock HTTP layer, and so a cached or offline source can be dropped in
/// beside this one later.
abstract interface class LeadRemoteDataSource {
  Future<PaginatedData<LeadModel>> fetchLeads({
    required PageParams params,
    LeadStatus? status,
    bool dueOnly,
    ApiCancelToken? cancelToken,
  });

  Future<LeadModel> fetchLead(String id, {ApiCancelToken? cancelToken});

  Future<LeadModel> createLead(LeadDraft draft);

  Future<LeadModel> updateLead(String id, LeadDraft draft);

  Future<void> deleteLead(String id);
}

/// Talks to the API through the shared [ApiClient].
///
/// Notice what is *not* here: no try/catch, no status-code checks, no
/// envelope unwrapping, no manual JSON casting. The client and its
/// interceptors do all of that, which is what keeps each endpoint down to a
/// call and a parser. Anything that goes wrong arrives at the repository as
/// a typed `AppException`.
class LeadRemoteDataSourceImpl implements LeadRemoteDataSource {
  const LeadRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<PaginatedData<LeadModel>> fetchLeads({
    required PageParams params,
    LeadStatus? status,
    bool dueOnly = false,
    ApiCancelToken? cancelToken,
  }) async {
    final ApiResponse<PaginatedData<LeadModel>> response = await _client
        .get<PaginatedData<LeadModel>>(
          Endpoints.leads,
          queryParameters: <String, dynamic>{
            ...params.toQuery(),
            if (status != null) 'status': status.wireValue,
            if (dueOnly) 'due': 'today',
          },
          // The rows are under `data` but the page count is under `meta`, so
          // this parser needs the whole body rather than the unwrapped payload.
          config: RequestConfig.paginated,
          parser: (dynamic json) => PaginatedData.fromJson<LeadModel>(
            json,
            itemParser: LeadModel.fromJson,
          ),
          cancelToken: cancelToken,
        );
    return response.data;
  }

  @override
  Future<LeadModel> fetchLead(String id, {ApiCancelToken? cancelToken}) async {
    final ApiResponse<LeadModel> response = await _client.get<LeadModel>(
      Endpoints.leadById(id),
      parser: (dynamic json) =>
          LeadModel.fromJson(json as Map<String, dynamic>),
      cancelToken: cancelToken,
    );
    return response.data;
  }

  @override
  Future<LeadModel> createLead(LeadDraft draft) async {
    final ApiResponse<LeadModel> response = await _client.post<LeadModel>(
      Endpoints.leads,
      body: draft.toJson(),
      parser: (dynamic json) =>
          LeadModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<LeadModel> updateLead(String id, LeadDraft draft) async {
    final ApiResponse<LeadModel> response = await _client.put<LeadModel>(
      Endpoints.leadById(id),
      body: draft.toJson(),
      parser: (dynamic json) =>
          LeadModel.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<void> deleteLead(String id) =>
      _client.delete<void>(Endpoints.leadById(id), parser: (dynamic _) {});
}
