import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/custom_form_widgets.dart';
import '../../utils/responsive_helper.dart';
import '../../theme/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          setState(() {
            _isEmailSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent! Check your inbox.'),
              backgroundColor: CHWTheme.primaryColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to send reset email'),
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
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CHWTheme.primaryColor,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 400,
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CHWTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: CHWTheme.primaryColor,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  _isEmailSent ? 'Check Your Email' : 'Forgot Password?',
                  style: CHWTheme.headingStyle.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                    color: CHWTheme.primaryColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _isEmailSent 
                      ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}. Check your inbox and follow the instructions to reset your password.'
                      : 'No worries! Enter your email address below and we\'ll send you a link to reset your password.',
                  style: CHWTheme.bodyStyle.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                if (!_isEmailSent) ...[
                  // Reset Form
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
                        
                        const SizedBox(height: 32),
                        
                        // Reset Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return CustomButton(
                              text: 'Send Reset Link',
                              onPressed: _handleResetPassword,
                              isLoading: authProvider.isLoading,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Success Actions
                  Column(
                    children: [
                      CustomButton(
                        text: 'Resend Email',
                        onPressed: () {
                          setState(() {
                            _isEmailSent = false;
                          });
                        },
                        isOutlined: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CustomButton(
                        text: 'Back to Login',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Back to Login Link
                if (!_isEmailSent)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: CHWTheme.bodyStyle.copyWith(
                        color: CHWTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
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