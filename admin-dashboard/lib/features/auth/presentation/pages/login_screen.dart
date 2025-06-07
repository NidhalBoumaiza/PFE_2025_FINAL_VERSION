// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../bloc/auth_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? theme.colorScheme.surface : Colors.grey[50],
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Row(
            children: [
              // Left Side - Branding Section
              if (MediaQuery.of(context).size.width > 768) ...[
                Expanded(
                  flex: 1,
                  child: _buildBrandingSection(context, isDarkMode),
                ),
              ],
              // Right Side - Login Form
              Expanded(
                flex: MediaQuery.of(context).size.width > 768 ? 1 : 2,
                child: _buildLoginForm(context, state, isDarkMode),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandingSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                    theme.colorScheme.secondary.withValues(alpha: 0.6),
                  ]
                  : [Colors.blue[600]!, Colors.indigo[700]!],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(64.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Icon
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 60.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40.h),

              // Welcome Text
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                'Medical Admin',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 24.h),

              // Description
              SizedBox(
                width: 320.w,
                child: Text(
                  'Manage your medical practice with our comprehensive admin dashboard. Monitor patients.',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // // Features List
              // _buildFeatureItem(Icons.people, 'Patient Management'),
              // SizedBox(height: 16.h),
              // _buildFeatureItem(Icons.local_hospital, 'Doctor Directory'),
              // SizedBox(height: 16.h),
              // _buildFeatureItem(Icons.analytics, 'Analytics & Reports'),
              // SizedBox(height: 16.h),
              // _buildFeatureItem(Icons.security, 'Secure & HIPAA Compliant'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: Colors.white),
        ),
        SizedBox(width: 16.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AuthState state,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: isDarkMode ? theme.colorScheme.surface : Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(48.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 400.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode
                                        ? theme.colorScheme.onSurface
                                        : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Enter your credentials to access the admin dashboard',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color:
                                    isDarkMode
                                        ? theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7)
                                        : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 40.h),

                            // Login Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Field
                                  Text(
                                    'Email Address',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDarkMode
                                              ? theme.colorScheme.onSurface
                                              : Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color:
                                            isDarkMode
                                                ? theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.6)
                                                : Colors.grey[500],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              isDarkMode
                                                  ? theme.colorScheme.outline
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDarkMode
                                              ? theme.colorScheme.surface
                                              : Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(fontSize: 16.sp),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email address';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20.h),

                                  // Password Field
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDarkMode
                                              ? theme.colorScheme.onSurface
                                              : Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color:
                                            isDarkMode
                                                ? theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.6)
                                                : Colors.grey[500],
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color:
                                              isDarkMode
                                                  ? theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.6)
                                                  : Colors.grey[500],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              isDarkMode
                                                  ? theme.colorScheme.outline
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDarkMode
                                              ? theme.colorScheme.surface
                                              : Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    obscureText: !_isPasswordVisible,
                                    style: TextStyle(fontSize: 16.sp),
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
                                  SizedBox(height: 28.h),

                                  // Login Button
                                  SizedBox(
                                    height: 56.h,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: theme.colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          state is AuthLoading
                                              ? null
                                              : () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  context.read<AuthBloc>().add(
                                                    LoginWithEmailAndPassword(
                                                      email:
                                                          _emailController.text
                                                              .trim(),
                                                      password:
                                                          _passwordController
                                                              .text
                                                              .trim(),
                                                    ),
                                                  );
                                                }
                                              },
                                      child:
                                          state is AuthLoading
                                              ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: 20.h,
                                                    width: 20.w,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    'Signing In...',
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),

                                  // Security Notice
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
