import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

// Simple animation widget to replace AnimationFindIn
class AnimationFindIn extends StatefulWidget {
  final Widget child;

  const AnimationFindIn({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimationFindIn> createState() => _AnimationFindInState();
}

class _AnimationFindInState extends State<AnimationFindIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: widget.child),
        );
      },
    );
  }
}

// Simple ReusableText widget
class ReusableText extends StatelessWidget {
  final String text;
  final double textSize;
  final FontWeight textFontWeight;
  final Color? textColor;

  const ReusableText({
    Key? key,
    required this.text,
    required this.textSize,
    required this.textFontWeight,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.raleway(
        fontSize: textSize,
        fontWeight: textFontWeight,
        color: textColor,
      ),
    );
  }
}

// Simple MyCustomButton widget
class MyCustomButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback function;
  final Color buttonColor;
  final String text;
  final double circularRadious;
  final Color textButtonColor;
  final double fontSize;
  final FontWeight fontWeight;
  final Widget? widget;

  const MyCustomButton({
    Key? key,
    required this.width,
    required this.height,
    required this.function,
    required this.buttonColor,
    required this.text,
    required this.circularRadious,
    required this.textButtonColor,
    required this.fontSize,
    required this.fontWeight,
    this.widget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: function,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(circularRadious),
          ),
        ),
        child:
            widget ??
            Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textButtonColor,
              ),
            ),
      ),
    );
  }
}

// Simple ReusablecircularProgressIndicator widget
class ReusablecircularProgressIndicator extends StatelessWidget {
  final Color indicatorColor;

  const ReusablecircularProgressIndicator({
    Key? key,
    required this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.w,
      height: 24.h,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        strokeWidth: 2.w,
      ),
    );
  }
}

class LocationActivationScreen extends StatefulWidget {
  final Function? onLocationEnabled;

  const LocationActivationScreen({Key? key, this.onLocationEnabled})
    : super(key: key);

  @override
  State<LocationActivationScreen> createState() =>
      _LocationActivationScreenState();
}

class _LocationActivationScreenState extends State<LocationActivationScreen> {
  bool _showWidget1 = false;
  bool _showWidget2 = false;
  bool _showWidget3 = false;
  bool _showWidget4 = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showWidgetsOneByOne();
  }

  void _showWidgetsOneByOne() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showWidget1 = true;
        });
      }
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showWidget2 = true;
        });
      }
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showWidget3 = true;
        });
      }
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showWidget4 = true;
        });
      }
    });
  }

  Future<void> _enableLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        // Wait until the user enables location services
        bool enabled = false;
        while (!enabled) {
          await Future.delayed(const Duration(seconds: 1));
          enabled = await LocationService.isLocationServiceEnabled();
        }
      }

      // Request permission
      LocationPermission permission =
          await LocationService.requestLocationPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Try to get position to confirm it works
        final position = await LocationService.getCurrentPosition();

        if (position != null) {
          // Success! Call the callback if provided
          if (widget.onLocationEnabled != null) {
            widget.onLocationEnabled!();
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_enabled_success'.tr),
              backgroundColor: Colors.green,
            ),
          );

          // Close this screen
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('could_not_get_location'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('location_permission_denied'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error enabling location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_enabling_location'.tr),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 25, 30, 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50.h),
                  Stack(
                    children: [
                      Image.asset(
                        'assets/images/maponly.jpg',
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback container if image not found
                          return Container(
                            height: 220.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20.r),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.1),
                                  Colors.blue.withOpacity(0.2),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 60.w,
                        top: 45.h,
                        child: Visibility(
                          visible: _showWidget1,
                          child: AnimationFindIn(
                            child: Image.asset(
                              'assets/images/1.jpg',
                              errorBuilder: (context, error, stackTrace) {
                                return _buildLocationPin(
                                  AppColors.primaryColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 165.w,
                        top: 55.h,
                        child: Visibility(
                          visible: _showWidget2,
                          child: AnimationFindIn(
                            child: Image.asset(
                              'assets/images/2.jpg',
                              errorBuilder: (context, error, stackTrace) {
                                return _buildLocationPin(Colors.red);
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 60.w,
                        top: 130.h,
                        child: Visibility(
                          visible: _showWidget3,
                          child: AnimationFindIn(
                            child: Image.asset(
                              'assets/images/3.jpg',
                              errorBuilder: (context, error, stackTrace) {
                                return _buildLocationPin(Colors.green);
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 165.w,
                        top: 130.h,
                        child: Visibility(
                          visible: _showWidget4,
                          child: AnimationFindIn(
                            child: Image.asset(
                              'assets/images/4.jpg',
                              errorBuilder: (context, error, stackTrace) {
                                return _buildLocationPin(Colors.orange);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ReusableText(
                      text: "Activer la localisation",
                      textSize: 20.sp,
                      textFontWeight: FontWeight.w800,
                      textColor: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: ReusableText(
                      text:
                          "Permettre à l'application d'accéder à votre emplacement? Vous devez autoriser l'accès pour que l'application fonctionne. Nous ne suivrons votre emplacement que pendant le service.",
                      textSize: 13.sp,
                      textFontWeight: FontWeight.w600,
                      textColor: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.147),
                  MyCustomButton(
                    width: double.infinity,
                    height: 50.h,
                    function: _isLoading ? () {} : _enableLocation,
                    buttonColor: AppColors.primaryColor,
                    text: 'Activer localisation',
                    circularRadious: 15.sp,
                    textButtonColor: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    widget:
                        _isLoading
                            ? ReusablecircularProgressIndicator(
                              indicatorColor: Colors.white,
                            )
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPin(Color color) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        Container(
          width: 15.w,
          height: 15.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
