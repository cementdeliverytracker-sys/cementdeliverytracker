import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
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

    try {
      await context.read<AuthNotifier>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                width: 200,
                child: Image.asset('assets/images/cementdeliverytracker.png'),
              ),
              Card(
                margin: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _handleLogin,
                            child: const Text('Login'),
                          ),
                        if (!_isLoading)
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppConstants.routeSignup);
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
    );
  }
}
