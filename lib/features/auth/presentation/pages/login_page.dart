import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    var navigated = false;

    try {
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final isAuthenticated =
          FirebaseAuth.instance.currentUser != null ||
          authNotifier.state == AuthState.authenticated;
      if (!isAuthenticated) {
        throw StateError('Login did not authenticate');
      }
      if (!mounted) return;
      navigated = true;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
        default:
          message = 'Login failed. Please try again later.';
      }
      if (!mounted) return;
      AppUtils.showSnackBar(context, message, isError: true);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        'Login failed. Please try again later.',
        isError: true,
      );
      setState(() => _isLoading = false);
    } finally {
      if (mounted && !navigated) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    width: 200,
                    child: Image.asset(
                      'assets/images/cementdeliverytracker.png',
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: AppUtils.validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              obscureText: true,
                              validator: AppUtils.validatePassword,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: const Text('Login'),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() => _isLoading = true);
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        AppConstants.routeSignup,
                                      );
                                    },
                              child: const Text('Create new account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(child: const CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
