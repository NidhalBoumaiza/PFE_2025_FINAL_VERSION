// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../constants/routes.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../widgets/responsive_layout.dart';
import '../../../../widgets/dashboard/stat_card.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/entities/stats_entity.dart';
import '../../../users/presentation/bloc/users_bloc.dart';
import '../../../users/presentation/bloc/users_event.dart';
import '../../../users/presentation/bloc/users_state.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<DashboardBloc>().add(LoadStats());
    context.read<UsersBloc>().add(LoadUserStatistics());
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      title: 'Statistics',
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
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
                      'Statistics Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // User Activity Statistics
              _buildUserActivitySection(),
              SizedBox(height: 32.h),

              // Basic Statistics
              _buildBasicStatsSection(),
              SizedBox(height: 32.h),

              // Appointment Statistics
              _buildAppointmentStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserActivitySection() {
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
        BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            int activePatients = 0;
            int inactivePatients = 0;
            int activeDoctors = 0;
            int inactiveDoctors = 0;

            if (state is UserStatisticsLoaded) {
              activePatients = state.statistics['activePatients'] ?? 0;
              inactivePatients = state.statistics['inactivePatients'] ?? 0;
              activeDoctors = state.statistics['activeDoctors'] ?? 0;
              inactiveDoctors = state.statistics['inactiveDoctors'] ?? 0;
            }

            if (state is UserStatisticsLoading) {
              return _buildLoadingStatsGrid();
            }

            return _buildEnhancedStatsGrid(
              activePatients,
              inactivePatients,
              activeDoctors,
              inactiveDoctors,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final isLoading = state is DashboardLoading;
            final StatsEntity? stats =
                state is StatsLoaded ? state.stats : null;

            return _buildBasicStatsGrid(isLoading, stats);
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Statistics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final isLoading = state is DashboardLoading;
            final StatsEntity? stats =
                state is StatsLoaded ? state.stats : null;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (stats == null) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Center(
                    child: Text(
                      'No appointment data available',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }

            return _buildAppointmentStatsGrid(stats);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingStatsGrid() {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildLoadingStatCard('Active Patients', Colors.green),
          SizedBox(height: 16.h),
          _buildLoadingStatCard('Inactive Patients', Colors.orange),
          SizedBox(height: 16.h),
          _buildLoadingStatCard('Active Doctors', Colors.blue),
          SizedBox(height: 16.h),
          _buildLoadingStatCard('Inactive Doctors', Colors.red),
        ],
      ),
      tablet: StaggeredGrid.count(
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
      ),
      desktop: StaggeredGrid.count(
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
      ),
    );
  }

  Widget _buildEnhancedStatsGrid(
    int activePatients,
    int inactivePatients,
    int activeDoctors,
    int inactiveDoctors,
  ) {
    return ResponsiveLayout(
      mobile: Column(
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
      ),
      tablet: StaggeredGrid.count(
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
      ),
      desktop: StaggeredGrid.count(
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
      ),
    );
  }

  Widget _buildBasicStatsGrid(bool isLoading, StatsEntity? stats) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          StatCard(
            title: 'Total Users',
            value:
                isLoading || stats == null
                    ? '...'
                    : stats.totalUsers.toString(),
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
      ),
      tablet: StaggeredGrid.count(
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
      ),
      desktop: StaggeredGrid.count(
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
      ),
    );
  }

  Widget _buildAppointmentStatsGrid(StatsEntity stats) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          StatCard(
            title: 'Pending Appointments',
            value: stats.pendingAppointments.toString(),
            icon: Icons.schedule,
            iconColor: Colors.orange,
          ),
          SizedBox(height: 16.h),
          StatCard(
            title: 'Completed Appointments',
            value: stats.completedAppointments.toString(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
          ),
          SizedBox(height: 16.h),
          StatCard(
            title: 'Cancelled Appointments',
            value: stats.cancelledAppointments.toString(),
            icon: Icons.cancel,
            iconColor: Colors.red,
          ),
        ],
      ),
      tablet: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        children: [
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Pending Appointments',
              value: stats.pendingAppointments.toString(),
              icon: Icons.schedule,
              iconColor: Colors.orange,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Completed Appointments',
              value: stats.completedAppointments.toString(),
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: StatCard(
              title: 'Cancelled Appointments',
              value: stats.cancelledAppointments.toString(),
              icon: Icons.cancel,
              iconColor: Colors.red,
            ),
          ),
        ],
      ),
      desktop: StaggeredGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        children: [
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Pending Appointments',
              value: stats.pendingAppointments.toString(),
              icon: Icons.schedule,
              iconColor: Colors.orange,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Completed Appointments',
              value: stats.completedAppointments.toString(),
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Cancelled Appointments',
              value: stats.cancelledAppointments.toString(),
              icon: Icons.cancel,
              iconColor: Colors.red,
            ),
          ),
        ],
      ),
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
    Color backgroundColor,
  ) {
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
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
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
}
