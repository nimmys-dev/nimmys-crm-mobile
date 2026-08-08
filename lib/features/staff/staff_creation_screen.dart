import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
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
import 'cubit/staff/staff_cubit.dart';
import 'model/create_staffsuccess_model.dart';
import 'model/staff_role.dart';
import 'model/store_success_model.dart';
import 'widgets/staff_widgets.dart';

/// Staff Creation — personal profile plus employment and increment settings.
///
/// Branches come from `GET /api/branches` and the form posts to
/// `POST /api/create-staff` through [StaffCubit].
class StaffCreationScreen extends StatefulWidget {
  const StaffCreationScreen({super.key, this.onStaffCreated});

  /// Called once the API has accepted the new staff member, with the full
  /// response — `message` for a toast, `data` for the created record. Screens
  /// that own a staff list pass a callback here to refresh themselves; when it
  /// is null the screen pops and hands the same response back as the route
  /// result, so an `await context.push(...)` can do the same thing.
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
  String? _role;
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

  @override
  void initState() {
    super.initState();
    // The cubit is a singleton, so a previous visit's SUCCESS/ERROR would still
    // be sitting in state and fire the listener the moment this screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffCubit>()
          ..resetCreateStaffState()
          ..getBranches();
      }
    });
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
    final bool passwordsMatch = confirmPassword == password;

    setState(() {
      _nameError = Validator.fieldRequired(
        _nameController.text.trim(),
        fieldName: 'Name',
      );
      _mobileError = Validator.phone(_mobileController.text.trim());
      _altMobileError = altMobile.isEmpty ? null : Validator.phone(altMobile);
      _emailError = email.isEmpty ? null : Validator.email(email);
      _passwordError = Validator.password(password);
      // A mismatch is left to StaffPasswordMatchHint, which is already showing
      // it live under the field — repeating it here would print it twice.
      _confirmPasswordError =
          confirmPassword.isEmpty ? 'Confirm password is required' : null;
      _branchError = _branch?.id == null ? 'Branch is required' : null;
      _roleError = _role == null ? 'Role is required' : null;
      _joiningDateError = _joiningDate == null ? 'Joining date is required' : null;
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

    final CreateStaffApiRequest request = CreateStaffApiRequest(
      name: _nameController.text.trim(),
      phone: _mobileController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      shopId: _branch!.id!,
      role: StaffRoles.apiValue(_role),
      joiningDate: DateTimeHelper.getApiDateFormat(_joiningDate!),
      salary: _amountForApi(_salaryController.text.trim()),
      incrementNotification: _incrementReminder,
      leadModuleAccess: _leadManagement,
      email: email.isEmpty ? null : email,
      alternatePhone: altMobile.isEmpty ? null : altMobile,
      incrementDate: _nextIncrementDate == null
          ? null
          : DateTimeHelper.getApiDateFormat(_nextIncrementDate!),
      incrementAmount:
          incrementAmount.isEmpty ? null : _amountForApi(incrementAmount),
      description: description.isEmpty ? null : description,
      photo: _photo,
    );

    await context.read<StaffCubit>().createStaff(request);
  }

  /// Reacts to the one terminal state per attempt. Both branches clear the
  /// state afterwards so the singleton cubit does not replay it on the next
  /// visit — or, on failure, keep the Save button spinning.
  void _onCreateStaffStateChanged(BuildContext context, StaffState state) {
    final UIState<CreateStaffSuccess>? uiState = state.createStaffUIState;
    switch (uiState?.status) {
      case Status.SUCCESS:
        final CreateStaffSuccess? response = uiState?.data;
        ToastMessages.success(
          message: response?.message ?? 'Staff created successfully.',
        );
        context.read<StaffCubit>().resetCreateStaffState();
        if (widget.onStaffCreated != null) {
          widget.onStaffCreated!.call(response);
        } else if (Navigator.of(context).canPop()) {
          // Back to whatever opened this — normally the staff list, which the
          // cubit has already put a refresh in flight for. The whole response
          // rather than just `data`: it is never null on success, so a caller
          // can treat "popped something" as "a staff member was created".
          Navigator.of(context).pop(response);
        } else {
          // Opened directly — a deep link, or a route restored on relaunch —
          // so there is nothing to go back to. Land on the list rather than on
          // a dead end.
          context.go(AppRouteName.staffList);
        }
      case Status.ERROR:
        // Laravel's 422 body is unpacked by ApiService into an ErrorWithMessage,
        // so a field-level validation failure arrives here as its own text.
        ToastMessages.error(
          message: uiState?.errorType?.getText(context) ??
              'Could not create staff, Please try again later',
        );
        context.read<StaffCubit>().resetCreateStaffState();
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
          // Branch loading emits too, and it must not replay the create-staff
          // toast every time it does.
          listenWhen: (StaffState previous, StaffState current) =>
              previous.createStaffUIState?.status !=
              current.createStaffUIState?.status,
          listener: _onCreateStaffStateChanged,
          builder: (BuildContext context, StaffState state) {
            final UIState<StoreModelSuccess>? branchesState =
                state.branchesUIState;
            final bool isLoadingBranches =
                branchesState?.status == Status.LOADING;
            final List<StoreResponseData> branches =
                branchesState?.data?.activeBranches ?? <StoreResponseData>[];
            final bool isSubmitting =
                state.createStaffUIState?.status == Status.LOADING;

            // A successful call with nothing selectable is as much a dead end
            // as a failed one, so both surface a message with a retry.
            final String? branchLoadError;
            if (branchesState?.status == Status.ERROR) {
              branchLoadError = branchesState?.errorType?.getText(context) ??
                  'Could not load branches';
            } else if (branchesState?.status == Status.SUCCESS &&
                branches.isEmpty) {
              branchLoadError = 'No active branches available';
            } else {
              branchLoadError = null;
            }

            return Column(
              children: <Widget>[
                const AppGradientHeader(
                  title: 'Staff Creation',
                  eyebrow: 'TEAM',
                  leading: AppBackButton(),
                  actions: <Widget>[
                    AppHeaderIconButton(
                      icon: Icons.local_fire_department_rounded,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    AppAvatar(initials: 'AB'),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.gutter,
                      right: AppSpacing.gutter,
                      top: AppSpacing.md,
                      bottom: MediaQuery.of(context).viewInsets.bottom +
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
                              onPickPhoto: isSubmitting ? null : _pickPhoto,
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
                              onBranchChanged: (StoreResponseData value) =>
                                  setState(() {
                                    _branch = value;
                                    _branchError = null;
                                  }),
                              roles: StaffRoles.options,
                              role: _role,
                              onRoleChanged: (String value) => setState(() {
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
                                  setState(() => _nextIncrementDate = value),
                              onReminderChanged: (bool value) =>
                                  setState(() => _incrementReminder = value),
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
                              subtitle: 'Allow this staff member to own leads',
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
                        label: 'Save Staff',
                        icon: Icons.save_outlined,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : _handleSave,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const AppSectionHeader(title: 'Increment History'),
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
    this.onPickPhoto,
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
  final VoidCallback? onPickPhoto;
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
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPasswordField(
                hint: 'Enter password',
                controller: passwordController,
              ),
              StaffFieldError(message: passwordError),
            ],
          ),
        ),
        AppFormField(
          label: 'Confirm Password',
          isRequired: true,
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
        StaffPhotoPicker(imagePath: photoPath, onEdit: onPickPhoto),
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
  final List<String> roles;
  final String? role;
  final ValueChanged<String>? onRoleChanged;
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

  @override
  Widget build(BuildContext context) {
    // A null onChanged makes AppSelectField inert, which is exactly what an
    // empty or still-loading branch list should be.
    final bool canPickBranch =
        !isLoadingBranches && branches.isNotEmpty && onBranchChanged != null;

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
                hint: 'Select role',
                sheetTitle: 'Staff role',
                icon: Icons.badge_outlined,
                options: roles,
                value: role,
                onChanged: onRoleChanged,
              ),
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
