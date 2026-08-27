import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/staff/api_request/create_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/api_request/update_staff_api_request.dart';
import 'package:nimmys_crm/features/staff/model/create_staffsuccess_model.dart';
import 'package:nimmys_crm/features/staff/model/delete_staff_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_details_model.dart';
import 'package:nimmys_crm/features/staff/model/staff_list_model.dart';
import 'package:nimmys_crm/features/staff/model/store_success_model.dart';
import 'package:nimmys_crm/features/staff/model/user_role_model.dart';
import 'package:nimmys_crm/features/staff/repository/staff_repository.dart';
import 'package:nimmys_crm/features/duties/model/task_details_model.dart';
import 'package:nimmys_crm/features/duties/model/tasks_list_model.dart';
import 'package:nimmys_crm/features/duties/repository/tasks_repository.dart';
part 'staff_state.dart';

class StaffCubit extends BaseCubit<StaffState> {
  final StaffRepository _repository;
  StaffCubit(this._repository) : super(const StaffState());

  // Branches Api Call
  void _setBranchesUIState(UIState<StoreModelSuccess>? uiState) {
    emit(state.copyWith(branchesUIState: uiState));
  }

  /// [force] re-fetches even when the branches are already loaded. Staff
  /// Creation calls this on every mount, so without the guard the branch picker
  /// would blank out and refill each time the screen is opened.
  Future<void> getBranches({bool force = false}) async {
    if (!force && state.branchesUIState?.data != null) {
      return;
    }
    _setBranchesUIState(UIState.loading());
    Result result = await _repository.getBranches();
    if (result is Success<StoreModelSuccess>) {
      _setBranchesUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setBranchesUIState(UIState.error(result.type));
    }
  }

  // User Roles Api Call
  void _setUserRolesUIState(UIState<UserRoleSuccess>? uiState) {
    emit(state.copyWith(userRolesUIState: uiState));
  }

  /// [force] re-fetches even when the roles are already loaded. Staff Creation
  /// calls this on every mount, so without the guard the role picker would
  /// blank out and refill each time the screen is opened.
  Future<void> getUserRoles({bool force = false}) async {
    if (!force && state.userRolesUIState?.data != null) {
      return;
    }
    _setUserRolesUIState(UIState.loading());
    Result result = await _repository.getUserRoles();
    if (result is Success<UserRoleSuccess>) {
      _setUserRolesUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setUserRolesUIState(UIState.error(result.type));
    }
  }

  // Staff List Api Call
  //
  // Page 1 replaces the list, later pages append to it. The accumulated items
  // live in state rather than being read back out of the last response, because
  // the last response only ever holds one page.
  static const int _pageSize = 10;

  Future<void> getStaffList({bool refresh = false, String? search}) async {
    if (state.staffListUIState?.status == Status.LOADING) {
      return;
    }
    final String query = (search ?? state.staffSearchQuery).trim();
    final bool searchChanged = query != state.staffSearchQuery;
    // A refresh keeps the current rows on screen while it reloads, so pulling
    // down does not blank the list it is refreshing.
    if (!refresh && !searchChanged && state.staffList.isNotEmpty) {
      return;
    }
    emit(
      state.copyWith(
        staffListUIState: UIState.loading(),
        staffSearchQuery: query,
        // Results for a previous search must never remain visible while the
        // new server-side search is in flight.
        staffList: searchChanged ? <StaffListItem>[] : state.staffList,
      ),
    );

    final Result<StaffListSuccess> result = await _repository.getStaffList(
      page: 1,
      perPage: _pageSize,
      search: query,
    );
    if (result is Success<StaffListSuccess>) {
      emit(
        state.copyWith(
          staffListUIState: UIState.success(result.value),
          staffList: result.value.data,
          staffPagination: result.value.pagination,
          isLoadingMoreStaff: false,
        ),
      );
    }
    // `Error<StaffListSuccess>`, not a bare `Error`: a `Result<StaffListSuccess>`
    // is not a subtype of `Error<dynamic>`, so the bare form never promotes and
    // `.type` would not resolve.
    if (result is Error<StaffListSuccess>) {
      emit(state.copyWith(staffListUIState: UIState.error(result.type)));
    }
  }

  /// Fetches the next page and appends it. Silent about failure by design — a
  /// load-more that fails should not replace a list the user is already reading;
  /// the row simply stops spinning and scrolling again retries.
  Future<void> loadMoreStaff() async {
    final StaffPagination? pagination = state.staffPagination;
    if (state.isLoadingMoreStaff ||
        state.staffListUIState?.status == Status.LOADING ||
        pagination == null ||
        !pagination.hasNextPage) {
      return;
    }
    emit(state.copyWith(isLoadingMoreStaff: true));

    final Result<StaffListSuccess> result = await _repository.getStaffList(
      page: pagination.nextPage,
      perPage: _pageSize,
      search: state.staffSearchQuery,
    );
    if (result is Success<StaffListSuccess>) {
      emit(
        state.copyWith(
          // A new list instance, not an in-place add: Equatable compares the
          // contents, so mutating the existing one would emit a state the UI
          // considers unchanged.
          staffList: <StaffListItem>[...state.staffList, ...result.value.data],
          staffPagination: result.value.pagination,
          isLoadingMoreStaff: false,
        ),
      );
      return;
    }
    emit(state.copyWith(isLoadingMoreStaff: false));
  }

  // Create Staff Api Call
  void _setCreateStaffUIState(UIState<CreateStaffSuccess>? uiState) {
    emit(state.copyWith(createStaffUIState: uiState));
  }

  Future<void> createStaff(CreateStaffApiRequest request) async {
    // Second line of defence against a double submit: the button is already
    // disabled while LOADING, but a queued tap that lands between the tap and
    // the rebuild would otherwise create the staff member twice.
    if (state.createStaffUIState?.status == Status.LOADING) {
      return;
    }
    _setCreateStaffUIState(UIState.loading());
    Result result = await _repository.createStaff(request);
    if (result is Success<CreateStaffSuccess>) {
      _setCreateStaffUIState(UIState.success(result.value));
      // The list the user is about to land back on no longer matches the
      // server. Refreshing here rather than in the screen means it is correct
      // however Staff Creation was reached — from the list, from the catalog,
      // or straight from a route — and the list screen needs no knowledge of
      // where its data went stale.
      //
      // Not awaited: the screen's SUCCESS listener toasts and pops immediately,
      // and the reload lands into a list that is already on its way back.
      unawaited(getStaffList(refresh: true));
    }
    if (result is Error) {
      _setCreateStaffUIState(UIState.error(result.type));
    }
  }

  /// Drops the terminal state so a returning visit to the screen does not
  /// replay the previous attempt's toast and navigation. The cubit is a
  /// singleton, so without this the loaded branches would be the only thing
  /// worth keeping between visits.
  void resetCreateStaffState() {
    _setCreateStaffUIState(
      resetUIState<CreateStaffSuccess>(state.createStaffUIState),
    );
  }

  // View Staff Api Call
  void _setStaffDetailsUIState(UIState<StaffDetailsSuccess>? uiState) {
    emit(state.copyWith(staffDetailsUIState: uiState));
  }

  /// Always fetches fresh — no "already loaded" guard, unlike branches/roles.
  /// This is a per-record view: the id changes between visits, and a guard
  /// keyed only on "is something loaded" would show a previously viewed staff
  /// member's data while a different one's request is in flight.
  Future<void> getStaffDetails(int id) async {
    _setStaffDetailsUIState(UIState.loading());
    Result result = await _repository.getStaffDetails(id);
    if (result is Success<StaffDetailsSuccess>) {
      _setStaffDetailsUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setStaffDetailsUIState(UIState.error(result.type));
    }
  }

  void resetStaffDetailsState() {
    _setStaffDetailsUIState(
      resetUIState<StaffDetailsSuccess>(state.staffDetailsUIState),
    );
  }

  // Update Staff Api Call
  void _setUpdateStaffUIState(UIState<StaffDetailsSuccess>? uiState) {
    emit(state.copyWith(updateStaffUIState: uiState));
  }

  Future<void> updateStaff(int id, UpdateStaffApiRequest request) async {
    if (state.updateStaffUIState?.status == Status.LOADING) {
      return;
    }
    _setUpdateStaffUIState(UIState.loading());
    Result result = await _repository.updateStaff(id, request);
    if (result is Success<StaffDetailsSuccess>) {
      _setUpdateStaffUIState(UIState.success(result.value));
      // Same reasoning as createStaff: whichever screen the user lands back
      // on after saving should already show the edited name/role/status.
      unawaited(getStaffList(refresh: true));
    }
    if (result is Error) {
      _setUpdateStaffUIState(UIState.error(result.type));
    }
  }

  void resetUpdateStaffState() {
    _setUpdateStaffUIState(
      resetUIState<StaffDetailsSuccess>(state.updateStaffUIState),
    );
  }

  // Delete Staff Api Call
  void _setDeleteStaffUIState(UIState<DeleteStaffSuccess>? uiState) {
    emit(state.copyWith(deleteStaffUIState: uiState));
  }

  /// `state.deletingStaffId` is what a specific row reads to show its own
  /// spinner — the shared `deleteStaffUIState` alone cannot say *which* staff
  /// member is mid-delete when the list has several rows on screen.
  Future<void> deleteStaff(int id) async {
    // One delete at a time — also the guard against a double tap on the same
    // row landing between the tap and the button disabling.
    if (state.deletingStaffId != null) {
      return;
    }
    emit(
      state.copyWith(
        deletingStaffId: id,
        deleteStaffUIState: UIState.loading(),
      ),
    );
    Result result = await _repository.deleteStaff(id);
    if (result is Success<DeleteStaffSuccess>) {
      emit(
        state.copyWith(
          deleteStaffUIState: UIState.success(result.value),
          clearDeletingStaffId: true,
        ),
      );
      // Same reasoning as create/update: whichever screen is showing the list
      // next should already be missing the deleted row, not carrying it until
      // something else happens to trigger a reload.
      unawaited(getStaffList(refresh: true));
      return;
    }
    if (result is Error) {
      emit(
        state.copyWith(
          deleteStaffUIState: UIState.error(result.type),
          clearDeletingStaffId: true,
        ),
      );
    }
  }

  void resetDeleteStaffState() {
    _setDeleteStaffUIState(
      resetUIState<DeleteStaffSuccess>(state.deleteStaffUIState),
    );
  }
  // ---------------------------------------------------------------------------
// My Tasks List
// ---------------------------------------------------------------------------

Future<void> getMyTasks({bool refresh = false, String? search}) async {
  if (state.myTasksListUIState?.status == Status.LOADING) return;

  final String query = (search ?? state.myTasksSearchQuery).trim();
  final bool searchChanged = query != state.myTasksSearchQuery;

  if (!refresh && !searchChanged && state.myTasksList.isNotEmpty) {
    return;
  }

  emit(state.copyWith(
    myTasksListUIState: UIState.loading(),
    myTasksSearchQuery: query,
    myTasksList: searchChanged ? <Task>[] : state.myTasksList,
  ));

  final result = await _repository.getMyTasksList(
    page: 1,
    perPage: _pageSize, // reuse _pageSize from StaffCubit
    search: query,
  );

  if (result is Success<TaskListResponse>) {
    emit(state.copyWith(
      myTasksListUIState: UIState.success(result.value),
      myTasksList: result.value.data ?? [],
      myTasksPagination: result.value.pagination,
      isLoadingMoreMyTasks: false,
    ));
  } else if (result is Error<TaskListResponse>) {
    emit(state.copyWith(
      myTasksListUIState: UIState.error(result.type),
    ));
  }
}

Future<void> refreshMyTasks() async {
  await getMyTasks(refresh: true);
}

Future<void> loadMoreMyTasks() async {
  final pagination = state.myTasksPagination;
  if (state.isLoadingMoreMyTasks ||
      state.myTasksListUIState?.status == Status.LOADING ||
      pagination == null ||
      !pagination.hasNextPage) {
    return;
  }

  emit(state.copyWith(isLoadingMoreMyTasks: true));

  final result = await _repository.getMyTasksList(
    page: pagination.nextPage,
    perPage: _pageSize,
    search: state.myTasksSearchQuery,
  );

  if (result is Success<TaskListResponse>) {
    emit(state.copyWith(
      myTasksList: [...state.myTasksList, ...?result.value.data],
      myTasksPagination: result.value.pagination,
      isLoadingMoreMyTasks: false,
    ));
  } else {
    emit(state.copyWith(isLoadingMoreMyTasks: false));
  }
}

void resetMyTasksState() {
  emit(state.copyWith(
    myTasksListUIState: null,
    myTasksList: const <Task>[],
    myTasksPagination: null,
    myTasksSearchQuery: '',
    isLoadingMoreMyTasks: false,
  ));
}

  /// Called on sign-out. Branches are scoped to the account that fetched them,
  /// so the cached list has to go with the session — otherwise the next user to
  /// sign in picks a branch from the previous user's shops.
  void resetStaffState() {
    emit(const StaffState());
  }
}
