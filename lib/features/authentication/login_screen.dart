import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update_flutter/in_app_update_flutter.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../enum/status.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_field_label.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../utils/toast_messages.dart';
import '../../utils/validator.dart';
import '../profile/cubit/profile/profile_cubit.dart';
import 'api_request/login_api_request.dart';
import 'cubit/login/login_cubit.dart';
import 'cubit/session/session_cubit.dart';

/// Email + password sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _emailError;
  String? _passwordError;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    if (AppPreferences.isReady) {
      final AppPreferences prefs = AppPreferences.instance;
      _rememberMe = prefs.rememberMe;
      if (_rememberMe) {
        _emailController.text = prefs.savedEmail;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LoginCubit>().resetLoginState();
        context.read<LoginCubit>().resetForgotPasswordState();
        _checkForUpdate();
        _getFcmToken();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (mounted) setState(() => _fcmToken = token);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    if (!AppPreferences.isReady) return;
    final AppPreferences prefs = AppPreferences.instance;
    await prefs.setRememberMe(value);
    if (!value) await prefs.clearSavedEmail();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updater = InAppUpdateFlutter();
      if (Platform.isAndroid) {
        final info = await updater.checkUpdateAndroid();
        if (info.updateAvailability == UpdateAvailabilityAndroid.updateAvailable &&
            info.isImmediateUpdateAllowed) {
          await updater.startImmediateUpdateAndroid();
        }
      } else if (Platform.isIOS) {
        await updater.showUpdateForIos(appStoreId: 'YOUR_APP_STORE_ID');
      }
    } catch (e, stack) {
      debugPrint('App update check failed: $e\n$stack');
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    setState(() {
      _emailError = Validator.email(email);
      _passwordError = Validator.fieldRequired(password, fieldName: 'Password');
    });
    if (_emailError != null || _passwordError != null) return;

    if (AppPreferences.isReady) {
      final AppPreferences prefs = AppPreferences.instance;
      await prefs.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await prefs.setSavedEmail(email);
      } else {
        await prefs.clearSavedEmail();
      }
    }

    if (!mounted) return;
    await context.read<LoginCubit>().login(
          LoginApiRequest(
            email: email,
            password: password,
            fcm_token: _fcmToken ?? '',
          ),
        );
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final error = Validator.email(email);
    if (error != null) {
      ToastMessages.error(message: error);
      return;
    }

    if (!mounted) return;
    context.read<LoginCubit>().forgotPassword(email);
  }

  void _showForgotPasswordToast(LoginState state) {
    final forgotState = state.forgotPasswordUIState;
    if (forgotState == null) return;

    switch (forgotState.status) {
      case Status.SUCCESS:
        ToastMessages.success(
          message: forgotState.data?.message ?? 'Reset link sent successfully.',
        );
        context.read<LoginCubit>().resetForgotPasswordState();
        break;
      case Status.ERROR:
        ToastMessages.error(
          message: forgotState.errorType?.getText(context) ??
              'Failed to send reset link. Please try again.',
        );
        context.read<LoginCubit>().resetForgotPasswordState();
        break;
      default:
        break;
    }
  }

  void _onLoginStateChanged(BuildContext context, LoginState state) {
    // Handle login terminal states
    switch (state.loginUIState?.status) {
      case Status.SUCCESS:
        final String name = state.loginUIState?.data?.user?.name ?? '';
        ToastMessages.success(
          message: name.isEmpty ? 'Login successful' : 'Welcome back, $name',
        );
        final AppPreferences prefs = AppPreferences.instance;
        prefs.setUserId(state.loginUIState?.data?.user?.id ?? 1);
        context.read<ProfileCubit>().resetProfileState();
        context.read<SessionCubit>().loadSession();
        if (mounted) widget.onSignedIn?.call();
        break;
      case Status.ERROR:
        ToastMessages.error(
          message: state.loginUIState?.errorType?.getText(context) ??
              'Login attempt unsuccessful, Please try again later',
        );
        break;
      default:
        break;
    }

    // Handle forgot password terminal states
    _showForgotPasswordToast(state);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<LoginCubit, LoginState>(
          listener: _onLoginStateChanged,
          builder: (BuildContext context, LoginState state) {
            final bool isLoginLoading = state.loginUIState?.status == Status.LOADING;
            final bool isForgotLoading = state.forgotPasswordUIState?.status == Status.LOADING;

            return Column(
              children: [
                const LoginBrandStage(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.xl,
                      bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LoginWelcomeText(),
                        const SizedBox(height: AppSpacing.xl),

                        // Linear loader for forgot password
                        if (isForgotLoading)
                          const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: AppColors.red,
                          ),

                        const AppFieldLabel(text: 'Email', isRequired: true),
                        AppTextField(
                          hint: 'you@nimmys.com',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoginLoading && !isForgotLoading,
                        ),
                        LoginFieldError(message: _emailError),
                        const SizedBox(height: AppSpacing.md),

                        const AppFieldLabel(text: 'Password', isRequired: true),
                        AppPasswordField(
                          hint: 'Enter your password',
                          controller: _passwordController,
                        ),
                        LoginFieldError(message: _passwordError),
                        const SizedBox(height: AppSpacing.xs),

                        LoginOptionsRow(
                          rememberMe: _rememberMe,
                          onRememberChanged: _setRememberMe,
                          onForgotPassword: _handleForgotPassword,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        AppPrimaryButton(
                          label: 'LOGIN',
                          icon: Icons.login_rounded,
                          isLoading: isLoginLoading,
                          onPressed: (isLoginLoading || isForgotLoading) ? null : _handleLogin,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        const LoginSecurityNote(),
                        const SizedBox(height: AppSpacing.lg),
                        const LoginFooter(),
                      ],
                    ),
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

// ---------- (all the stateless widgets remain exactly as before) ----------

class LoginFieldError extends StatelessWidget {
  const LoginFieldError({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.red),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message!,
              style: context.type.caption.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginBrandStage extends StatelessWidget {
  const LoginBrandStage({super.key});

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: const LoginStageClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: topInset + AppSpacing.xxl,
          bottom: AppSpacing.huge,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
        ),
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.16),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(height: 52),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    'CRM WORKSPACE',
                    style: context.type.splashTagline.copyWith(fontSize: 10, letterSpacing: 2.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginStageClipper extends CustomClipper<Path> {
  const LoginStageClipper();
  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..lineTo(0, size.height - 46)
      ..quadraticBezierTo(size.width * 0.5, size.height + 26, size.width, size.height - 46)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LoginWelcomeText extends StatelessWidget {
  const LoginWelcomeText({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            Text('Welcome back', style: context.type.pageHeading),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'Sign in to manage your leads, duties and follow ups.',
            style: context.type.bodyMuted,
          ),
        ),
      ],
    );
  }
}

class LoginOptionsRow extends StatelessWidget {
  const LoginOptionsRow({
    super.key,
    required this.rememberMe,
    this.onRememberChanged,
    this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool>? onRememberChanged;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Checkbox(
            value: rememberMe,
            onChanged: (bool? value) => onRememberChanged?.call(value ?? false),
            activeColor: AppColors.red,
            checkColor: AppColors.white,
            side: BorderSide(color: context.palette.inkBorder, width: 1.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            'Remember me',
            style: context.type.bodyMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onForgotPassword,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.red,
          ),
          child: Text(
            'Forgot password?',
            style: context.type.link.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class LoginSecurityNote extends StatelessWidget {
  const LoginSecurityNote({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.palette.redWashSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.redBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.red),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Your session is encrypted. Never share your password with anyone.',
              style: context.type.caption.copyWith(color: context.palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            Text('Trouble signing in?', style: context.type.caption),
            Text(
              'Contact admin',
              style: context.type.link.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '© nimmys camera centre',
          style: context.type.caption.copyWith(fontSize: 11, color: context.palette.faint),
        ),
      ],
    );
  }
}