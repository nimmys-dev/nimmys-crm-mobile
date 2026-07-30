import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmys_crm/core/error/app_exception.dart';
import 'package:nimmys_crm/core/network/api_client.dart';
import 'package:nimmys_crm/core/network/api_response.dart';
import 'package:nimmys_crm/core/presentation/paginated_list_bloc.dart';
import 'package:nimmys_crm/core/presentation/view_state.dart';
import 'package:nimmys_crm/core/usecase/use_case.dart';
import 'package:nimmys_crm/core/utils/result.dart';
import 'package:nimmys_crm/features/leads/domain/entities/lead.dart';
import 'package:nimmys_crm/features/leads/domain/repositories/lead_repository.dart';
import 'package:nimmys_crm/features/leads/presentation/bloc/lead_list_bloc.dart';

/// Serves a scripted sequence of results, one per call.
///
/// A hand-written fake rather than a mock: the assertions here are about the
/// bloc's state machine, and a fake keeps the setup readable instead of
/// burying it in `when(...).thenAnswer(...)`.
class _ScriptedLeadRepository implements LeadRepository {
  _ScriptedLeadRepository(this._responses);

  final List<Result<PaginatedData<Lead>>> _responses;

  int calls = 0;

  @override
  Future<Result<PaginatedData<Lead>>> getLeads({
    PageParams params = const PageParams(),
    LeadStatus? status,
    bool forceRefresh = false,
    ApiCancelToken? cancelToken,
  }) async {
    final Result<PaginatedData<Lead>> response =
        _responses[calls.clamp(0, _responses.length - 1)];
    calls++;
    return response;
  }

  @override
  Future<Result<PaginatedData<Lead>>> getDueFollowUps({
    PageParams params = const PageParams(),
    ApiCancelToken? cancelToken,
  }) => getLeads(params: params);

  @override
  Future<Result<Lead>> getLead(String id, {ApiCancelToken? cancelToken}) async =>
      FailureResult<Lead>(const NotFoundException());

  @override
  Future<Result<Lead>> createLead(LeadDraft draft) async =>
      FailureResult<Lead>(const NotFoundException());

  @override
  Future<Result<Lead>> updateLead(String id, LeadDraft draft) async =>
      FailureResult<Lead>(const NotFoundException());

  @override
  Future<Result<void>> deleteLead(String id) async => const Success<void>(null);
}

Lead _lead(String id) => Lead(
  id: id,
  name: 'Lead $id',
  mobile: '90000000$id',
  status: LeadStatus.fresh,
  createdAt: DateTime(2026, 1, 1),
);

PaginatedData<Lead> _page(
  List<String> ids, {
  int page = 1,
  bool hasMore = false,
}) => PaginatedData<Lead>(
  items: ids.map(_lead).toList(),
  page: page,
  hasMore: hasMore,
);

void main() {
  group('LeadListBloc', () {
    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'goes initial -> loading -> loaded on a first page with rows',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(_page(<String>['1', '2'])),
        ]),
      ),
      act: (LeadListBloc bloc) => bloc.add(const ListLoadRequested()),
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<LoadedState<List<Lead>>>().having(
          (LoadedState<List<Lead>> state) => state.data.length,
          'row count',
          2,
        ),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'reports an empty page as empty, not as a loaded empty list',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(_page(<String>[])),
        ]),
      ),
      act: (LeadListBloc bloc) => bloc.add(const ListLoadRequested()),
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<EmptyState<List<Lead>>>(),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'surfaces a failure as an error state carrying the exception',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          const FailureResult<PaginatedData<Lead>>(NetworkException()),
        ]),
      ),
      act: (LeadListBloc bloc) => bloc.add(const ListLoadRequested()),
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<ErrorState<List<Lead>>>().having(
          (ErrorState<List<Lead>> state) => state.exception,
          'exception',
          isA<NetworkException>(),
        ),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'appends the next page instead of replacing the current one',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(
            _page(<String>['1', '2'], hasMore: true),
          ),
          Success<PaginatedData<Lead>>(_page(<String>['3'], page: 2)),
        ]),
      ),
      act: (LeadListBloc bloc) async {
        bloc.add(const ListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListLoadMoreRequested());
      },
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<LoadedState<List<Lead>>>(),
        // Keeps the existing rows on screen while the next page loads.
        isA<LoadingMoreState<List<Lead>>>().having(
          (LoadingMoreState<List<Lead>> state) => state.data.length,
          'rows still visible',
          2,
        ),
        isA<LoadedState<List<Lead>>>().having(
          (LoadedState<List<Lead>> state) => state.data.length,
          'rows after append',
          3,
        ),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'keeps the current rows visible while refreshing',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(_page(<String>['1', '2'])),
          Success<PaginatedData<Lead>>(_page(<String>['1', '2', '3'])),
        ]),
      ),
      act: (LeadListBloc bloc) async {
        bloc.add(const ListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListRefreshRequested());
      },
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<LoadedState<List<Lead>>>(),
        // The point of the whole design: a refresh must not blank the list.
        isA<RefreshingState<List<Lead>>>().having(
          (RefreshingState<List<Lead>> state) => state.data.length,
          'rows still visible',
          2,
        ),
        isA<LoadedState<List<Lead>>>().having(
          (LoadedState<List<Lead>> state) => state.data.length,
          'rows after refresh',
          3,
        ),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'keeps the loaded rows when loading more fails',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(
            _page(<String>['1', '2'], hasMore: true),
          ),
          const FailureResult<PaginatedData<Lead>>(RequestTimeoutException()),
        ]),
      ),
      act: (LeadListBloc bloc) async {
        bloc.add(const ListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListLoadMoreRequested());
      },
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<LoadedState<List<Lead>>>(),
        isA<LoadingMoreState<List<Lead>>>(),
        isA<ErrorState<List<Lead>>>().having(
          (ErrorState<List<Lead>> state) => state.previousData?.length,
          'rows kept behind the error',
          2,
        ),
      ],
    );

    blocTest<LeadListBloc, ViewState<List<Lead>>>(
      'ignores a second load when data is already present',
      build: () => LeadListBloc(
        _ScriptedLeadRepository(<Result<PaginatedData<Lead>>>[
          Success<PaginatedData<Lead>>(_page(<String>['1'])),
        ]),
      ),
      act: (LeadListBloc bloc) async {
        bloc.add(const ListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListLoadRequested());
      },
      expect: () => <Matcher>[
        isA<LoadingState<List<Lead>>>(),
        isA<LoadedState<List<Lead>>>(),
      ],
    );
  });

  group('ViewState', () {
    test('exposes data through refreshing, loading-more and error alike', () {
      const List<int> rows = <int>[1, 2, 3];

      expect(const LoadedState<List<int>>(rows).dataOrNull, rows);
      expect(const RefreshingState<List<int>>(rows).dataOrNull, rows);
      expect(
        const LoadingMoreState<List<int>>(
          rows,
          pageInfo: PageInfo(page: 1, hasMore: true),
        ).dataOrNull,
        rows,
      );
      expect(
        const ErrorState<List<int>>(
          NetworkException(),
          previousData: rows,
        ).dataOrNull,
        rows,
      );
      expect(const LoadingState<List<int>>().dataOrNull, isNull);
      expect(const EmptyState<List<int>>().dataOrNull, isNull);
    });

    test('only allows load-more from a settled loaded page', () {
      const PageInfo more = PageInfo(page: 1, hasMore: true);

      expect(
        const LoadedState<List<int>>(<int>[1], pageInfo: more).canLoadMore,
        isTrue,
      );
      // Already fetching — asking again is the double-fetch bug.
      expect(
        const LoadingMoreState<List<int>>(<int>[1], pageInfo: more).canLoadMore,
        isFalse,
      );
      expect(
        const LoadedState<List<int>>(<int>[1]).canLoadMore,
        isFalse,
      );
    });

    test('surfaces field errors from a rejected form submission', () {
      const ViewState<int> state = ErrorState<int>(
        ValidationException(
          fieldErrors: <String, List<String>>{
            'mobile': <String>['Enter a valid mobile number.'],
          },
        ),
      );

      expect(state.fieldErrors['mobile']?.first, contains('valid mobile'));
    });
  });
}
