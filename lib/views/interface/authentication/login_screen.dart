// ignore_for_file: deprecated_member_use

import 'package:chw_tb/components/auth_form.dart';
import 'package:chw_tb/components/auth_header.dart';
import 'package:chw_tb/components/glassmorphism_button.dart';
import 'package:chw_tb/controllers/input_controllers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // Implement sign-in logic here with snackbar error handling
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
                            foregroundColor: Colors.white70,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.white70),
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
