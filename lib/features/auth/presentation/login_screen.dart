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
import 'package:rhythm_flutter/shared/providers/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    
    ref.read(authProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.xxLarge,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInLeft(
                      child: IconButton(
                        onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
                        icon: const Icon(Icons.language),
                      ),
                    ),
                  ],
                ),
                Spacing.medium,
                FadeInUp(
                  child: Text(
                    context.l10n.welcomeBack,
                    style: context.textTheme.headlineLarge,
                  ),
                ),
                Spacing.small,
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    context.l10n.signIn,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Spacing.xxLarge,
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
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
                  delay: const Duration(milliseconds: 300),
                  child: AppTextField(
                    controller: _passwordController,
                    labelText: context.l10n.password,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                ),
                Spacing.small,
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(context.l10n.forgotPassword),
                    ),
                  ),
                ),
                Spacing.xLarge,
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: AppButton(
                    text: context.l10n.login,
                    onPressed: _onLogin,
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
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.l10n.dontHaveAccount),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(context.l10n.signUp),
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
