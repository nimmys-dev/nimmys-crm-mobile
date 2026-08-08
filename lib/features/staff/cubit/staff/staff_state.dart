part of 'staff_cubit.dart';

class StaffState extends Equatable {
  final UIState<StoreModelSuccess>? branchesUIState;
  final UIState<CreateStaffSuccess>? createStaffUIState;

  /// Status of the *current page request*. The rows themselves live in
  /// [staffList] because the response only ever carries one page.
  final UIState<StaffListSuccess>? staffListUIState;

  /// Every row loaded so far, page 1 first.
  final List<StaffListItem> staffList;
  final StaffPagination? staffPagination;

  /// True only while a follow-on page is in flight, so the footer spinner is
  /// separate from the full-screen loading state.
  final bool isLoadingMoreStaff;

  const StaffState({
    this.branchesUIState,
    this.createStaffUIState,
    this.staffListUIState,
    this.staffList = const <StaffListItem>[],
    this.staffPagination,
    this.isLoadingMoreStaff = false,
  });

  StaffState copyWith({
    UIState<StoreModelSuccess>? branchesUIState,
    UIState<CreateStaffSuccess>? createStaffUIState,
    UIState<StaffListSuccess>? staffListUIState,
    List<StaffListItem>? staffList,
    StaffPagination? staffPagination,
    bool? isLoadingMoreStaff,
  }) {
    return StaffState(
      branchesUIState: branchesUIState ?? this.branchesUIState,
      createStaffUIState: createStaffUIState ?? this.createStaffUIState,
      staffListUIState: staffListUIState ?? this.staffListUIState,
      staffList: staffList ?? this.staffList,
      staffPagination: staffPagination ?? this.staffPagination,
      isLoadingMoreStaff: isLoadingMoreStaff ?? this.isLoadingMoreStaff,
    );
  }

  @override
  List<Object?> get props => [
    branchesUIState,
    branchesUIState?.status,
    branchesUIState?.data,
    branchesUIState?.errorType,
    createStaffUIState,
    createStaffUIState?.status,
    createStaffUIState?.data,
    createStaffUIState?.errorType,
    staffListUIState,
    staffListUIState?.status,
    staffListUIState?.data,
    staffListUIState?.errorType,
    staffList,
    staffPagination,
    isLoadingMoreStaff,
  ];
}
