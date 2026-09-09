import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/authentication/cubit/change_password/change_password_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/authentication/repository/auth_repository.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_field_label.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:nimmys_crm/shared/widgets/app_section_card.dart';
import 'package:nimmys_crm/shared/widgets/app_text_field.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'package:nimmys_crm/utils/validator.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ChangePasswordCubit>().changePassword(
      currentPassword: _currentPasswordController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmationController.text,
    );
  }

  Future<void> _signOutAfterPasswordChange() async {
    await locator<AuthRepository>().signOut();
    locator<SessionCubit>().clearSession();
    locator<ProfileCubit>().resetProfileState();
    locator<StaffCubit>().resetStaffState();
    locator<LeadsCubit>().resetLeadsState();
    locator<DashboardCubit>().resetDashboardState();
    locator<TasksCubit>().resetTasksState();
    if (mounted) context.go(AppRouteName.signIn);
  }

  void _onStateChanged(BuildContext context, ChangePasswordState state) {
    final result = state.changePasswordUIState;
    if (result?.status == Status.SUCCESS) {
      context.read<ChangePasswordCubit>().reset();
      ToastMessages.success(
        message: result?.data?.message ??
            'Password changed. Please sign in with your new password.',
      );
      _signOutAfterPasswordChange();
    } else if (result?.status == Status.ERROR) {
      ToastMessages.error(
        message: result?.errorType?.getText(context) ??
            'Unable to change password. Please try again.',
      );
      context.read<ChangePasswordCubit>().reset();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.canvas,
    body: SafeArea(
      top: false,
      child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listenWhen: (previous, current) =>
            previous.changePasswordUIState?.status !=
            current.changePasswordUIState?.status,
        listener: _onStateChanged,
        builder: (context, state) {
          final isLoading =
              state.changePasswordUIState?.status == Status.LOADING;
          return Column(children: <Widget>[
            const AppGradientHeader(
              title: 'Change Password',
              eyebrow: 'ACCOUNT SECURITY',
              leading: AppBackButton(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Form(
                  key: _formKey,
                  child: AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text('Keep your account secure',
                            style: context.type.cardTitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'You will be signed out after changing your password.',
                          style: context.type.bodyMuted,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const AppFieldLabel(text: 'Current password', isRequired: true),
                        AppPasswordField(
                          hint: 'Enter current password',
                          controller: _currentPasswordController,
                          validator: (value) => Validator.fieldRequired(
                            value,
                            fieldName: 'Current password',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const AppFieldLabel(text: 'New password', isRequired: true),
                        AppPasswordField(
                          hint: 'At least 6 characters',
                          controller: _passwordController,
                          validator: Validator.password,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const AppFieldLabel(text: 'Confirm new password', isRequired: true),
                        AppPasswordField(
                          hint: 'Re-enter new password',
                          controller: _confirmationController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            return value == _passwordController.text
                                ? null
                                : 'Passwords do not match';
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppPrimaryButton(
                          label: 'CHANGE PASSWORD',
                          icon: Icons.lock_reset_rounded,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    ),
  );
}
