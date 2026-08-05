import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/preferences/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_field_label.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/theme_toggle_button.dart';

/// Email + password sign-in.
///
/// Black brand stage up top, white credential card below. Validation and auth
/// are intentionally left to the host app — this is presentation only.
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Restore the remembered address so returning users only type a password.
    if (AppPreferences.isReady) {
      final AppPreferences prefs = AppPreferences.instance;
      _rememberMe = prefs.rememberMe;
      if (_rememberMe) {
        _emailController.text = prefs.savedEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    if (!AppPreferences.isReady) {
      return;
    }
    final AppPreferences prefs = AppPreferences.instance;
    await prefs.setRememberMe(value);
    if (!value) {
      await prefs.clearSavedEmail();
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    if (AppPreferences.isReady) {
      final AppPreferences prefs = AppPreferences.instance;
      await prefs.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await prefs.setSavedEmail(_emailController.text.trim());
      } else {
        await prefs.clearSavedEmail();
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    widget.onSignedIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: <Widget>[
            const LoginBrandStage(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.xl,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const LoginWelcomeText(),
                    const SizedBox(height: AppSpacing.xl),
                    const AppFieldLabel(text: 'Email', isRequired: true),
                    AppTextField(
                      hint: 'you@nimmys.com',
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppFieldLabel(text: 'Password', isRequired: true),
                    AppPasswordField(
                      hint: 'Enter your password',
                      controller: _passwordController,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LoginOptionsRow(
                      rememberMe: _rememberMe,
                      onRememberChanged: _setRememberMe,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'LOGIN',
                      icon: Icons.login_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const LoginSecurityNote(),
                    const SizedBox(height: AppSpacing.lg),
                    const LoginAppearanceSection(),
                    const SizedBox(height: AppSpacing.lg),
                    const LoginFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Black curved hero holding the logo above the credential form.
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
          children: <Widget>[
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
              children: <Widget>[
                const AppLogo(height: 52),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    'CRM WORKSPACE',
                    style: context.type.splashTagline.copyWith(
                      fontSize: 10,
                      letterSpacing: 2.4,
                    ),
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

/// Sweeping bottom edge for the login hero.
class LoginStageClipper extends CustomClipper<Path> {
  const LoginStageClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..lineTo(0, size.height - 46)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 26,
        size.width,
        size.height - 46,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Greeting copy above the fields.
class LoginWelcomeText extends StatelessWidget {
  const LoginWelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 22,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Text('Welcome back', style: context.type.pageHeading),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            'Sign in to manage your leads, duties and follow ups.',
            style: context.type.bodyMuted,
          ),
        ),
      ],
    );
  }
}

/// "Remember me" checkbox paired with the forgot-password link.
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
      children: <Widget>[
        SizedBox(
          width: 32,
          height: 32,
          child: Checkbox(
            value: rememberMe,
            onChanged: (bool? value) => onRememberChanged?.call(value ?? false),
            activeColor: AppColors.red,
            checkColor: AppColors.white,
            side: BorderSide(color: context.palette.inkBorder, width: 1.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
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
          child: Text('Forgot password?', style: context.type.link),
        ),
      ],
    );
  }
}

/// Reassurance strip beneath the login button.
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
        children: <Widget>[
          const Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: AppColors.red,
          ),
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

/// Lets the user pick light / dark / system before signing in.
///
/// The choice is written straight to shared preferences, so it survives
/// restarts and applies to every screen.
class LoginAppearanceSection extends StatelessWidget {
  const LoginAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.palette_outlined,
              size: 15,
              color: context.palette.muted,
            ),
            const SizedBox(width: 6),
            Text('Appearance', style: context.type.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const ThemeModeSelector(),
      ],
    );
  }
}

/// Support line at the bottom of the login screen.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: <Widget>[
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
          style: context.type.caption.copyWith(
            fontSize: 11,
            color: context.palette.faint,
          ),
        ),
      ],
    );
  }
}
