// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/theme_toggle_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MainLayout(
      selectedIndex: 3, // Settings tab
      title: 'Paramètres',
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'Paramètres',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Theme Settings Section
              _buildSection(
                context: context,
                title: 'Apparence',
                icon: Icons.palette,
                children: [const ThemeToggleWidget()],
              ),

              SizedBox(height: 24.h),

              // Settings explanation
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings,
                        size: 64.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Paramètres de l\'application',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Configurez vos préférences du tableau de bord administrateur et les paramètres de compte. Le mode thème peut être basculé ci-dessus pour passer entre les modes clair et sombre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 24.h),

                      // Account section
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is Authenticated) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(height: 32.h),
                                Text(
                                  'Compte',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ListTile(
                                  title: Text(
                                    'Déconnexion',
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  subtitle: Text(
                                    'Se déconnecter de votre compte',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  trailing: Icon(Icons.logout, size: 24.sp),
                                  onTap: () {
                                    _showLogoutConfirmation(context);
                                  },
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Déconnexion',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(fontSize: 16.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler', style: TextStyle(fontSize: 14.sp)),
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(Logout());
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
