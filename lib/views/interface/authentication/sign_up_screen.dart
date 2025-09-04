// ignore_for_file: deprecated_member_use

import 'package:chw_tb/components/auth_form.dart';
import 'package:chw_tb/components/auth_header.dart';
import 'package:chw_tb/components/glassmorphism_button.dart';
import 'package:chw_tb/controllers/input_controllers.dart';
import 'package:provider/provider.dart';
import 'package:chw_tb/controllers/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final InputControllers inputs = InputControllers();
  String _selectedGender = 'male';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    inputs.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be 18+ years old
    );
    if (picked != null) {
      inputs.dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
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
      final success = await auth.signUp(
        email: inputs.emailController.text.trim(),
        password: inputs.passwordController.text,
        fullName: inputs.nameController.text.trim(),
        phoneNumber: inputs.phoneController.text.trim(),
        workingArea: inputs.workingAreaController.text.trim(),
        dateOfBirth: inputs.dateOfBirthController.text.trim().isNotEmpty 
            ? inputs.dateOfBirthController.text.trim() 
            : null,
        gender: _selectedGender,
      );
      
      if (!mounted) return;

      if (success) {
        // Navigate to first-time setup after successful registration
        Navigator.pushReplacementNamed(context, '/first-time-setup');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Registration failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      if (mounted) setState(() => inputs.loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF0B2239)
        : const Color(0xFFFDFDFD);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: isDark
                    ? [
                        const Color(0xFF0B2239),
                        const Color(0xFF162B45).withOpacity(0.8),
                        const Color(0xFF009688).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFFFDFDFD),
                        const Color(0xFF009688).withOpacity(0.05),
                        const Color(0xFF2ECC71).withOpacity(0.03),
                      ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

          SafeArea(
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
                          // Date of Birth field - using GestureDetector wrapper
                          GestureDetector(
                            onTap: _selectDateOfBirth,
                            child: AbsorbPointer(
                              child: AuthFormField(
                                labelText: 'Date of Birth',
                                hintText: 'Select your date of birth',
                                controller: inputs.dateOfBirthController,
                                prefixIcon: Icons.calendar_today_outlined,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Date of birth is required'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Gender dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) => setState(() => _selectedGender = value!),
                            validator: (v) => v == null ? 'Gender is required' : null,
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
                          AuthFormField(
                            labelText: 'Working Area',
                            hintText: 'e.g., Lahore District',
                            controller: inputs.workingAreaController,
                            prefixIcon: Icons.location_on_outlined,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Working area is required'
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
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                '/sign-in',
                              ), 
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
        ],
      ),
    );
  }
}
