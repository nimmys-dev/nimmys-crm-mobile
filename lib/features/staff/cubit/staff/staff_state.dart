part of 'staff_cubit.dart';

class StaffState extends Equatable {
  final UIState<StoreModelSuccess>? branchesUIState;
  final UIState<UserRoleSuccess>? userRolesUIState;
  final UIState<CreateStaffSuccess>? createStaffUIState;

  /// The record behind `GET /api/view-staff/{id}` — Staff Details reads this,
  /// and Edit Staff prefills its form from it.
  final UIState<StaffDetailsSuccess>? staffDetailsUIState;

  /// `POST /api/update-staff/{id}`'s own terminal state, kept separate from
  /// [createStaffUIState] so a create in flight on one screen can never be
  /// mistaken for an update finishing on another.
  final UIState<StaffDetailsSuccess>? updateStaffUIState;

  /// Status of the *current page request*. The rows themselves live in
  /// [staffList] because the response only ever carries one page.
  final UIState<StaffListSuccess>? staffListUIState;

  /// Every row loaded so far, page 1 first.
  final List<StaffListItem> staffList;
  final StaffPagination? staffPagination;

  /// True only while a follow-on page is in flight, so the footer spinner is
  /// separate from the full-screen loading state.
  final bool isLoadingMoreStaff;

  /// `DELETE /api/delete-staff/{id}`'s own terminal state, drives the toast.
  final UIState<DeleteStaffSuccess>? deleteStaffUIState;

  /// The id currently being deleted, or null. What a specific row reads for
  /// its own spinner — [deleteStaffUIState] alone cannot say *which* row.
  final int? deletingStaffId;

  const StaffState({
    this.branchesUIState,
    this.userRolesUIState,
    this.createStaffUIState,
    this.staffDetailsUIState,
    this.updateStaffUIState,
    this.staffListUIState,
    this.staffList = const <StaffListItem>[],
    this.staffPagination,
    this.isLoadingMoreStaff = false,
    this.deleteStaffUIState,
    this.deletingStaffId,
  });

  StaffState copyWith({
    UIState<StoreModelSuccess>? branchesUIState,
    UIState<UserRoleSuccess>? userRolesUIState,
    UIState<CreateStaffSuccess>? createStaffUIState,
    UIState<StaffDetailsSuccess>? staffDetailsUIState,
    UIState<StaffDetailsSuccess>? updateStaffUIState,
    UIState<StaffListSuccess>? staffListUIState,
    List<StaffListItem>? staffList,
    StaffPagination? staffPagination,
    bool? isLoadingMoreStaff,
    UIState<DeleteStaffSuccess>? deleteStaffUIState,
    int? deletingStaffId,
    // `deletingStaffId: null` from a caller means "leave it alone", matching
    // every other field here — this is the explicit "actually clear it" flag,
    // the same `clearX` shape `TaskSchedule.copyWith` already uses.
    bool clearDeletingStaffId = false,
  }) {
    return StaffState(
      branchesUIState: branchesUIState ?? this.branchesUIState,
      userRolesUIState: userRolesUIState ?? this.userRolesUIState,
      createStaffUIState: createStaffUIState ?? this.createStaffUIState,
      staffDetailsUIState: staffDetailsUIState ?? this.staffDetailsUIState,
      updateStaffUIState: updateStaffUIState ?? this.updateStaffUIState,
      staffListUIState: staffListUIState ?? this.staffListUIState,
      staffList: staffList ?? this.staffList,
      staffPagination: staffPagination ?? this.staffPagination,
      isLoadingMoreStaff: isLoadingMoreStaff ?? this.isLoadingMoreStaff,
      deleteStaffUIState: deleteStaffUIState ?? this.deleteStaffUIState,
      deletingStaffId: clearDeletingStaffId
          ? null
          : (deletingStaffId ?? this.deletingStaffId),
    );
  }

  @override
  List<Object?> get props => [
    branchesUIState,
    branchesUIState?.status,
    branchesUIState?.data,
    branchesUIState?.errorType,
    userRolesUIState,
    userRolesUIState?.status,
    userRolesUIState?.data,
    userRolesUIState?.errorType,
    createStaffUIState,
    createStaffUIState?.status,
    createStaffUIState?.data,
    createStaffUIState?.errorType,
    staffDetailsUIState,
    staffDetailsUIState?.status,
    staffDetailsUIState?.data,
    staffDetailsUIState?.errorType,
    updateStaffUIState,
    updateStaffUIState?.status,
    updateStaffUIState?.data,
    updateStaffUIState?.errorType,
    staffListUIState,
    staffListUIState?.status,
    staffListUIState?.data,
    staffListUIState?.errorType,
    staffList,
    staffPagination,
    isLoadingMoreStaff,
    deleteStaffUIState,
    deleteStaffUIState?.status,
    deleteStaffUIState?.data,
    deleteStaffUIState?.errorType,
    deletingStaffId,
  ];
}
