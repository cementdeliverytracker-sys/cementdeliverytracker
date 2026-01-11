import 'dart:io';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/shared/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      AppUtils.showSnackBar(
        context,
        'Please select a profile image',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthNotifier>().signup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        imagePath: _selectedImage!.path,
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
                        UserImagePicker(
                          onPickImage: (pickedImage) {
                            setState(() => _selectedImage = pickedImage);
                          },
                        ),
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
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          enableSuggestions: false,
                          validator: AppUtils.validateUsername,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: AppUtils.validatePhone,
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
                            onPressed: _handleSignup,
                            child: const Text('Sign Up'),
                          ),
                        if (!_isLoading)
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppConstants.routeLogin);
                            },
                            child: const Text('I already have an account'),
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
