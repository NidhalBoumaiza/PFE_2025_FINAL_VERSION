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
      title: 'Dashboard',
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
                      'Dashboard Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.people, size: 20.sp),
                          label: Text(
                            'Manage Users',
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
          'User Activity Statistics',
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
        _buildLoadingStatCard('Active Patients', Colors.green),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Inactive Patients', Colors.orange),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Active Doctors', Colors.blue),
        SizedBox(height: 16.h),
        _buildLoadingStatCard('Inactive Doctors', Colors.red),
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
          child: _buildLoadingStatCard('Active Patients', Colors.green),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Inactive Patients', Colors.orange),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Active Doctors', Colors.blue),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Inactive Doctors', Colors.red),
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
          child: _buildLoadingStatCard('Active Patients', Colors.green),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Inactive Patients', Colors.orange),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Active Doctors', Colors.blue),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildLoadingStatCard('Inactive Doctors', Colors.red),
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
        _buildEnhancedStatCard(
          'Active Patients',
          activePatients.toString(),
          Icons.trending_up,
          Colors.green,
          '5+ appointments',
          Colors.green.withValues(alpha: 0.1),
        ),
        SizedBox(height: 16.h),
        _buildEnhancedStatCard(
          'Inactive Patients',
          inactivePatients.toString(),
          Icons.trending_down,
          Colors.orange,
          'Less than 5 appointments',
          Colors.orange.withValues(alpha: 0.1),
        ),
        SizedBox(height: 16.h),
        _buildEnhancedStatCard(
          'Active Doctors',
          activeDoctors.toString(),
          Icons.medical_services,
          Colors.blue,
          '5+ appointments',
          Colors.blue.withValues(alpha: 0.1),
        ),
        SizedBox(height: 16.h),
        _buildEnhancedStatCard(
          'Inactive Doctors',
          inactiveDoctors.toString(),
          Icons.medical_services_outlined,
          Colors.red,
          'Less than 5 appointments',
          Colors.red.withValues(alpha: 0.1),
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
          child: _buildEnhancedStatCard(
            'Active Patients',
            activePatients.toString(),
            Icons.trending_up,
            Colors.green,
            '5+ appointments',
            Colors.green.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Inactive Patients',
            inactivePatients.toString(),
            Icons.trending_down,
            Colors.orange,
            'Less than 5 appointments',
            Colors.orange.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Active Doctors',
            activeDoctors.toString(),
            Icons.medical_services,
            Colors.blue,
            '5+ appointments',
            Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Inactive Doctors',
            inactiveDoctors.toString(),
            Icons.medical_services_outlined,
            Colors.red,
            'Less than 5 appointments',
            Colors.red.withValues(alpha: 0.1),
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
          child: _buildEnhancedStatCard(
            'Active Patients',
            activePatients.toString(),
            Icons.trending_up,
            Colors.green,
            '5+ appointments',
            Colors.green.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Inactive Patients',
            inactivePatients.toString(),
            Icons.trending_down,
            Colors.orange,
            'Less than 5 appointments',
            Colors.orange.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Active Doctors',
            activeDoctors.toString(),
            Icons.medical_services,
            Colors.blue,
            '5+ appointments',
            Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: _buildEnhancedStatCard(
            'Inactive Doctors',
            inactiveDoctors.toString(),
            Icons.medical_services_outlined,
            Colors.red,
            'Less than 5 appointments',
            Colors.red.withValues(alpha: 0.1),
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

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    Color backgroundColor, {
    bool showPulse = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withValues(alpha: 0.3)],
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
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                if (showPulse)
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsForMobile(bool isLoading, StatsEntity? stats) {
    return Column(
      children: [
        StatCard(
          title: 'Total Users',
          value:
              isLoading || stats == null ? '...' : stats.totalUsers.toString(),
          icon: Icons.people,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total Doctors',
          value:
              isLoading || stats == null
                  ? '...'
                  : stats.totalDoctors.toString(),
          icon: Icons.medical_services,
          iconColor: Colors.blue,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total Patients',
          value:
              isLoading || stats == null
                  ? '...'
                  : stats.totalPatients.toString(),
          icon: Icons.personal_injury,
          iconColor: Colors.green,
          isLoading: isLoading,
        ),
        SizedBox(height: 16.h),
        StatCard(
          title: 'Total Appointments',
          value:
              isLoading || stats == null
                  ? '...'
                  : stats.totalAppointments.toString(),
          icon: Icons.calendar_today,
          iconColor: Colors.orange,
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
            title: 'Total Users',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalUsers.toString(),
            icon: Icons.people,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Doctors',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalDoctors.toString(),
            icon: Icons.medical_services,
            iconColor: Colors.blue,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Patients',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalPatients.toString(),
            icon: Icons.personal_injury,
            iconColor: Colors.green,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Appointments',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalAppointments.toString(),
            icon: Icons.calendar_today,
            iconColor: Colors.orange,
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
            title: 'Total Users',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalUsers.toString(),
            icon: Icons.people,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Doctors',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalDoctors.toString(),
            icon: Icons.medical_services,
            iconColor: Colors.blue,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Patients',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalPatients.toString(),
            icon: Icons.personal_injury,
            iconColor: Colors.green,
            isLoading: isLoading,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Appointments',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalAppointments.toString(),
            icon: Icons.calendar_today,
            iconColor: Colors.orange,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(bool isLoading, StatsEntity? stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (stats != null) ...[
              _buildInfoRow(
                'Active Users',
                '${stats.totalUsers}',
                Icons.people,
                Colors.green,
              ),
              SizedBox(height: 12.h),
              _buildInfoRow(
                'Medical Professionals',
                '${stats.totalDoctors}',
                Icons.medical_services,
                Colors.blue,
              ),
              SizedBox(height: 12.h),
              _buildInfoRow(
                'Registered Patients',
                '${stats.totalPatients}',
                Icons.personal_injury,
                Colors.orange,
              ),
              SizedBox(height: 12.h),
              _buildInfoRow(
                'Total Appointments',
                '${stats.totalAppointments}',
                Icons.calendar_today,
                Colors.purple,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'The activity statistics above show users based on their appointment history. For detailed analytics and charts, visit the Advanced Statistics section.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Text(
                'No data available',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
