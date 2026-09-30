import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A premium custom text form field that supports micro-interactions on focus,
/// including a smooth border color transition and a soft glow/shadow effect.
class AppTextField extends StatefulWidget {
  /// The floating label text.
  final String labelText;

  /// Optional placeholder/hint text.
  final String? hintText;

  /// Optional text controller.
  final TextEditingController? controller;

  /// Optional validator callback.
  final String? Function(String?)? validator;

  /// Optional initial value.
  final String? initialValue;

  /// The keyboard type.
  final TextInputType keyboardType;

  /// Whether text is obscured.
  final bool obscureText;

  /// Optional icon placed at the start of the field.
  final Widget? prefixIcon;

  /// Optional icon placed at the end of the field.
  final Widget? suffixIcon;

  /// Optional change callback.
  final void Function(String)? onChanged;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Creates an [AppTextField].
  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFieldReadOnly = widget.readOnly;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppDimensions.functionalBorderRadius,
        boxShadow: _isFocused && !isFieldReadOnly
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                 ),
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        validator: widget.validator,
        initialValue: widget.initialValue,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        onChanged: widget.onChanged,
        readOnly: isFieldReadOnly,
        enableInteractiveSelection: !isFieldReadOnly,
        style: AppTypography.bodyMedium.copyWith(
          color: isFieldReadOnly ? AppColors.textSecondary : AppColors.primary,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: isFieldReadOnly ? AppColors.surfaceContainer : Colors.white,
          border: OutlineInputBorder(
            borderRadius: AppDimensions.functionalBorderRadius,
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppDimensions.functionalBorderRadius,
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppDimensions.functionalBorderRadius,
            borderSide: BorderSide(
              color: isFieldReadOnly ? AppColors.border : AppColors.primary,
              width: isFieldReadOnly ? 1.0 : 1.5,
            ),
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: (_isFocused && !isFieldReadOnly) ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
