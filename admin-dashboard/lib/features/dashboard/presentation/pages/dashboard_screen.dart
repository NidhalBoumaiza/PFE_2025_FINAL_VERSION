// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../../../users/presentation/bloc/users_bloc.dart';
import '../../../users/presentation/bloc/users_event.dart';
import '../../../users/presentation/bloc/users_state.dart';
import '../../domain/entities/stats_entity.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../widgets/dashboard/stat_card.dart';
import '../../../../widgets/responsive_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to fetch data after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<DashboardBloc>().add(LoadStats());
    // Load user statistics for enhanced stats
    context.read<UsersBloc>().add(LoadUserStatistics());
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0,
      title: 'Tableau de bord',
      child: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      'Aperçu du tableau de bord',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.people, size: 20.sp),
                          label: Text(
                            'Gérer les utilisateurs',
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
                  ],
                ),
              ),

              // Enhanced Stats Cards (Active/Inactive Users)
              _buildEnhancedStatsSection(),

              SizedBox(height: 24.h),

              // Basic Stats Cards
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  final isLoading = state is DashboardLoading;
                  final StatsEntity? stats =
                      state is StatsLoaded ? state.stats : null;

                  return Column(
                    children: [
                      ResponsiveLayout(
                        mobile: _buildStatCardsForMobile(isLoading, stats),
                        tablet: _buildStatCardsForTablet(isLoading, stats),
                        desktop: _buildStatCardsForDesktop(isLoading, stats),
                      ),

                      SizedBox(height: 24.h),

                      // Additional Info Section
                      _buildAdditionalInfoSection(isLoading, stats),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques d\'activité des utilisateurs',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        _buildEnhancedStatsCards(),
      ],
    );
  }

  Widget _buildEnhancedStatsCards() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        int activePatients = 0;
        int inactivePatients = 0;
        int activeDoctors = 0;
        int inactiveDoctors = 0;

        // Get activity statistics from UserStatisticsLoaded state
        if (state is UserStatisticsLoaded) {
          activePatients = state.statistics['activePatients'] ?? 0;
          inactivePatients = state.statistics['inactivePatients'] ?? 0;
          activeDoctors = state.statistics['activeDoctors'] ?? 0;
          inactiveDoctors = state.statistics['inactiveDoctors'] ?? 0;
        }

        // Show loading state for statistics
        if (state is UserStatisticsLoading) {
          return ResponsiveLayout(
            mobile: _buildLoadingStatsForMobile(),
            tablet: _buildLoadingStatsForTablet(),
            desktop: _buildLoadingStatsForDesktop(),
          );
        }

        return ResponsiveLayout(
          mobile: _buildEnhancedStatsForMobile(
            activePatients,
            inactivePatients,
            activeDoctors,
            inactiveDoctors,
          ),
          tablet: _buildEnhancedStatsForTablet(
            activePatients,
            inactivePatients,
            activeDoctors,
            inactiveDoctors,
          ),
          desktop: _buildEnhancedStatsForDesktop(
            activePatients,
            inactivePatients,
            activeDoctors,
            inactiveDoctors,
          ),
        );
      },
    );
  }

  Widget _buildLoadingStatsForMobile() {
    return Column(
      children: [
        _buildLoadingStatCard('Patients actifs', Colors.green),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Patients inactifs', Colors.orange),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Médecins actifs', Colors.blue),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Médecins inactifs', Colors.red),
      ],
    );
  }

  Widget _buildLoadingStatsForTablet() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Patients actifs', Colors.green),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Patients inactifs', Colors.orange),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Médecins actifs', Colors.blue),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Médecins inactifs', Colors.red),
        ),
      ],
    );
  }

  Widget _buildLoadingStatsForDesktop() {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Patients actifs', Colors.green),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Patients inactifs', Colors.orange),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Médecins actifs', Colors.blue),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Médecins inactifs', Colors.red),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatsForMobile(
    int activePatients,
    int inactivePatients,
    int activeDoctors,
    int inactiveDoctors,
  ) {
    return Column(
      children: [
        StatCard(
          title: 'Patients actifs',
          value: activePatients.toString(),
          icon: Icons.people,
          iconColor: Colors.green,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Patients inactifs',
          value: inactivePatients.toString(),
          icon: Icons.people_outline,
          iconColor: Colors.orange,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Médecins actifs',
          value: activeDoctors.toString(),
          icon: Icons.local_hospital,
          iconColor: Colors.blue,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Médecins inactifs',
          value: inactiveDoctors.toString(),
          icon: Icons.local_hospital_outlined,
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildEnhancedStatsForTablet(
    int activePatients,
    int inactivePatients,
    int activeDoctors,
    int inactiveDoctors,
  ) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Patients actifs',
            value: activePatients.toString(),
            icon: Icons.people,
            iconColor: Colors.green,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Patients inactifs',
            value: inactivePatients.toString(),
            icon: Icons.people_outline,
            iconColor: Colors.orange,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Médecins actifs',
            value: activeDoctors.toString(),
            icon: Icons.local_hospital,
            iconColor: Colors.blue,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Médecins inactifs',
            value: inactiveDoctors.toString(),
            icon: Icons.local_hospital_outlined,
            iconColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatsForDesktop(
    int activePatients,
    int inactivePatients,
    int activeDoctors,
    int inactiveDoctors,
  ) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Patients actifs',
            value: activePatients.toString(),
            icon: Icons.people,
            iconColor: Colors.green,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Patients inactifs',
            value: inactivePatients.toString(),
            icon: Icons.people_outline,
            iconColor: Colors.orange,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Médecins actifs',
            value: activeDoctors.toString(),
            icon: Icons.local_hospital,
            iconColor: Colors.blue,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Médecins inactifs',
            value: inactiveDoctors.toString(),
            icon: Icons.local_hospital_outlined,
            iconColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatCard(String title, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.hourglass_empty, color: color, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: 60.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: 100.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(bool isLoading, StatsEntity? stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu du système',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  'Utilisateurs actifs',
                  isLoading ? '...' : (stats?.totalUsers.toString() ?? '0'),
                  Icons.people,
                ),
                _buildInfoItem(
                  'Professionnels de santé',
                  isLoading ? '...' : (stats?.totalDoctors.toString() ?? '0'),
                  Icons.local_hospital,
                ),
                _buildInfoItem(
                  'Patients inscrits',
                  isLoading ? '...' : (stats?.totalPatients.toString() ?? '0'),
                  Icons.assignment_ind,
                ),
                _buildInfoItem(
                  'Total rendez-vous',
                  isLoading
                      ? '...'
                      : (stats?.totalAppointments.toString() ?? '0'),
                  Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsForMobile(bool isLoading, StatsEntity? stats) {
    return Column(
      children: [
        StatCard(
          title: 'Total utilisateurs',
          value: isLoading ? '...' : (stats?.totalUsers.toString() ?? '0'),
          icon: Icons.people,
          iconColor: Colors.blue,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total médecins',
          value: isLoading ? '...' : (stats?.totalDoctors.toString() ?? '0'),
          icon: Icons.local_hospital,
          iconColor: Colors.green,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total patients',
          value: isLoading ? '...' : (stats?.totalPatients.toString() ?? '0'),
          icon: Icons.people_outline,
          iconColor: Colors.orange,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total rendez-vous',
          value:
              isLoading ? '...' : (stats?.totalAppointments.toString() ?? '0'),
          icon: Icons.calendar_today,
          iconColor: Colors.purple,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildStatCardsForTablet(bool isLoading, StatsEntity? stats) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total utilisateurs',
            value: isLoading ? '...' : (stats?.totalUsers.toString() ?? '0'),
            icon: Icons.people,
            iconColor: Colors.blue,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total médecins',
            value: isLoading ? '...' : (stats?.totalDoctors.toString() ?? '0'),
            icon: Icons.local_hospital,
            iconColor: Colors.green,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total patients',
            value: isLoading ? '...' : (stats?.totalPatients.toString() ?? '0'),
            icon: Icons.people_outline,
            iconColor: Colors.orange,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total rendez-vous',
            value:
                isLoading
                    ? '...'
                    : (stats?.totalAppointments.toString() ?? '0'),
            icon: Icons.calendar_today,
            iconColor: Colors.purple,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsForDesktop(bool isLoading, StatsEntity? stats) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      children: [
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total utilisateurs',
            value: isLoading ? '...' : (stats?.totalUsers.toString() ?? '0'),
            icon: Icons.people,
            iconColor: Colors.blue,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total médecins',
            value: isLoading ? '...' : (stats?.totalDoctors.toString() ?? '0'),
            icon: Icons.local_hospital,
            iconColor: Colors.green,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total patients',
            value: isLoading ? '...' : (stats?.totalPatients.toString() ?? '0'),
            icon: Icons.people_outline,
            iconColor: Colors.orange,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total rendez-vous',
            value:
                isLoading
                    ? '...'
                    : (stats?.totalAppointments.toString() ?? '0'),
            icon: Icons.calendar_today,
            iconColor: Colors.purple,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}
