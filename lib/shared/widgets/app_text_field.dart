import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// Standard bordered input used by every form in the app.
///
/// Focus is expressed with the brand red on both the border and the leading
/// icon so the active field is unmistakable in either theme.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showCounter = false,
  });

  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Shows a live `used/max` counter beneath the field.
  final bool showCounter;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isMultiline = widget.maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.enabled ? palette.surfaceAlt : palette.inkWash,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _isFocused ? AppColors.red : palette.line,
              width: _isFocused ? 1.4 : 1,
            ),
            boxShadow: _isFocused
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: isMultiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.only(
                    right: AppSpacing.xs,
                    top: isMultiline ? 14 : 0,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 19,
                    color: _isFocused ? AppColors.red : palette.faint,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  style: context.type.input,
                  cursorColor: AppColors.red,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: context.type.hint,
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isMultiline ? 14 : 15,
                    ),
                  ),
                ),
              ),
              ?widget.suffix,
            ],
          ),
        ),
        if (widget.showCounter && widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 2),
            child: AppFieldCounter(
              controller: widget.controller,
              maxLength: widget.maxLength!,
            ),
          ),
      ],
    );
  }
}

/// Live `0/500` counter rendered under a character-limited field.
class AppFieldCounter extends StatelessWidget {
  const AppFieldCounter({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController? controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Text('0/$maxLength', style: context.type.caption);
    }
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        return Text(
          '${value.text.characters.length}/$maxLength',
          style: context.type.caption,
        );
      },
    );
  }
}

/// Password field with an inline show/hide toggle.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.hint,
    this.controller,
    this.icon = Icons.lock_outline_rounded,
  });

  final String hint;
  final TextEditingController? controller;
  final IconData icon;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: widget.hint,
      controller: widget.controller,
      icon: widget.icon,
      obscureText: _isHidden,
      keyboardType: TextInputType.visiblePassword,
      suffix: IconButton(
        onPressed: () => setState(() => _isHidden = !_isHidden),
        icon: Icon(
          _isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: context.palette.muted,
        ),
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        tooltip: _isHidden ? 'Show password' : 'Hide password',
      ),
    );
  }
}
