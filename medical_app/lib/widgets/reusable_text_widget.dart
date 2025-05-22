import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ReusableTextWidget extends StatelessWidget {
  final String text;

  final int textSize;
  FontWeight? fontWeight;
  Color? color;
  double? letterSpacing;

  ReusableTextWidget({
    super.key,
    required this.text,
    this.textSize = 16,
    this.fontWeight,
    this.color,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr, // Translated title
      style: GoogleFonts.raleway(
        fontSize: textSize.sp,
        fontWeight: fontWeight ?? FontWeight.w200,
        color: color ?? Colors.black,
        letterSpacing: letterSpacing ?? 0,
      ),
    );
  }
}
