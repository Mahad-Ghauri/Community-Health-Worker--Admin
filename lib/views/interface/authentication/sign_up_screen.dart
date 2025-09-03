// ignore_for_file: deprecated_member_use

import 'package:chw_tb/components/auth_form.dart';
import 'package:chw_tb/components/auth_header.dart';
import 'package:chw_tb/components/glassmorphism_button.dart';
import 'package:chw_tb/controllers/input_controllers.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/controllers/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final InputControllers inputs = InputControllers();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    inputs.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!inputs.validateForm()) return;

    if (inputs.passwordController.text !=
        inputs.confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => inputs.loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signUp(
        email: inputs.emailController.text,
        password: inputs.passwordController.text,
        displayName: inputs.nameController.text,
      );
      if (!mounted) return;
      context.go('/home');
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => inputs.loading = false);
    }
  }

  String _friendlyError(Exception e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'Email already in use';
    if (msg.contains('weak-password')) return 'Password is too weak';
    if (msg.contains('invalid-email')) return 'Invalid email address';
    return 'Sign up failed: $msg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AuthHeader(
              title: 'Create Account',
              subtitle: 'Join us on your learning journey',
              logoPath: 'assets/icons/logo.jpeg',
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AuthForm(
                    formKey: inputs.formKey,
                    children: [
                      AuthFormField(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: inputs.nameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AuthFormField(
                        labelText: 'Phone',
                        hintText: '+92xxxxxxxxxx',
                        keyboardType: TextInputType.phone,
                        controller: inputs.phoneController,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Phone is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AuthFormField(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        controller: inputs.emailController,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Email is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AuthFormField(
                        labelText: 'Password',
                        hintText: 'Create a password',
                        controller: inputs.passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AuthFormField(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        controller: inputs.confirmPasswordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      GlassmorphismButton(
                        label: 'Create Account',
                        loading: inputs.loading,
                        onPressed: _handleSignUp,
                        icon: Icons.person_add,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/sign-in'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
