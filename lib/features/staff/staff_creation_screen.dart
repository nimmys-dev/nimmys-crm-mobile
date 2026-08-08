import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/model/result.dart';
import '../../data/ui_state/ui_state.dart';
import '../../enum/status.dart';
import '../../helpers/date_helper.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../utils/app_string.dart';
import '../../utils/toast_messages.dart';
import '../../utils/upload_images_and_documents/image_picker_from.dart';
import '../../utils/upload_images_and_documents/picked_images_and_documents_model.dart';
import '../../utils/validator.dart';
import 'api_request/create_staff_api_request.dart';
import 'api_request/update_staff_api_request.dart';
import 'cubit/staff/staff_cubit.dart';
import 'model/create_staffsuccess_model.dart';
import 'model/staff_details_model.dart';
import 'model/store_success_model.dart';
import 'model/user_role_model.dart';
import 'staff_list_screen.dart';
import 'widgets/staff_widgets.dart';

/// Staff Creation — personal profile plus employment and increment settings.
///
/// Also Edit Staff: passing [staffId] switches the same form to edit mode. The
/// two share every field, so one screen prefilled from
/// `GET /api/view-staff/{id}` and posting to `PUT /api/update-staff/{id}`
/// avoids maintaining the form twice — see `_isEditMode` throughout.
///
/// Branches and roles come from `GET /api/branches` / `GET /api/user-roles`;
/// the form posts to `POST /api/create-staff` or `POST /api/update-staff/{id}`
/// through [StaffCubit].
class StaffCreationScreen extends StatefulWidget {
  const StaffCreationScreen({super.key, this.staffId, this.onStaffCreated});

  /// Non-null switches the form to Edit Staff: the id is what
  /// `GET /api/view-staff/{id}` fetches and `POST /api/update-staff/{id}`
  /// writes back to.
  final int? staffId;

  /// Called once the API has accepted the new staff member, with the full
  /// response — `message` for a toast, `data` for the created record. Screens
  /// that own a staff list pass a callback here to refresh themselves; when it
  /// is null the screen pops and hands the same response back as the route
  /// result, so an `await context.push(...)` can do the same thing.
  ///
  /// Create-only: edit mode always pops rather than calling back, since it can
  /// be opened from more than one place (Staff Details, the catalog) and none
  /// of them needs anything richer than "something changed, refetch".
  final ValueChanged<CreateStaffSuccess?>? onStaffCreated;

  @override
  State<StaffCreationScreen> createState() => _StaffCreationScreenState();
}

class _StaffCreationScreenState extends State<StaffCreationScreen> {
  static const List<IncrementRecord> _history = <IncrementRecord>[
    IncrementRecord(
      effectiveDate: '15 May 2025',
      salary: '₹27,500',
      incrementSalary: '₹2,500',
      remarks: 'Annual increment',
    ),
    IncrementRecord(
      effectiveDate: '15 May 2024',
      salary: '₹25,000',
      incrementSalary: '₹2,000',
      remarks: 'Annual increment',
    ),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _altMobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _incrementController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  /// The whole branch record, not its name: `shop_id` is what the API wants and
  /// two shops are free to share a display name.
  StoreResponseData? _branch;

  /// The whole role record, not its label: `role` sends `value` ("manager")
  /// while the picker shows `label` ("Manager").
  UserRoleOption? _role;
  DateTime? _joiningDate;
  DateTime? _nextIncrementDate;
  bool _incrementReminder = true;
  bool _leadManagement = true;
  File? _photo;

  String? _nameError;
  String? _mobileError;
  String? _altMobileError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _branchError;
  String? _roleError;
  String? _joiningDateError;
  String? _salaryError;
  String? _incrementAmountError;

  bool get _isEditMode => widget.staffId != null;

  /// True once [_prefillFrom] has populated the text controllers, dates and
  /// toggles from the fetched record. Guards against re-running that on every
  /// rebuild and clobbering whatever the user has since typed. Branch and role
  /// are prefilled independently of this flag — see [_tryPrefillSelections] —
  /// since they depend on branches/roles having loaded, which can land after
  /// the staff record does.
  bool _textFieldsPrefilled = false;

  /// The staff member's current photo, shown by [StaffPhotoPicker] until the
  /// user picks a replacement. Null in create mode.
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    // The cubit is a singleton, so a previous visit's SUCCESS/ERROR would still
    // be sitting in state and fire the listener the moment this screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final StaffCubit cubit = context.read<StaffCubit>()
          ..resetCreateStaffState()
          ..resetUpdateStaffState()
          ..getBranches()
          ..getUserRoles();
        if (_isEditMode) {
          cubit.getStaffDetails(widget.staffId!);
        }
      }
    });
  }

  /// Fills every field that does not depend on branches/roles having loaded —
  /// called once, guarded by [_textFieldsPrefilled].
  void _prefillFrom(StaffDetailsData details) {
    _nameController.text = details.name ?? '';
    _mobileController.text = details.phone ?? '';
    _altMobileController.text = details.alternatePhone ?? '';
    _emailController.text = details.email ?? '';
    _salaryController.text = _formatAmountForEditing(details.salary);
    _incrementController.text = _formatAmountForEditing(
      details.incrementAmount,
    );
    _remarksController.text = details.description ?? '';
    setState(() {
      _joiningDate = details.joiningDate;
      _nextIncrementDate = details.incrementDate;
      _incrementReminder = details.incrementNotification ?? true;
      _leadManagement = details.leadModuleAccess ?? true;
      _existingPhotoUrl = details.photoUrl;
      _textFieldsPrefilled = true;
    });
  }

  /// Resolves [_branch]/[_role] from the fetched record once their source
  /// lists are available. Called from the listener on every relevant state
  /// change rather than once, because branches/roles and the staff record load
  /// independently and can land in either order; each check is a no-op once
  /// its target is already set, so repeat calls are harmless.
  void _tryPrefillSelections(StaffState state) {
    final StaffDetailsData? details = state.staffDetailsUIState?.data?.data;
    if (details == null) {
      return;
    }

    if (_branch == null && details.shopId != null) {
      final List<StoreResponseData> branches =
          state.branchesUIState?.data?.activeBranches ?? <StoreResponseData>[];
      for (final StoreResponseData branch in branches) {
        if (branch.id == details.shopId) {
          setState(() => _branch = branch);
          break;
        }
      }
    }

    if (_role == null && details.role != null) {
      final List<UserRoleOption> roles =
          state.userRolesUIState?.data?.selectableRoles ?? <UserRoleOption>[];
      for (final UserRoleOption role in roles) {
        if (role.value == details.role) {
          setState(() => _role = role);
          break;
        }
      }
    }
  }

  /// `"20000.00"` → `"20000"` for a text field: a trailing `.00` reads as
  /// clutter the user did not type, but a genuine fraction like `"1234.50"` is
  /// kept.
  String _formatAmountForEditing(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final double? value = double.tryParse(raw);
    if (value == null) {
      return raw;
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _altMobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _salaryController.dispose();
    _incrementController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// Camera or gallery, then straight into [_photo] so Save has a file to
  /// attach. [ImagePickerFrom] already toasts on a cancelled pick, an
  /// unsupported format or an oversized file, so a null result needs no
  /// message of its own.
  Future<void> _pickPhoto() async {
    FocusScope.of(context).unfocus();

    final String? source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return AppSelectSheet(
          title: AppString.label.selectImageFrom,
          options: <String>[
            AppString.label.fromCamera,
            AppString.label.fromGallery,
          ],
        );
      },
    );
    if (source == null) {
      return;
    }

    final PickedImageModel? picked = source == AppString.label.fromCamera
        ? await ImagePickerFrom.fromCamera()
        : await ImagePickerFrom.fromGallery();
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _photo = File(picked.path));
  }

  /// Amount fields are typed with a number keyboard but can still pick up
  /// grouping separators from a paste — the API wants a bare `numeric`.
  String _amountForApi(String value) =>
      value.replaceAll(RegExp(r'[^0-9.]'), '');

  /// Runs every rule the form has and paints the failures inline.
  ///
  /// Optional fields are only checked once the user has typed into them: an
  /// untouched alternate number is not an invalid one.
  bool _validate() {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;
    final String altMobile = _altMobileController.text.trim();
    final String email = _emailController.text.trim();
    final String salary = _salaryController.text.trim();
    final String incrementAmount = _incrementController.text.trim();
    // On edit, a blank pair means "keep the current password" — it is only
    // "provided" once either field has something in it, at which point both
    // become subject to the normal rules.
    final bool passwordProvided =
        !_isEditMode || password.isNotEmpty || confirmPassword.isNotEmpty;
    final bool passwordsMatch =
        !passwordProvided || confirmPassword == password;

    setState(() {
      _nameError = Validator.fieldRequired(
        _nameController.text.trim(),
        fieldName: 'Name',
      );
      _mobileError = Validator.phone(_mobileController.text.trim());
      _altMobileError = altMobile.isEmpty ? null : Validator.phone(altMobile);
      _emailError = email.isEmpty ? null : Validator.email(email);
      if (passwordProvided) {
        _passwordError = Validator.password(password);
        // A mismatch is left to StaffPasswordMatchHint, which is already
        // showing it live under the field — repeating it here would print it
        // twice.
        _confirmPasswordError = confirmPassword.isEmpty
            ? (_isEditMode
                  ? 'Confirm the new password'
                  : 'Confirm password is required')
            : null;
      } else {
        _passwordError = null;
        _confirmPasswordError = null;
      }
      _branchError = _branch?.id == null ? 'Branch is required' : null;
      _roleError = _role?.value == null ? 'Role is required' : null;
      _joiningDateError = _joiningDate == null
          ? 'Joining date is required'
          : null;
      // Required, and actually a number: the field takes a numeric keyboard but
      // a paste can still leave text behind, and `salary` is `numeric` on the
      // API — better to catch it here than to spend a round trip on a 422.
      _salaryError = Validator.fieldRequired(salary, fieldName: 'Salary');
      if (_salaryError == null && _amountForApi(salary).isEmpty) {
        _salaryError = 'Enter a valid salary';
      }
      _incrementAmountError =
          incrementAmount.isNotEmpty && _amountForApi(incrementAmount).isEmpty
          ? 'Enter a valid increment salary'
          : null;
    });

    final bool hasFieldError = <String?>[
      _nameError,
      _mobileError,
      _altMobileError,
      _emailError,
      _passwordError,
      _confirmPasswordError,
      _branchError,
      _roleError,
      _joiningDateError,
      _salaryError,
      _incrementAmountError,
    ].any((String? error) => error != null);

    return !hasFieldError && passwordsMatch;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      ToastMessages.alert(message: 'Please correct the highlighted fields');
      return;
    }

    final String email = _emailController.text.trim();
    final String altMobile = _altMobileController.text.trim();
    final String incrementAmount = _incrementController.text.trim();
    final String description = _remarksController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (_isEditMode) {
      final UpdateStaffApiRequest request = UpdateStaffApiRequest(
        name: _nameController.text.trim(),
        phone: _mobileController.text.trim(),
        shopId: _branch!.id!,
        role: _role!.value!,
        joiningDate: DateTimeHelper.getApiDateFormat(_joiningDate!),
        salary: _amountForApi(_salaryController.text.trim()),
        incrementNotification: _incrementReminder,
        leadModuleAccess: _leadManagement,
        email: email.isEmpty ? null : email,
        alternatePhone: altMobile.isEmpty ? null : altMobile,
        incrementDate: _nextIncrementDate == null
            ? null
            : DateTimeHelper.getApiDateFormat(_nextIncrementDate!),
        incrementAmount: incrementAmount.isEmpty
            ? null
            : _amountForApi(incrementAmount),
        description: description.isEmpty ? null : description,
        // Null keeps the existing photo — only a freshly picked file is sent.
        photo: _photo,
        // Blank means "leave the password unchanged"; `_validate` has already
        // confirmed the two match whenever either one was actually typed.
        password: password.isEmpty ? null : password,
        passwordConfirmation: password.isEmpty ? null : confirmPassword,
      );
      await context.read<StaffCubit>().updateStaff(widget.staffId!, request);
      return;
    }

    final CreateStaffApiRequest request = CreateStaffApiRequest(
      name: _nameController.text.trim(),
      phone: _mobileController.text.trim(),
      password: password,
      passwordConfirmation: confirmPassword,
      shopId: _branch!.id!,
      role: _role!.value!,
      joiningDate: DateTimeHelper.getApiDateFormat(_joiningDate!),
      salary: _amountForApi(_salaryController.text.trim()),
      incrementNotification: _incrementReminder,
      leadModuleAccess: _leadManagement,
      email: email.isEmpty ? null : email,
      alternatePhone: altMobile.isEmpty ? null : altMobile,
      incrementDate: _nextIncrementDate == null
          ? null
          : DateTimeHelper.getApiDateFormat(_nextIncrementDate!),
      incrementAmount: incrementAmount.isEmpty
          ? null
          : _amountForApi(incrementAmount),
      description: description.isEmpty ? null : description,
      photo: _photo,
    );

    await context.read<StaffCubit>().createStaff(request);
  }

  /// Reacts to the one terminal state per attempt — of whichever of create or
  /// update this instance is running — and, in edit mode, keeps trying to
  /// resolve the branch/role selections as their source lists arrive. Both
  /// terminal branches clear their state afterwards so the singleton cubit
  /// does not replay them on the next visit, or, on failure, leave the Save
  /// button stuck spinning.
  void _onStaffStateChanged(BuildContext context, StaffState state) {
    if (!mounted) {
      return;
    }

    if (_isEditMode) {
      final StaffDetailsData? details = state.staffDetailsUIState?.data?.data;
      if (details != null && !_textFieldsPrefilled) {
        _prefillFrom(details);
      }
      _tryPrefillSelections(state);
    }

    final Status? status = _isEditMode
        ? state.updateStaffUIState?.status
        : state.createStaffUIState?.status;

    switch (status) {
      case Status.SUCCESS:
        final String message = _isEditMode
            ? (state.updateStaffUIState?.data?.message ??
                  'Staff updated successfully.')
            : (state.createStaffUIState?.data?.message ??
                  'Staff created successfully.');
        ToastMessages.success(message: message);

        if (_isEditMode) {
          context.read<StaffCubit>().resetUpdateStaffState();
        } else {
          context.read<StaffCubit>().resetCreateStaffState();
        }

        if (!_isEditMode && widget.onStaffCreated != null) {
          widget.onStaffCreated!.call(state.createStaffUIState?.data);
        } else if (context.canPop()) {
          // GoRouter's pop, not the Navigator's: this screen was pushed with
          // `context.push`, and popping the raw Navigator underneath GoRouter
          // leaves its route stack believing this route is still up. The next
          // back gesture then runs `willPop()` against a scope that has
          // already been disposed — the `'scope != null'` assertion.
          //
          // `true` is enough of a payload: whoever awaited this push (Staff
          // Details, mainly) only needs to know that something was saved, not
          // what — it re-fetches its own copy either way.
          context.pop(true);
        } else {
          // Opened directly — a deep link, or a route restored on relaunch —
          // so there is nothing to go back to. Land on the list rather than on
          // a dead end.
          context.go(AppRouteName.staffList);
        }
      case Status.ERROR:
        // Laravel's 422 body is unpacked by ApiService into an ErrorWithMessage,
        // so a field-level validation failure arrives here as its own text.
        final ErrorType? errorType = _isEditMode
            ? state.updateStaffUIState?.errorType
            : state.createStaffUIState?.errorType;
        ToastMessages.error(
          message:
              errorType?.getText(context) ??
              'Could not save staff, Please try again later',
        );
        if (_isEditMode) {
          context.read<StaffCubit>().resetUpdateStaffState();
        } else {
          context.read<StaffCubit>().resetCreateStaffState();
        }
      case Status.LOADING:
      case Status.INITIAL:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: BlocConsumer<StaffCubit, StaffState>(
          // Branch/role loading emits too, and in edit mode so does the staff
          // details fetch — all three matter to `_onStaffStateChanged` (the
          // prefill), not just create/update finishing.
          listenWhen: (StaffState previous, StaffState current) =>
              previous.createStaffUIState?.status !=
                  current.createStaffUIState?.status ||
              previous.updateStaffUIState?.status !=
                  current.updateStaffUIState?.status ||
              previous.staffDetailsUIState?.status !=
                  current.staffDetailsUIState?.status ||
              previous.branchesUIState?.status !=
                  current.branchesUIState?.status ||
              previous.userRolesUIState?.status !=
                  current.userRolesUIState?.status,
          listener: _onStaffStateChanged,
          builder: (BuildContext context, StaffState state) {
            final UIState<StoreModelSuccess>? branchesState =
                state.branchesUIState;
            final bool isLoadingBranches =
                branchesState?.status == Status.LOADING;
            final List<StoreResponseData> branches =
                branchesState?.data?.activeBranches ?? <StoreResponseData>[];
            final bool isSubmitting = _isEditMode
                ? state.updateStaffUIState?.status == Status.LOADING
                : state.createStaffUIState?.status == Status.LOADING;

            // Edit mode only: the form has nothing to show until the record
            // arrives, so it replaces the whole body with a spinner or a
            // retry rather than rendering blank fields that then snap-fill.
            final bool isLoadingStaffDetails =
                _isEditMode &&
                !_textFieldsPrefilled &&
                state.staffDetailsUIState?.status == Status.LOADING;
            final bool staffDetailsFailed =
                _isEditMode &&
                !_textFieldsPrefilled &&
                state.staffDetailsUIState?.status == Status.ERROR;

            // A successful call with nothing selectable is as much a dead end
            // as a failed one, so both surface a message with a retry.
            final String? branchLoadError;
            if (branchesState?.status == Status.ERROR) {
              branchLoadError =
                  branchesState?.errorType?.getText(context) ??
                  'Could not load branches';
            } else if (branchesState?.status == Status.SUCCESS &&
                branches.isEmpty) {
              branchLoadError = 'No active branches available';
            } else {
              branchLoadError = null;
            }

            // Roles get the same treatment as branches: loaded from the API,
            // inert while loading, and offering a retry when the call fails or
            // comes back with nothing selectable.
            final UIState<UserRoleSuccess>? rolesState = state.userRolesUIState;
            final bool isLoadingRoles = rolesState?.status == Status.LOADING;
            final List<UserRoleOption> roles =
                rolesState?.data?.selectableRoles ?? <UserRoleOption>[];

            final String? roleLoadError;
            if (rolesState?.status == Status.ERROR) {
              roleLoadError =
                  rolesState?.errorType?.getText(context) ??
                  'Could not load roles';
            } else if (rolesState?.status == Status.SUCCESS && roles.isEmpty) {
              roleLoadError = 'No roles available';
            } else {
              roleLoadError = null;
            }

            return Column(
              children: <Widget>[
                AppGradientHeader(
                  title: _isEditMode ? 'Edit Staff' : 'Staff Creation',
                  eyebrow: 'TEAM',
                  leading: const AppBackButton(),
                  actions: const <Widget>[
                    AppHeaderIconButton(
                      icon: Icons.local_fire_department_rounded,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    AppAvatar(initials: 'AB'),
                  ],
                ),
                Expanded(
                  child: isLoadingStaffDetails
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.red,
                            ),
                          ),
                        )
                      : staffDetailsFailed
                      ? StaffListMessage(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load staff details',
                          message:
                              state.staffDetailsUIState?.errorType?.getText(
                                context,
                              ) ??
                              'Something went wrong. Please try again.',
                          actionLabel: 'Retry',
                          actionIcon: Icons.refresh_rounded,
                          onAction: () async => context
                              .read<StaffCubit>()
                              .getStaffDetails(widget.staffId!),
                        )
                      : ListView(
                          padding: EdgeInsets.only(
                            left: AppSpacing.gutter,
                            right: AppSpacing.gutter,
                            top: AppSpacing.md,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom +
                                AppSpacing.xl,
                          ),
                          children: <Widget>[
                            // One continuous form: the two groups are sections of the
                            // same page rather than tabs the user has to switch between.
                            AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const StaffSubsectionTitle(
                                    title: 'Personal Details',
                                  ),
                                  StaffPersonalDetailsForm(
                                    nameController: _nameController,
                                    mobileController: _mobileController,
                                    altMobileController: _altMobileController,
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    confirmPasswordController:
                                        _confirmPasswordController,
                                    photoPath: _photo?.path,
                                    networkPhotoUrl: _existingPhotoUrl,
                                    onPickPhoto: isSubmitting
                                        ? null
                                        : _pickPhoto,
                                    isEditMode: _isEditMode,
                                    nameError: _nameError,
                                    mobileError: _mobileError,
                                    altMobileError: _altMobileError,
                                    emailError: _emailError,
                                    passwordError: _passwordError,
                                    confirmPasswordError: _confirmPasswordError,
                                  ),
                                ],
                              ),
                            ),
                            AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const StaffSubsectionTitle(
                                    title: 'Employment Details',
                                  ),
                                  StaffEmploymentDetailsForm(
                                    salaryController: _salaryController,
                                    incrementController: _incrementController,
                                    remarksController: _remarksController,
                                    branches: branches,
                                    branch: _branch,
                                    isLoadingBranches: isLoadingBranches,
                                    branchLoadError: branchLoadError,
                                    onRetryBranches: () => context
                                        .read<StaffCubit>()
                                        .getBranches(force: true),
                                    onBranchChanged:
                                        (StoreResponseData value) =>
                                            setState(() {
                                              _branch = value;
                                              _branchError = null;
                                            }),
                                    roles: roles,
                                    role: _role,
                                    isLoadingRoles: isLoadingRoles,
                                    roleLoadError: roleLoadError,
                                    onRetryRoles: () => context
                                        .read<StaffCubit>()
                                        .getUserRoles(force: true),
                                    onRoleChanged: (UserRoleOption value) =>
                                        setState(() {
                                          _role = value;
                                          _roleError = null;
                                        }),
                                    joiningDate: _joiningDate,
                                    nextIncrementDate: _nextIncrementDate,
                                    reminderEnabled: _incrementReminder,
                                    onJoiningDateChanged: (DateTime value) =>
                                        setState(() {
                                          _joiningDate = value;
                                          _joiningDateError = null;
                                        }),
                                    onIncrementDateChanged: (DateTime value) =>
                                        setState(
                                          () => _nextIncrementDate = value,
                                        ),
                                    onReminderChanged: (bool value) => setState(
                                      () => _incrementReminder = value,
                                    ),
                                    branchError: _branchError,
                                    roleError: _roleError,
                                    joiningDateError: _joiningDateError,
                                    salaryError: _salaryError,
                                    incrementAmountError: _incrementAmountError,
                                  ),
                                ],
                              ),
                            ),
                            AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const StaffSubsectionTitle(title: 'Optional'),
                                  AppToggleRow(
                                    title: 'Lead Management',
                                    subtitle:
                                        'Allow this staff member to own leads',
                                    icon: Icons.groups_outlined,
                                    value: _leadManagement,
                                    onChanged: (bool value) =>
                                        setState(() => _leadManagement = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppPrimaryButton(
                              label: _isEditMode
                                  ? 'Update Staff'
                                  : 'Save Staff',
                              icon: Icons.save_outlined,
                              isLoading: isSubmitting,
                              onPressed: isSubmitting ? null : _handleSave,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const AppSectionHeader(
                                    title: 'Increment History',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  IncrementHistoryTable(records: _history),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Name, contact numbers and photo.
class StaffPersonalDetailsForm extends StatelessWidget {
  const StaffPersonalDetailsForm({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.altMobileController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.photoPath,
    this.networkPhotoUrl,
    this.onPickPhoto,
    this.isEditMode = false,
    this.nameError,
    this.mobileError,
    this.altMobileError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController altMobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? photoPath;

  /// The staff member's current photo, shown until a new one is picked.
  /// Always null on Staff Creation.
  final String? networkPhotoUrl;

  final VoidCallback? onPickPhoto;

  /// Edit Staff leaves the password fields optional — a blank pair means
  /// "keep the current password" — so their labels/hints say so rather than
  /// carrying the create screen's "required" copy verbatim.
  final bool isEditMode;

  final String? nameError;
  final String? mobileError;
  final String? altMobileError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFormField(
          label: 'Name',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: 'Enter full name',
                controller: nameController,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              StaffFieldError(message: nameError),
            ],
          ),
        ),
        AppFormField(
          label: 'Mobile No.',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: '98765 43210',
                controller: mobileController,
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              StaffFieldError(message: mobileError),
            ],
          ),
        ),
        AppFormField(
          label: 'Alternate Mobile No.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: '91234 56789',
                controller: altMobileController,
                icon: Icons.add_ic_call_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              StaffFieldError(message: altMobileError),
            ],
          ),
        ),
        AppFormField(
          label: 'Email',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: 'Enter email address',
                controller: emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              StaffFieldError(message: emailError),
            ],
          ),
        ),
        AppFormField(
          label: 'Password',
          isRequired: !isEditMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPasswordField(
                hint: isEditMode
                    ? 'Leave blank to keep current password'
                    : 'Enter password',
                controller: passwordController,
              ),
              StaffFieldError(message: passwordError),
            ],
          ),
        ),
        AppFormField(
          label: 'Confirm Password',
          isRequired: !isEditMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPasswordField(
                hint: 'Re-enter password',
                controller: confirmPasswordController,
              ),
              StaffPasswordMatchHint(
                passwordController: passwordController,
                confirmPasswordController: confirmPasswordController,
              ),
              StaffFieldError(message: confirmPasswordError),
            ],
          ),
        ),
        const AppFieldLabelRow(label: 'Photo'),
        StaffPhotoPicker(
          imagePath: photoPath,
          networkImageUrl: networkPhotoUrl,
          onEdit: onPickPhoto,
        ),
      ],
    );
  }
}

/// Tells the user the moment the two passwords stop matching.
///
/// Listens to both fields rather than rebuilding the whole form on every
/// keystroke, and stays silent until the confirmation has something in it —
/// an empty field is unfinished, not wrong.
class StaffPasswordMatchHint extends StatelessWidget {
  const StaffPasswordMatchHint({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        passwordController,
        confirmPasswordController,
      ]),
      builder: (BuildContext context, Widget? child) {
        final String confirm = confirmPasswordController.text;
        if (confirm.isEmpty) {
          return const SizedBox.shrink();
        }

        final bool matches = confirm == passwordController.text;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: <Widget>[
              Icon(
                matches
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 14,
                color: matches ? Colors.green.shade600 : AppColors.red,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  matches ? 'Passwords match' : 'Passwords do not match',
                  style: context.type.caption.copyWith(
                    color: matches ? Colors.green.shade700 : AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thin wrapper so the photo label matches every other field caption.
class AppFieldLabelRow extends StatelessWidget {
  const AppFieldLabelRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(label, style: context.type.label),
    );
  }
}

/// Joining date, salary and the increment schedule.
class StaffEmploymentDetailsForm extends StatelessWidget {
  const StaffEmploymentDetailsForm({
    super.key,
    required this.salaryController,
    required this.incrementController,
    required this.remarksController,
    required this.branches,
    required this.branch,
    required this.roles,
    required this.role,
    required this.joiningDate,
    required this.nextIncrementDate,
    required this.reminderEnabled,
    this.isLoadingBranches = false,
    this.branchLoadError,
    this.onRetryBranches,
    this.isLoadingRoles = false,
    this.roleLoadError,
    this.onRetryRoles,
    this.onBranchChanged,
    this.onRoleChanged,
    this.onJoiningDateChanged,
    this.onIncrementDateChanged,
    this.onReminderChanged,
    this.branchError,
    this.roleError,
    this.joiningDateError,
    this.salaryError,
    this.incrementAmountError,
  });

  final TextEditingController salaryController;
  final TextEditingController incrementController;
  final TextEditingController remarksController;

  /// Active branches from `GET /api/branches`. The picker shows `name` and the
  /// screen keeps the record so Save can send `id` as `shop_id`.
  final List<StoreResponseData> branches;
  final StoreResponseData? branch;
  final ValueChanged<StoreResponseData>? onBranchChanged;
  final bool isLoadingBranches;
  final String? branchLoadError;
  final VoidCallback? onRetryBranches;

  /// Roles from `GET /api/user-roles`. The picker shows each `label` and the
  /// screen keeps the record so Save can send its `value` as `role`.
  final List<UserRoleOption> roles;
  final UserRoleOption? role;
  final ValueChanged<UserRoleOption>? onRoleChanged;
  final bool isLoadingRoles;
  final String? roleLoadError;
  final VoidCallback? onRetryRoles;
  final DateTime? joiningDate;
  final DateTime? nextIncrementDate;
  final bool reminderEnabled;
  final ValueChanged<DateTime>? onJoiningDateChanged;
  final ValueChanged<DateTime>? onIncrementDateChanged;
  final ValueChanged<bool>? onReminderChanged;
  final String? branchError;
  final String? roleError;
  final String? joiningDateError;
  final String? salaryError;
  final String? incrementAmountError;

  /// Maps the picked name back to its record. `AppSelectField` speaks in
  /// strings, and the id is the only thing the API accepts.
  void _handleBranchPicked(String name) {
    final int index = branches.indexWhere(
      (StoreResponseData item) => item.name == name,
    );
    if (index != -1) {
      onBranchChanged?.call(branches[index]);
    }
  }

  /// Same mapping for roles: the sheet returns a label, the API wants `value`.
  void _handleRolePicked(String label) {
    final int index = roles.indexWhere(
      (UserRoleOption item) => item.displayLabel == label,
    );
    if (index != -1) {
      onRoleChanged?.call(roles[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A null onChanged makes AppSelectField inert, which is exactly what an
    // empty or still-loading branch list should be.
    final bool canPickBranch =
        !isLoadingBranches && branches.isNotEmpty && onBranchChanged != null;
    final bool canPickRole =
        !isLoadingRoles && roles.isNotEmpty && onRoleChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFormField(
          label: 'Branch',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSelectField(
                hint: isLoadingBranches ? 'Loading branches…' : 'Select branch',
                sheetTitle: 'Assign to branch',
                icon: Icons.storefront_outlined,
                options: branches
                    .map((StoreResponseData item) => item.name ?? '')
                    .toList(),
                value: branch?.name,
                onChanged: canPickBranch ? _handleBranchPicked : null,
              ),
              if (branchLoadError != null)
                StaffBranchLoadError(
                  message: branchLoadError!,
                  onRetry: onRetryBranches,
                )
              else
                StaffFieldError(message: branchError),
            ],
          ),
        ),
        AppFormField(
          label: 'Role',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSelectField(
                hint: isLoadingRoles ? 'Loading roles…' : 'Select role',
                sheetTitle: 'Staff role',
                icon: Icons.badge_outlined,
                options: roles
                    .map((UserRoleOption item) => item.displayLabel)
                    .toList(),
                value: role?.displayLabel,
                onChanged: canPickRole ? _handleRolePicked : null,
              ),
              if (roleLoadError != null)
                StaffBranchLoadError(
                  message: roleLoadError!,
                  onRetry: onRetryRoles,
                )
              else
                StaffFieldError(message: roleError),
            ],
          ),
        ),
        AppFormField(
          label: 'Joining Date',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppDateField(
                hint: 'Select joining date',
                value: joiningDate,
                onChanged: onJoiningDateChanged,
              ),
              StaffFieldError(message: joiningDateError),
            ],
          ),
        ),
        AppFormField(
          label: 'Salary',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: '25,000',
                controller: salaryController,
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
              ),
              StaffFieldError(message: salaryError),
            ],
          ),
        ),
        const StaffSubsectionTitle(title: 'Increment Details', showInfo: true),
        AppFormField(
          label: 'Next Increment Date',
          child: AppDateField(
            hint: 'Select next increment date',
            value: nextIncrementDate,
            onChanged: onIncrementDateChanged,
          ),
        ),
        AppToggleRow(
          title: 'Increment Reminder',
          subtitle: 'Notify me when the increment date arrives',
          icon: Icons.notifications_active_outlined,
          value: reminderEnabled,
          onChanged: onReminderChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        AppFormField(
          label: 'Increment Salary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                hint: '2,500',
                controller: incrementController,
                icon: Icons.trending_up_rounded,
                keyboardType: TextInputType.number,
              ),
              StaffFieldError(message: incrementAmountError),
            ],
          ),
        ),
        AppFormField(
          label: 'Description',
          bottomSpacing: AppSpacing.md,
          child: AppTextField(
            hint: 'Annual increment based on performance and company policy.',
            controller: remarksController,
            icon: Icons.notes_rounded,
            maxLines: 3,
            maxLength: 250,
            showCounter: true,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        AppOutlineButton(
          label: 'View Increment History',
          icon: Icons.history_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}
