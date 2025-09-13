import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/custom_form_widgets.dart';
import '../../utils/responsive_helper.dart';
import '../../theme/theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Navigation will be handled by AuthWrapper
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed'),
              backgroundColor: CHWTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CHWTheme.backgroundColor,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 400,
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Logo or App Name
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CHWTheme.primaryColor,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'CHW Admin',
                  style: CHWTheme.headingStyle.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                    color: CHWTheme.primaryColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Welcome back! Please sign in to continue.',
                  style: CHWTheme.bodyStyle.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      CustomTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: CHWTheme.bodyStyle.copyWith(
                              color: CHWTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return CustomButton(
                            text: 'Sign In',
                            onPressed: _handleLogin,
                            isLoading: authProvider.isLoading,
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Up Link
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Text(
                      //       "Don't have an account? ",
                      //       style: CHWTheme.bodyStyle.copyWith(
                      //         color: Colors.grey.shade600,
                      //       ),
                      //     ),
                      //     TextButton(
                      //       onPressed: () {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (context) => const SignupScreen(),
                      //           ),
                      //         );
                      //       },
                      //       child: Text(
                      //         'Sign Up',
                      //         style: CHWTheme.bodyStyle.copyWith(
                      //           color: CHWTheme.primaryColor,
                      //           fontWeight: FontWeight.w600,
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}