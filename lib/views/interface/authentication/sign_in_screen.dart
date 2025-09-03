// ignore_for_file: deprecated_member_use

import 'package:chw_tb/components/auth_form.dart';
import 'package:chw_tb/components/auth_header.dart';
import 'package:chw_tb/components/glassmorphism_button.dart';
import 'package:chw_tb/controllers/input_controllers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/controllers/providers/app_providers.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final InputControllers inputs = InputControllers();

  @override
  void dispose() {
    inputs.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!inputs.validateForm()) return;

    setState(() => inputs.loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signIn(
        inputs.emailController.text,
        inputs.passwordController.text,
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
    // Minimal mapping for FirebaseAuth errors without importing types directly here
    if (msg.contains('wrong-password')) return 'Incorrect password';
    if (msg.contains('user-not-found')) return 'No user found for this email';
    if (msg.contains('invalid-email')) return 'Invalid email address';
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts, try later';
    }
    return 'Sign in failed: $msg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AuthHeader(
              title: 'Welcome Back',
              subtitle: 'Sign in to continue your journey',
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
                        hintText: 'Your password',
                        controller: inputs.passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      GlassmorphismButton(
                        label: 'Sign In',
                        loading: inputs.loading,
                        onPressed: _handleSignIn,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/sign-up'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
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
