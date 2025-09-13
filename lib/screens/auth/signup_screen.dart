// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/auth_provider.dart';
// import '../../widgets/custom_form_widgets.dart';
// import '../../utils/responsive_helper.dart';
// import '../../theme/theme.dart';
// import '../../models/user.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
  
//   String _selectedRole = UserRole.admin;
//   String? _selectedGender;
//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;

//   final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSignup() async {
//     if (_formKey.currentState!.validate()) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
//       final success = await authProvider.signUp(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//         name: _nameController.text.trim(),
//         phone: _phoneController.text.trim(),
//         role: _selectedRole,
//         gender: _selectedGender,
//       );

//       if (mounted) {
//         if (success) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Account created successfully!'),
//               backgroundColor: CHWTheme.primaryColor,
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(authProvider.errorMessage ?? 'Signup failed'),
//               backgroundColor: CHWTheme.errorColor,
//             ),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: CHWTheme.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Create Account'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: CHWTheme.primaryColor,
//       ),
//       body: SafeArea(
//         child: ResponsiveContainer(
//           maxWidth: 400,
//           child: SingleChildScrollView(
//             padding: ResponsiveHelper.getResponsivePadding(context),
//             child: Column(
//               children: [
//                 const SizedBox(height: 24),
                
//                 Text(
//                   'Create New Account',
//                   style: CHWTheme.headingStyle.copyWith(
//                     fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
//                     color: CHWTheme.primaryColor,
//                   ),
//                 ),
                
//                 const SizedBox(height: 8),
                
//                 Text(
//                   'Fill in the details below to create your account.',
//                   style: CHWTheme.bodyStyle.copyWith(
//                     color: Colors.grey.shade600,
//                     fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
                
//                 const SizedBox(height: 32),
                
//                 // Signup Form
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       CustomTextField(
//                         label: 'Full Name',
//                         controller: _nameController,
//                         prefixIcon: const Icon(Icons.person_outline),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your full name';
//                           }
//                           if (value.trim().length < 2) {
//                             return 'Name must be at least 2 characters';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       CustomTextField(
//                         label: 'Email Address',
//                         controller: _emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         prefixIcon: const Icon(Icons.email_outlined),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       CustomTextField(
//                         label: 'Phone Number',
//                         controller: _phoneController,
//                         keyboardType: TextInputType.phone,
//                         prefixIcon: const Icon(Icons.phone_outlined),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your phone number';
//                           }
//                           if (value.length < 10) {
//                             return 'Please enter a valid phone number';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Role Selection
//                       CustomDropdown(
//                         label: 'Role',
//                         value: UserRole.getDisplayName(_selectedRole),
//                         items: UserRole.all.map((role) => UserRole.getDisplayName(role)).toList(),
//                         onChanged: (value) {
//                           if (value != null) {
//                             setState(() {
//                               // Convert display name back to role key
//                               switch (value) {
//                                 case 'Administrator':
//                                   _selectedRole = UserRole.admin;
//                                   break;
//                                 case 'Staff Member':
//                                   _selectedRole = UserRole.staff;
//                                   break;
//                                 case 'Supervisor':
//                                   _selectedRole = UserRole.supervisor;
//                                   break;
//                               }
//                             });
//                           }
//                         },
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please select a role';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Gender Selection (Optional)
//                       CustomDropdown(
//                         label: 'Gender (Optional)',
//                         value: _selectedGender,
//                         items: _genderOptions,
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedGender = value;
//                           });
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       CustomTextField(
//                         label: 'Password',
//                         controller: _passwordController,
//                         obscureText: !_isPasswordVisible,
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isPasswordVisible = !_isPasswordVisible;
//                             });
//                           },
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a password';
//                           }
//                           if (value.length < 6) {
//                             return 'Password must be at least 6 characters';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       CustomTextField(
//                         label: 'Confirm Password',
//                         controller: _confirmPasswordController,
//                         obscureText: !_isConfirmPasswordVisible,
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
//                             });
//                           },
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please confirm your password';
//                           }
//                           if (value != _passwordController.text) {
//                             return 'Passwords do not match';
//                           }
//                           return null;
//                         },
//                       ),
                      
//                       const SizedBox(height: 32),
                      
//                       // Signup Button
//                       Consumer<AuthProvider>(
//                         builder: (context, authProvider, child) {
//                           return CustomButton(
//                             text: 'Create Account',
//                             onPressed: _handleSignup,
//                             isLoading: authProvider.isLoading,
//                           );
//                         },
//                       ),
                      
//                       const SizedBox(height: 24),
                      
//                       // Login Link
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Already have an account? ',
//                             style: CHWTheme.bodyStyle.copyWith(
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             child: Text(
//                               'Sign In',
//                               style: CHWTheme.bodyStyle.copyWith(
//                                 color: CHWTheme.primaryColor,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }