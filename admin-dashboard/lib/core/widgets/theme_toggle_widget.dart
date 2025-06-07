import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_cubit.dart';

class ThemeToggleWidget extends StatelessWidget {
  final bool compact;
  final Color? activeColor;

  const ThemeToggleWidget({Key? key, this.compact = false, this.activeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = activeColor ?? theme.primaryColor;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        if (state is ThemeLoaded) {
          final isDarkMode = state.themeMode == ThemeMode.dark;

          if (compact) {
            return Switch(
              value: isDarkMode,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
              activeColor: primaryColor,
            );
          }

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: primaryColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Mode',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isDarkMode ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (_) {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),
          );
        }

        // Show placeholder while theme is initializing
        return Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.light_mode,
                        color: Colors.grey,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(value: false, onChanged: null),
              ],
            ),
          ),
        );
      },
    );
  }
}
