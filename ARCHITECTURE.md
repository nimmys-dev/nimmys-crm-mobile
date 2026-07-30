# Architecture

MVVM with BLoC as the ViewModel, over a repository-backed data layer.

## The dependency rule

```
presentation  ──▶  domain  ◀──  data
      │                          │
      └──────────▶ core ◀────────┘
```

Arrows point at what a layer is allowed to import. `domain` imports nothing
from `data` or `presentation`, which is what makes a bloc testable with plain
constructors and no HTTP fake.

## Layout

Feature-first, not layer-first:

```
lib/
├── core/                        # reusable, feature-agnostic
│   ├── di/service_locator.dart  # get_it composition root
│   ├── error/app_exception.dart # the app's error vocabulary
│   ├── network/                 # ApiClient + Dio implementation
│   │   └── interceptors/        # auth · retry · logging · error
│   ├── presentation/            # ViewState + base blocs + shared widgets
│   ├── session/                 # SessionManager, forced-logout listener
│   ├── storage/                 # secure token storage
│   └── utils/result.dart        # Result<T>
└── features/<feature>/
    ├── domain/                  # entities · repository interfaces
    ├── data/                    # models · data sources · repository impls
    └── presentation/            # blocs · screens
```

Layer-first (`lib/data/models/…` for the whole app) collapses at scale — you
end up with two hundred files in one folder and no way to see a feature whole.
Feature-first keeps everything a lead touches under `features/leads/`.

## The eight states

`core/presentation/view_state.dart` defines one generic `ViewState<T>` that
every feature reuses. A list screen is `ViewState<List<Lead>>`, a detail
screen `ViewState<Lead>`, a form `ViewState<void>`.

| State | Carries data | Meaning |
|---|---|---|
| `InitialState` | — | Nothing requested yet |
| `LoadingState` | — | First load, blank screen |
| `LoadedState` | ✅ | Data present |
| `EmptyState` | — | Loaded successfully, nothing to show |
| `RefreshingState` | ✅ | Reloading page 1, rows stay visible |
| `LoadingMoreState` | ✅ | Fetching next page, rows stay visible |
| `SuccessState` | optional | A write completed |
| `ErrorState` | previous data | Failed, and what was on screen before |

The column that matters is the middle one. Modelling a refresh as "loading,
therefore no data" is what makes apps blank out and jump to a spinner on every
pull-to-refresh. Here the data survives a refresh, a load-more **and** a
failure, so a failed page 3 leaves pages 1–2 perfectly usable with a retry
footer underneath.

`SuccessState` is for writes and is read from a `BlocListener`, not a builder —
the reaction to a successful save is a pop and a snackbar, not a rebuild.

## Request lifecycle

Interceptors run in registration order, and the order is load-bearing:

1. **Auth** — attaches the bearer token. On a 401 it refreshes and replays the
   original request before anything else sees a failure.
2. **Retry** — exponential backoff with jitter, for transient failures auth
   could not fix. Only idempotent verbs by default: replaying a POST that
   timed out on the way back creates two leads from one tap.
3. **Logging** — records the final outcome, after any recovery. Redacts
   `Authorization`, cookies and password-ish fields; off entirely in release.
4. **Error** — maps `DioException` to `AppException` last, once the failure is
   final. This is where Dio stops existing as far as the rest of the app is
   concerned.

Then `guard()` in the repository converts a throw into a `Result`, and the
bloc folds that into a state. A widget never sees an exception.

### Token refresh under concurrency

The subtle part. A dashboard opening four requests at once sees four
simultaneous 401s. The naive implementation fires four refreshes, three of
which use an already-rotated refresh token, fail, and sign the user out
mid-session.

`AuthInterceptor` holds a single in-flight refresh future. Concurrent 401s all
await the same one, so N failures spend exactly one refresh token. The refresh
itself goes through a separate Dio instance with no auth interceptor — sharing
one would make a 401 on refresh trigger another refresh, forever.

## Adding a feature

Five files, and only the last two contain anything specific to it.

```dart
// 1. domain/entities/duty.dart          — plain class, no JSON
// 2. domain/repositories/duty_repository.dart
abstract interface class DutyRepository {
  Future<Result<PaginatedData<Duty>>> getDuties({PageParams params});
}

// 3. data/models/duty_model.dart        — extends Duty, adds fromJson
// 4. data/datasources/duty_remote_data_source.dart
final ApiResponse<PaginatedData<DutyModel>> response = await _client
    .get<PaginatedData<DutyModel>>(
      Endpoints.duties,
      queryParameters: params.toQuery(),
      config: RequestConfig.paginated,
      parser: (dynamic json) =>
          PaginatedData.fromJson<DutyModel>(json, itemParser: DutyModel.fromJson),
    );

// 5. presentation/bloc/duty_list_bloc.dart
class DutyListBloc extends PaginatedListBloc<Duty> {
  DutyListBloc(this._repository);
  final DutyRepository _repository;

  @override
  Future<Result<PaginatedData<Duty>>> fetchPage(int page, {required bool isRefresh}) =>
      _repository.getDuties(params: PageParams(page: page, pageSize: pageSize));
}
```

That is the whole bloc. Load, refresh, append, empty detection, error
recovery and all eight state transitions are inherited. The screen is a
`PagedListView` and a row widget — see
`features/leads/presentation/screens/lead_list_screen.dart`, which is a
complete list screen in about a hundred lines and owns no loading flag, no
`try`/`catch` and no paging arithmetic.

Register the pieces in `core/di/service_locator.dart`: repositories and data
sources as lazy singletons, blocs as **factories** (a bloc that outlived its
screen would emit into a dead tree).

## Pointing at a different backend

- **Base URL / timeouts** — `core/network/api_config.dart`. Flavors are
  selected by `--dart-define=FLAVOR=staging`, falling back to build mode so a
  release build cannot ship pointing at a laptop.
- **Response shape** — `core/network/response_envelope.dart`. If the API wraps
  payloads as `{success, data, message, errors}`, `WrappedEnvelope` already
  handles it; otherwise swap the one registration in the service locator.
- **HTTP library** — implement `ApiClient` (no Dio types appear in its
  signatures) and change one DI line. No feature code moves.

## Deliberate omissions

- **No code generation.** Models hand-write `fromJson` against the defensive
  readers in `core/utils/json.dart`. The project had no `build_runner` and
  adding one means a generate step before the app compiles and generated files
  that drift. Swap in `json_serializable` per-model when a model earns it.
- **No use case per endpoint.** `core/usecase/use_case.dart` exists for logic
  worth holding — combining repositories, enforcing a rule. A use case that
  forwards one call to one repository is ceremony; blocs depend on
  repositories directly for plain CRUD.
- **No router.** The app still boots splash → screen catalog.
  `SessionExpiryListener` is wired in `app.dart` and shows the "session
  expired" message; give it `onSessionEnded` to navigate once a router exists.

## Testing

`test/features/leads/lead_list_bloc_test.dart` asserts the state sequences
directly — that a refresh keeps rows visible, that a failed load-more preserves
the list, that an empty page is `EmptyState` and not an empty `LoadedState`.

`test/widget_test.dart` boots the real app with `InMemoryTokenStorage` swapped
in via the `overrides` hook on `configureDependencies`, which is the pattern
for testing against the real object graph with only the platform-backed leaves
replaced.
