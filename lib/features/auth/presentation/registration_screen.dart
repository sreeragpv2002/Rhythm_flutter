import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/utils/app_utils.dart';
import 'package:rhythm_flutter/core/widgets/app_button.dart';
import 'package:rhythm_flutter/core/widgets/app_text_field.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      UiUtils.showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    ref.read(authProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  child: Text(
                    context.l10n.getStarted,
                    style: context.textTheme.headlineLarge,
                  ),
                ),
                Spacing.small,
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    context.l10n.signUp,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Spacing.xxLarge,
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: AppTextField(
                    controller: _nameController,
                    labelText: context.l10n.fullName,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => Validators.required(v, context.l10n.fullName),
                  ),
                ),
                Spacing.medium,
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AppTextField(
                    controller: _emailController,
                    labelText: context.l10n.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                ),
                Spacing.medium,
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: AppTextField(
                    controller: _passwordController,
                    labelText: context.l10n.password,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                ),
                Spacing.medium,
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: AppTextField(
                    controller: _confirmPasswordController,
                    labelText: context.l10n.confirmPassword,
                    prefixIcon: Icons.lock_clock_outlined,
                    obscureText: true,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ),
                Spacing.xxLarge,
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: AppButton(
                    text: context.l10n.register,
                    onPressed: _onRegister,
                    isLoading: authState.isLoading,
                  ),
                ),
                if (authState.error != null) ...[
                  Spacing.medium,
                  Center(
                    child: Text(
                      authState.error!,
                      style: TextStyle(color: context.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                Spacing.xLarge,
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.l10n.alreadyHaveAccount),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(context.l10n.signIn),
                      ),
                    ],
                  ),
                ),
                Spacing.xxLarge,
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
