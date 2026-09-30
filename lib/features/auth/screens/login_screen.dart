import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

/// Fully-styled pre-auth Login Screen.
///
/// Features centered branding, username/password form card with focus glow,
/// and a primary pill Sign In button.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _errorMessage = null);
      try {
        await ref
            .read(authProvider.notifier)
            .login(_usernameController.text.trim(), _passwordController.text);
        AppRouter.refreshAuthState();
        if (mounted) {
          context.go('/dashboard');
        }
      } catch (error) {
        if (mounted) {
          setState(() => _errorMessage = _messageFor(error));
        }
      }
    }
  }

  String _messageFor(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.isEmpty) {
      return 'Login failed. Please try again.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.mobileGutter),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header Title
                Text(
                  'GENSET',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.modalRadius,
                    ),
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: AppColors.shadowSoft,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Text(
                          'ACCESS',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use your username and password to continue.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username Field
                        _StyledTextField(
                          label: 'Username',
                          id: 'username',
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 24),

                        // Password Field
                        _StyledTextField(
                          label: 'Password',
                          id: 'password',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.danger,
                                  width: 4,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.functionalRadius,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Sign In Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatefulWidget {
  final String label;
  final String id;
  final bool obscureText;
  final TextEditingController controller;

  const _StyledTextField({
    required this.label,
    required this.id,
    this.obscureText = false,
    required this.controller,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
            border: Border.all(
              color: _isFocused ? AppColors.primary : AppColors.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
            child: TextFormField(
              key: Key('input_${widget.id}'),
              focusNode: _focusNode,
              controller: widget.controller,
              obscureText: widget.obscureText,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return ''; // empty to keep it compact
                }
                return null;
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorStyle: TextStyle(
                  height: 0,
                  fontSize: 0,
                ), // hide error text
              ),
            ),
          ),
        ),
      ],
    );
  }
}
