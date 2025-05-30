// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../../../../config/theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/stats_entity.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../widgets/dashboard/stat_card.dart';
import '../../../../widgets/dashboard/login_chart.dart';
import '../../../../widgets/dashboard/activity_chart.dart';
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
                          icon: Icon(Icons.analytics, size: 20.sp),
                          label: Text(
                            'Advanced Stats',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.advancedStatistics,
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
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

              // Stats Cards
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

                      // Charts
                      ResponsiveLayout(
                        mobile: _buildChartsForMobile(isLoading, stats),
                        tablet: _buildChartsForTablet(isLoading, stats),
                        desktop: _buildChartsForDesktop(isLoading, stats),
                      ),
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

  Widget _buildChartsForMobile(bool isLoading, StatsEntity? stats) {
    // Convert real data to chart format
    final activityStats = _getActivityStatsFromAppointments(stats);
    final loginStats = _getLoginStatsFromAppointments(stats);

    return Column(
      children: [
        // User activity chart
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: ActivityChart(
            activityStats: activityStats,
            isLoading: isLoading,
          ),
        ),
        SizedBox(height: 16.h),
        // User login chart
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: LoginChart(loginStats: loginStats, isLoading: isLoading),
        ),
      ],
    );
  }

  Widget _buildChartsForTablet(bool isLoading, StatsEntity? stats) {
    // Convert real data to chart format
    final activityStats = _getActivityStatsFromAppointments(stats);
    final loginStats = _getLoginStatsFromAppointments(stats);

    return Column(
      children: [
        // User activity chart
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: ActivityChart(
            activityStats: activityStats,
            isLoading: isLoading,
          ),
        ),
        SizedBox(height: 16.h),
        // User login chart
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: LoginChart(loginStats: loginStats, isLoading: isLoading),
        ),
      ],
    );
  }

  Widget _buildChartsForDesktop(bool isLoading, StatsEntity? stats) {
    // Convert real data to chart format
    final activityStats = _getActivityStatsFromAppointments(stats);
    final loginStats = _getLoginStatsFromAppointments(stats);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User activity chart
        Expanded(
          child: Container(
            height: 400.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ActivityChart(
              activityStats: activityStats,
              isLoading: isLoading,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        // User login chart
        Expanded(
          child: Container(
            height: 400.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: LoginChart(loginStats: loginStats, isLoading: isLoading),
          ),
        ),
      ],
    );
  }

  // Helper methods to convert real data to chart format
  List<ActivityStats> _getActivityStatsFromAppointments(StatsEntity? stats) {
    if (stats == null) {
      return _getEmptyActivityStats();
    }

    final appointmentsPerDay = stats.appointmentsPerDay;
    final now = DateTime.now();

    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final appointmentCount = appointmentsPerDay[dayKey] ?? 0;

      // Convert appointments to activity (active users = appointments, inactive = total users - appointments)
      final activeUsers = appointmentCount;
      final inactiveUsers = (stats.totalUsers - appointmentCount).clamp(
        0,
        stats.totalUsers,
      );

      return ActivityStats(
        date: date,
        activeUsers: activeUsers,
        inactiveUsers: inactiveUsers,
      );
    });
  }

  List<LoginStats> _getLoginStatsFromAppointments(StatsEntity? stats) {
    if (stats == null) {
      return _getEmptyLoginStats();
    }

    final appointmentsPerDay = stats.appointmentsPerDay;
    final now = DateTime.now();

    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final appointmentCount = appointmentsPerDay[dayKey] ?? 0;

      // Estimate logins based on appointments (assuming each appointment involves 2 users logging in)
      final logins = appointmentCount * 2;
      final logouts = (appointmentCount * 1.5).round(); // Slightly less logouts

      return LoginStats(date: date, logins: logins, logouts: logouts);
    });
  }

  List<ActivityStats> _getEmptyActivityStats() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return ActivityStats(date: date, activeUsers: 0, inactiveUsers: 0);
    });
  }

  List<LoginStats> _getEmptyLoginStats() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return LoginStats(date: date, logins: 0, logouts: 0);
    });
  }
}
