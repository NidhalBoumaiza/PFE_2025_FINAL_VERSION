import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/features/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/signup_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/verify_code_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/reusable_text_field_widget.dart';
import '../../../../widgets/reusable_text_widget.dart';
import '../../../home/presentation/pages/home_medecin.dart';
import '../../../home/presentation/pages/home_patient.dart';
import '../blocs/login BLoC/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObsecureText = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      "sign_in".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Header image
                  Center(
                    child: Image.asset(
                      'assets/images/Login.png',
                      height: 200.h,
                      width: 200.w,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Form fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email label
                        Text(
                          "Email",
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Email field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: emailController,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              hintText: "email_placeholder".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "L'email est obligatoire".tr;
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return "Veuillez entrer un email valide".tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Password label
                        Text(
                          "Mot de passe",
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Password field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: _isObsecureText,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              hintText: "password_placeholder".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObsecureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObsecureText = !_isObsecureText;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Le mot de passe est obligatoire".tr;
                              }
                              if (value.length < 6) {
                                return "Le mot de passe doit contenir au moins 6 caractères"
                                    .tr;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "forgot_password".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                  // Login button
                  BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) async {
                      if (state is LoginSuccess) {
                        showSuccessSnackBar(context, "login_success".tr);
                        if (state.user.role == "medecin") {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                            context,
                            const HomeMedecin(),
                          );
                        } else {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                            context,
                            const HomePatient(),
                          );
                        }
                      } else if (state is LoginError) {
                        // Check if the error message contains information about account activation
                        if (state.message.contains(
                              'Account is not activated',
                            ) ||
                            state.message.contains('verify your email')) {
                          // Show error message with option to navigate to verification screen
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: Text('Account Verification Required'),
                                  content: Text(
                                    'Your account has not been activated. Please verify your email to continue.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        // Navigate to verification screen with the email
                                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                          context,
                                          VerifyCodeScreen(
                                            email: emailController.text,
                                            isAccountCreation: true,
                                          ),
                                        );
                                      },
                                      child: Text('Verify Now'),
                                    ),
                                  ],
                                ),
                          );
                        } else {
                          // Normal error handling
                          showErrorSnackBar(context, state.message.tr);
                        }
                      }
                    },
                    builder: (context, state) {
                      final isLoading =
                          state is LoginLoading && state.isEmailPasswordLogin;
                      return Container(
                        width: double.infinity,
                        height: 55.h,
                        margin: EdgeInsets.only(top: 10.h),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 2,
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<LoginBloc>().add(
                                        LoginWithEmailAndPassword(
                                          email: emailController.text,
                                          password: passwordController.text,
                                        ),
                                      );
                                    }
                                  },
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                  : Text(
                                    "connect_button_text".tr,
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30.h),

                  // No account row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "no_account".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                            context,
                            SignupScreen(),
                          );
                        },
                        child: Text(
                          "sign_up".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),

                  // Or login with divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[300], thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          "or_login_with".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[300], thickness: 1),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Google login button
                  BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) async {
                      if (state is LoginSuccess) {
                        showSuccessSnackBar(context, "login_success".tr);
                        if (state.user.role == "medecin") {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                            context,
                            const HomeMedecin(),
                          );
                        } else {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                            context,
                            const HomePatient(),
                          );
                        }
                      } else if (state is LoginError) {
                        showErrorSnackBar(context, state.message.tr);
                      }
                    },
                    builder: (context, state) {
                      final isEmailPasswordLoading =
                          state is LoginLoading && state.isEmailPasswordLogin;
                      final isGoogleLoading =
                          state is LoginLoading && !state.isEmailPasswordLogin;

                      return Container(
                        width: double.infinity,
                        height: 55.h,
                        margin: EdgeInsets.only(bottom: 30.h),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            FontAwesomeIcons.google,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                          label: Text(
                            "continue_with_google".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isEmailPasswordLoading
                                    ? Colors.grey
                                    : (isGoogleLoading
                                        ? AppColors.primaryColor.withAlpha(178)
                                        : AppColors.primaryColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: isEmailPasswordLoading ? 0 : 2,
                          ),
                          onPressed:
                              isGoogleLoading || isEmailPasswordLoading
                                  ? null
                                  : () {
                                    context.read<LoginBloc>().add(
                                      LoginWithGoogle(),
                                    );
                                  },
                        ),
                      );
                    },
                  ),

                  // Add a debug button to create a test account (only in debug/dev builds)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    Padding(
                      padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                      child: GestureDetector(
                        onTap: () => _createTestAccount(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: Colors.grey,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Debug: Create test account",
                              style: GoogleFonts.raleway(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to manually create a test account for debugging
  void _createTestAccount(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Creating test account..."),
                ],
              ),
            ),
      );

      // Create a test account directly with Firebase
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Use a test email with timestamp to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test$timestamp@example.com';
      const password = 'Test123456';

      // Create user in Firebase Auth
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a corresponding Firestore document
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await firestore.collection('patients').doc(uid).set({
          'id': uid,
          'name': 'Test',
          'lastName': 'User',
          'email': email,
          'role': 'patient',
          'gender': 'Homme',
          'phoneNumber': '',
          'dateOfBirth': null,
          'antecedent': '',
          'accountStatus': true, // Already activated for testing
        });

        // Also create an entry in users collection for notifications
        await firestore.collection('users').doc(uid).set({
          'id': uid,
          'name': 'Test',
          'lastName': 'User',
          'email': email,
          'role': 'patient',
        });

        // Close the dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          // Show success dialog with credentials
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Test Account Created"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: $email"),
                      const Text("Password: Test123456"),
                      const SizedBox(height: 16),
                      const Text("Account is already activated for testing."),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Error"),
                content: Text("Failed to create test account: $e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    }
  }
}
