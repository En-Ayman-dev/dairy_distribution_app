import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../presentation/viewmodels/auth_viewmodel.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      developer.log('Splash: checking auth state', name: 'Splash');
      final authVm = context.read<AuthViewModel>();
      await authVm.checkAuthState();
      if (!mounted) return;
      if (authVm.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
