// ignore_for_file: deprecated_member_use

import 'package:chw_tb/components/auth_form.dart';
import 'package:chw_tb/components/auth_header.dart';
import 'package:chw_tb/components/glassmorphism_button.dart';
import 'package:chw_tb/controllers/input_controllers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  final String? initialRole; // expects 'qari' or 'student' (any case)
  const SignUpScreen({super.key, this.initialRole});

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
    // Implement sign-up logic here with snackbar error handling
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
                      // Glassmorphism Role Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
                            foregroundColor: Colors.white70,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.white70),
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
