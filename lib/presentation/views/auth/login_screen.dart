import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    // Add a listener to handle navigation and errors centrally.
    // Capture the viewmodel instance now so callbacks don't lookup context
    // (which can be unsafe if called after dispose).
    _authViewModel = context.read<AuthViewModel>();
    _authViewModel.addListener(_onAuthStateChanged);
    // Check initial auth state after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authViewModel.checkAuthState();
    });
  }

  @override
  void dispose() {
    // Remove listener from the captured instance.
    _authViewModel.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    // First guard: if widget is no longer mounted, bail out immediately.
    if (!mounted) return;
    final authViewModel = _authViewModel;

    // Log auth listener calls for debugging
    developer.log('LoginScreen._onAuthStateChanged called; isAuthenticated=${authViewModel.isAuthenticated}, error=${authViewModel.errorMessage}',
        name: 'LoginScreen');

    if (authViewModel.isAuthenticated) {
      // Navigate to home screen on successful authentication.
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (authViewModel.errorMessage != null) {
      // Show an error message if authentication fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      // It's good practice for the ViewModel to clear the error after it's been shown.
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Trigger the sign-in process. The listener will handle the result.
      await context.read<AuthViewModel>().signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.local_drink,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    AppLocalizations.of(context)!.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context)!.emailLabel,
                    hint: AppLocalizations.of(context)!.enterEmailHint,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: AppLocalizations.of(context)!.passwordLabel,
                    hint: AppLocalizations.of(context)!.enterPasswordHint,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog();
                      },
                      child: Text(AppLocalizations.of(context)!.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                        return CustomButton(
                        text: AppLocalizations.of(context)!.loginButton,
                        isLoading: authViewModel.state == AuthState.loading,
                        onPressed: _login,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.dontHaveAccount} ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.register);
                        },
                        child: Text(AppLocalizations.of(context)!.register),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

  // Do not capture the BuildContext here; use the stored _authViewModel
  // instance for async operations and the State's context for UI.

    showDialog(
      context: context,
        builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(loc.resetPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.resetPasswordInstruction),
              const SizedBox(height: 16),
              CustomTextField(
                controller: emailController,
                label: loc.emailLabel,
                hint: loc.enterEmailHint,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  final vm = _authViewModel;
                  // Capture navigator and messenger from the State's context
                  // before performing the async operation so we don't rely on
                  // a builder-local context after an await.
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  await vm.resetPassword(
                    emailController.text.trim(),
                  );

                  if (!mounted) return;

                  // Close the dialog and show feedback using the captured
                  // navigator/messenger which are safe to use here.
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(loc.passwordResetSent),
                    ),
                  );
                }
              },
              child: Text(loc.send),
            ),
          ],
        );
      },
    );
  }
}
