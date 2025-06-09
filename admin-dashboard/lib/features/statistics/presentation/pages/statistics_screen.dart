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
      title: 'Statistiques',
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
                child: Text(
                  'Tableau de bord des statistiques',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // User Activity Statistics
              _buildUserActivitySection(),
              SizedBox(height: 32.h),

              // Basic Statistics
              _buildPlatformOverviewSection(),
              SizedBox(height: 32.h),

              // Appointment Statistics
              _buildAppointmentStatisticsSection(),
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
          'Statistiques d\'activité des utilisateurs',
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
              return _buildLoadingStatsForMobile();
            }

            return _buildEnhancedStatsForMobile(
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

  Widget _buildPlatformOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de la plateforme',
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

            return ResponsiveLayout(
              mobile: _buildBasicStatsForMobile(isLoading, stats),
              tablet: _buildBasicStatsForTablet(isLoading, stats),
              desktop: _buildBasicStatsForDesktop(isLoading, stats),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques des rendez-vous',
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
                      'Aucune donnée de rendez-vous disponible',
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

  Widget _buildBasicStatsForMobile(bool isLoading, StatsEntity? stats) {
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

  Widget _buildBasicStatsForTablet(bool isLoading, StatsEntity? stats) {
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

  Widget _buildBasicStatsForDesktop(bool isLoading, StatsEntity? stats) {
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

  Widget _buildAppointmentStatsGrid(StatsEntity stats) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          StatCard(
            title: 'Rendez-vous en attente',
            value: stats.pendingAppointments.toString(),
            icon: Icons.schedule,
            iconColor: Colors.orange,
          ),
          SizedBox(height: 16.h),
          StatCard(
            title: 'Rendez-vous terminés',
            value: stats.completedAppointments.toString(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
          ),
          SizedBox(height: 16.h),
          StatCard(
            title: 'Rendez-vous annulés',
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
              title: 'Rendez-vous en attente',
              value: stats.pendingAppointments.toString(),
              icon: Icons.schedule,
              iconColor: Colors.orange,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Rendez-vous terminés',
              value: stats.completedAppointments.toString(),
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 2,
            child: StatCard(
              title: 'Rendez-vous annulés',
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
              title: 'Rendez-vous en attente',
              value: stats.pendingAppointments.toString(),
              icon: Icons.schedule,
              iconColor: Colors.orange,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Rendez-vous terminés',
              value: stats.completedAppointments.toString(),
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
          ),
          StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: StatCard(
              title: 'Rendez-vous annulés',
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
}
