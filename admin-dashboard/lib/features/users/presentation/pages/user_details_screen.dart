// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This would typically receive a user ID from the route arguments
    // and use it to fetch the user details using a dedicated UserBloc

    return MainLayout(
      selectedIndex: 1,
      title: 'Détails de l\'utilisateur',
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détails de l\'utilisateur',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back, size: 20.sp),
                      label: Text(
                        'Retour aux utilisateurs',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.users,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // User Details will be loaded here
              // Add user details content based on userId and userType
            ],
          ),
        ),
      ),
    );
  }
}
