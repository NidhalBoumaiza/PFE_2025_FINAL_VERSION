// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../bloc/users_bloc.dart';
import '../widgets/user_info_modal.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import 'patient_details_page.dart';
import 'doctor_details_page.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('🚀 UsersScreen: initState called');
    _tabController = TabController(length: 3, vsync: this);

    // Load data safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 UsersScreen: Post-frame callback executing');
      if (mounted) {
        print('✅ UsersScreen: Widget is mounted, loading data...');
        context.read<UsersBloc>().add(LoadAllUsers());
        context.read<UsersBloc>().add(LoadUserStatistics());
        context.read<UsersBloc>().add(StartListeningToUsers());
      } else {
        print('❌ UsersScreen: Widget not mounted, skipping data load');
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ UsersScreen: dispose called');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ UsersScreen: Building widget');
    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        print('👂 UsersScreen: BlocListener state: ${state.runtimeType}');
        if (state is UserDeleted) {
          print('✅ UsersScreen: User deleted successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(state.message),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is UserOperationError) {
          print('❌ UsersScreen: User operation error: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () {
                  // Refresh the data
                  context.read<UsersBloc>().add(LoadAllUsers());
                },
              ),
            ),
          );
        } else if (state is UserOperationLoading) {
          print('⏳ UsersScreen: User operation loading');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Suppression de l\'utilisateur...'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: MainLayout(
        selectedIndex: 1,
        title: 'Utilisateurs',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildHeader(),
            _buildEnhancedStatsCards(),
            _buildEnhancedTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllUsersTab(),
                  _buildPatientsTab(),
                  _buildDoctorsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeader() {
  //   print('🎯 UsersScreen: Building header');
  //   return Container(
  //     padding: EdgeInsets.all(16.w),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.1),
  //           spreadRadius: 1,
  //           blurRadius: 3,
  //           offset: const Offset(0, 1),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'User Management',
  //               style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
  //             ),
  //             SizedBox(height: 4.h),
  //             Text(
  //               'View and manage your users',
  //               style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
  //             ),
  //           ],
  //         ),
  //         Row(
  //           children: [
  //             BlocBuilder<UsersBloc, UsersState>(
  //               buildWhen: (previous, current) {
  //                 print(
  //                   '🔄 UsersScreen: Header BlocBuilder buildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
  //                 );
  //                 return current is AllUsersLoaded ||
  //                     current is AllUsersLoading ||
  //                     current is UsersError;
  //               },
  //               builder: (context, state) {
  //                 print(
  //                   '📊 UsersScreen: Header BlocBuilder state: ${state.runtimeType}',
  //                 );
  //                 if (state is AllUsersLoaded) {
  //                   final totalUsers =
  //                       state.patients.length + state.doctors.length;
  //                   print(
  //                     '📊 UsersScreen: Header showing total users: $totalUsers',
  //                   );
  //                   return Row(
  //                     children: [
  //                       Icon(
  //                         Icons.people,
  //                         size: 20.sp,
  //                         color: Colors.grey[600],
  //                       ),
  //                       SizedBox(width: 8.w),
  //                       Text(
  //                         '$totalUsers Total Users',
  //                         style: TextStyle(
  //                           fontSize: 14.sp,
  //                           color: Colors.grey[600],
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                   );
  //                 }
  //                 print('⏳ UsersScreen: Header showing loading state');
  //                 return Row(
  //                   children: [
  //                     SizedBox(
  //                       width: 16.w,
  //                       height: 16.h,
  //                       child: CircularProgressIndicator(strokeWidth: 2),
  //                     ),
  //                     SizedBox(width: 12.w),
  //                     Text(
  //                       'Loading user data...',
  //                       style: TextStyle(
  //                         fontSize: 14.sp,
  //                         color: Colors.grey[600],
  //                       ),
  //                     ),
  //                   ],
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEnhancedStatsCards() {
    print('📊 UsersScreen: Building enhanced stats cards');
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        print(
          '📈 UsersScreen: Stats BlocBuilder main state: ${state.runtimeType}',
        );
        int totalPatients = 0;
        int totalDoctors = 0;
        int activePatients = 0;
        int inactivePatients = 0;
        int activeDoctors = 0;
        int inactiveDoctors = 0;

        // Get current users data from cached data or state
        List<PatientEntity> patients = [];
        List<DoctorEntity> doctors = [];
        final bloc = context.read<UsersBloc>();

        if (state is AllUsersLoaded) {
          patients = state.patients;
          doctors = state.doctors;
          print(
            '✅ UsersScreen: All users loaded from state - ${patients.length} patients, ${doctors.length} doctors',
          );
        } else {
          // Try to get cached data from bloc
          patients = bloc.currentPatients;
          doctors = bloc.currentDoctors;
          print(
            '💾 UsersScreen: All users loaded from cache - ${patients.length} patients, ${doctors.length} doctors',
          );
        }

        // Get activity statistics from UserStatisticsLoaded state
        return BlocBuilder<UsersBloc, UsersState>(
          buildWhen: (previous, current) {
            print(
              '🔄 UsersScreen: Stats BlocBuilder buildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
            );
            return current is UserStatisticsLoaded ||
                current is AllUsersLoaded ||
                current is UserStatisticsLoading;
          },
          builder: (context, statsState) {
            print(
              '📊 UsersScreen: Stats BlocBuilder nested state: ${statsState.runtimeType}',
            );
            if (statsState is UserStatisticsLoaded) {
              activePatients = statsState.statistics['activePatients'] ?? 0;
              inactivePatients = statsState.statistics['inactivePatients'] ?? 0;
              activeDoctors = statsState.statistics['activeDoctors'] ?? 0;
              inactiveDoctors = statsState.statistics['inactiveDoctors'] ?? 0;
              totalPatients = activePatients + inactivePatients;
              totalDoctors = activeDoctors + inactiveDoctors;
              print(
                '🎯 UsersScreen: Activity stats loaded - Active patients: $activePatients, Inactive patients: $inactivePatients, Active doctors: $activeDoctors, Inactive doctors: $inactiveDoctors',
              );
            }

            // Show loading state for statistics
            if (statsState is UserStatisticsLoading) {
              print('⏳ UsersScreen: Statistics loading state');
              return Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLoadingStatCard(
                        'Active Patients',
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildLoadingStatCard(
                        'Inactive Patients',
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildLoadingStatCard(
                        'Active Doctors',
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildLoadingStatCard(
                        'Inactive Doctors',
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }

            print('🎨 UsersScreen: Building stats cards with final values');
            return Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildEnhancedStatCard(
                      'Active Patients',
                      activePatients.toString(),
                      Icons.trending_up,
                      Colors.green,
                      '5+ appointments',
                      Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      'Inactive Patients',
                      inactivePatients.toString(),
                      Icons.trending_down,
                      Colors.orange,
                      'Less than 5 appointments',
                      Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      'Active Doctors',
                      activeDoctors.toString(),
                      Icons.medical_services,
                      Colors.blue,
                      '5+ appointments',
                      Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
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
          },
        );
      },
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
            colors: [backgroundColor, backgroundColor.withOpacity(0.3)],
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
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                if (showPulse)
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
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
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
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
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.maxFinite,
              height: 16.h,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14.sp),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Tous les utilisateurs'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.personal_injury, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Patients'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Médecins'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllUsersTab() {
    print('👥 UsersScreen: Building all users tab');
    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (previous, current) {
        return current is AllUsersLoaded ||
            current is AllUsersLoading ||
            current is UserStatisticsLoaded ||
            current is UsersError;
      },
      builder: (context, state) {
        print(
          '🏗️ UsersScreen: All users tab BlocBuilder state: ${state.runtimeType}',
        );

        // Get current users data from cached data or state
        List<PatientEntity> patients = [];
        List<DoctorEntity> doctors = [];
        final bloc = context.read<UsersBloc>();

        if (state is AllUsersLoaded) {
          patients = state.patients;
          doctors = state.doctors;
          print(
            '✅ UsersScreen: All users loaded from state - ${patients.length} patients, ${doctors.length} doctors',
          );
        } else {
          // Try to get cached data from bloc
          patients = bloc.currentPatients;
          doctors = bloc.currentDoctors;
          print(
            '💾 UsersScreen: All users loaded from cache - ${patients.length} patients, ${doctors.length} doctors',
          );
        }

        if (state is AllUsersLoading) {
          print('⏳ UsersScreen: All users loading');
          return Center(child: CircularProgressIndicator());
        }

        if (state is UsersError) {
          print('❌ UsersScreen: Users error - ${state.message}');
          return _buildErrorState(state.message);
        }

        if (patients.isNotEmpty || doctors.isNotEmpty) {
          print(
            '✅ UsersScreen: All users available - ${patients.length} patients, ${doctors.length} doctors',
          );
          return _buildCombinedUsersTable(patients, doctors);
        }

        print('📭 UsersScreen: No data available state');
        return Center(child: Text('Aucune donnée disponible'));
      },
    );
  }

  Widget _buildPatientsTab() {
    print('👤 UsersScreen: Building patients tab');
    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (previous, current) {
        return current is AllUsersLoaded ||
            current is AllUsersLoading ||
            current is PatientsLoaded ||
            current is PatientsLoading ||
            current is UserStatisticsLoaded ||
            current is UsersError;
      },
      builder: (context, state) {
        print(
          '🏗️ UsersScreen: Patients tab BlocBuilder state: ${state.runtimeType}',
        );
        List<PatientEntity> patients = [];
        bool isLoading = false;

        if (state is AllUsersLoading || state is PatientsLoading) {
          print('⏳ UsersScreen: Patients loading');
          isLoading = true;
        } else if (state is AllUsersLoaded) {
          patients = state.patients;
          print(
            '✅ UsersScreen: Patients from AllUsersLoaded - ${patients.length} patients',
          );
        } else if (state is PatientsLoaded) {
          patients = state.patients;
          print(
            '✅ UsersScreen: Patients from PatientsLoaded - ${patients.length} patients',
          );
        } else {
          // Try to get cached data from bloc
          patients = context.read<UsersBloc>().currentPatients;
          print(
            '💾 UsersScreen: Patients from cache - ${patients.length} patients',
          );
        }

        if (isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return _buildPatientsTable(patients);
      },
    );
  }

  Widget _buildDoctorsTab() {
    print('👨‍⚕️ UsersScreen: Building doctors tab');
    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (previous, current) {
        return current is AllUsersLoaded ||
            current is AllUsersLoading ||
            current is DoctorsLoaded ||
            current is DoctorsLoading ||
            current is UserStatisticsLoaded ||
            current is UsersError;
      },
      builder: (context, state) {
        print(
          '🏗️ UsersScreen: Doctors tab BlocBuilder state: ${state.runtimeType}',
        );
        List<DoctorEntity> doctors = [];
        bool isLoading = false;

        if (state is AllUsersLoading || state is DoctorsLoading) {
          print('⏳ UsersScreen: Doctors loading');
          isLoading = true;
        } else if (state is AllUsersLoaded) {
          doctors = state.doctors;
          print(
            '✅ UsersScreen: Doctors from AllUsersLoaded - ${doctors.length} doctors',
          );
        } else if (state is DoctorsLoaded) {
          doctors = state.doctors;
          print(
            '✅ UsersScreen: Doctors from DoctorsLoaded - ${doctors.length} doctors',
          );
        } else {
          // Try to get cached data from bloc
          doctors = context.read<UsersBloc>().currentDoctors;
          print(
            '💾 UsersScreen: Doctors from cache - ${doctors.length} doctors',
          );
        }

        if (isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return _buildDoctorsTable(doctors);
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(fontSize: 16.sp, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.read<UsersBloc>().add(LoadAllUsers()),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedUsersTable(
    List<PatientEntity> patients,
    List<DoctorEntity> doctors,
  ) {
    if (patients.isEmpty && doctors.isEmpty) {
      return _buildEmptyState(
        'Aucun utilisateur trouvé',
        'Ajoutez votre premier utilisateur pour commencer',
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tous les utilisateurs (${patients.length + doctors.length} total)',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  headingRowHeight: 56.h,
                  dataRowHeight: 64.h,
                  columns: [
                    DataColumn2(
                      label: Text(
                        'Nom',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'E-mail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text(
                        'Téléphone',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows: [
                    ...patients.map((patient) => _buildPatientRow(patient)),
                    ...doctors.map((doctor) => _buildDoctorRow(doctor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow2 _buildPatientRow(PatientEntity patient) {
    return DataRow2(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.person, color: Colors.green, size: 16.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  patient.fullName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(patient.email)),
        DataCell(_buildTypeChip('Patient', Colors.green)),
        DataCell(Text(patient.phoneNumber ?? 'N/A')),
        DataCell(_buildActionButtons(userType: 'patient', patient: patient)),
      ],
    );
  }

  DataRow2 _buildDoctorRow(DoctorEntity doctor) {
    return DataRow2(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.blue,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  doctor.fullName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(doctor.email)),
        DataCell(_buildTypeChip('Médecin', Colors.blue)),
        DataCell(Text(doctor.phoneNumber ?? 'N/A')),
        DataCell(_buildActionButtons(userType: 'doctor', doctor: doctor)),
      ],
    );
  }

  Widget _buildTypeChip(String type, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required String userType,
    PatientEntity? patient,
    DoctorEntity? doctor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.visibility, size: 18.sp, color: Colors.blue),
          onPressed: () {
            print('👁️ UsersScreen: View pressed for $userType');
            if (userType == 'patient' && patient != null) {
              print('👁️👤 UsersScreen: Viewing patient: ${patient.fullName}');
              _showPatientDetails(patient);
            } else if (userType == 'doctor' && doctor != null) {
              print('👁️👨‍⚕️ UsersScreen: Viewing doctor: ${doctor.fullName}');
              _showDoctorDetails(doctor);
            } else {
              print(
                '❌ UsersScreen: Invalid userType or null entity for view - Type: $userType, Patient: $patient, Doctor: $doctor',
              );
            }
          },
          tooltip:
              'Voir les détails du ${userType == 'patient' ? 'patient' : 'médecin'}',
        ),
        IconButton(
          icon: Icon(Icons.delete, size: 18.sp, color: Colors.red),
          onPressed: () {
            print('🗑️ UsersScreen: Delete pressed for $userType');
            if (userType == 'patient' && patient != null) {
              print(
                '🗑️👤 UsersScreen: Confirming delete for patient: ${patient.fullName}',
              );
              _confirmDeleteUser(patient.id!, 'patient', patient.fullName);
            } else if (userType == 'doctor' && doctor != null) {
              print(
                '🗑️👨‍⚕️ UsersScreen: Confirming delete for doctor: ${doctor.fullName}',
              );
              _confirmDeleteUser(doctor.id!, 'medecin', doctor.fullName);
            } else {
              print(
                '❌ UsersScreen: Invalid userType or null entity for delete - Type: $userType, Patient: $patient, Doctor: $doctor',
              );
            }
          },
          tooltip:
              'Supprimer le ${userType == 'patient' ? 'patient' : 'médecin'}',
        ),
      ],
    );
  }

  Widget _buildPatientsTable(List<PatientEntity> patients) {
    if (patients.isEmpty) {
      return _buildEmptyState(
        'Aucun patient trouvé',
        'Aucun patient n\'est actuellement enregistré dans le système',
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients (${patients.length} total)',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 900,
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  headingRowHeight: 56.h,
                  dataRowHeight: 64.h,
                  columns: [
                    DataColumn2(
                      label: Text(
                        'Patient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'Sexe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text(
                        'Groupe sanguin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows:
                      patients
                          .map(
                            (patient) => DataRow2(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        patient.fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Age: ${patient.age ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        patient.email,
                                        style: TextStyle(fontSize: 13.sp),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        patient.phoneNumber ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(_buildGenderChip(patient.gender)),
                                DataCell(
                                  _buildBloodTypeChip(patient.bloodType),
                                ),
                                DataCell(
                                  _buildActionButtons(
                                    userType: 'patient',
                                    patient: patient,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsTable(List<DoctorEntity> doctors) {
    if (doctors.isEmpty) {
      return _buildEmptyState(
        'Aucun médecin trouvé',
        'Ajoutez votre premier médecin pour commencer',
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Médecins (${doctors.length} total)',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 900,
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  headingRowHeight: 56.h,
                  dataRowHeight: 64.h,
                  columns: [
                    DataColumn2(
                      label: Text(
                        'Médecin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(
                        'Spécialité',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text(
                        'Expérience',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows:
                      doctors
                          .map(
                            (doctor) => DataRow2(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        doctor.fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'License: ${doctor.numLicence ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        doctor.email,
                                        style: TextStyle(fontSize: 13.sp),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        doctor.phoneNumber ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  _buildSpecialityChip(doctor.speciality),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        doctor.experienceYears,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (doctor.consultationFee != null)
                                        Text(
                                          '${doctor.consultationFee} DT',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.green[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  _buildActionButtons(
                                    userType: 'doctor',
                                    doctor: doctor,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String? gender) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color:
            gender == 'Homme'
                ? Colors.blue.withOpacity(0.1)
                : Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        gender ?? 'N/A',
        style: TextStyle(
          color: gender == 'Homme' ? Colors.blue : Colors.pink,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBloodTypeChip(String? bloodType) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getBloodTypeColor(bloodType),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        bloodType ?? 'N/A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpecialityChip(String? speciality) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getSpecialityColor(speciality).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        speciality ?? 'N/A',
        style: TextStyle(
          color: _getSpecialityColor(speciality),
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBloodTypeColor(String? bloodType) {
    if (bloodType == null) return Colors.grey;
    switch (bloodType.toLowerCase()) {
      case 'a+':
        return Colors.red;
      case 'a-':
        return Colors.purple;
      case 'b+':
        return Colors.orange;
      case 'b-':
        return Colors.yellow[700]!;
      case 'ab+':
        return Colors.pink;
      case 'ab-':
        return Colors.brown;
      case 'o+':
        return Colors.green;
      case 'o-':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getSpecialityColor(String? speciality) {
    if (speciality == null) return Colors.grey;
    switch (speciality.toLowerCase()) {
      case 'cardiology':
      case 'cardiologist':
        return Colors.red;
      case 'dentist':
      case 'dentiste':
        return Colors.blue;
      case 'dermatology':
      case 'dermatologist':
        return Colors.orange;
      case 'neurology':
      case 'neurologist':
        return Colors.purple;
      case 'pediatrics':
      case 'pediatrician':
        return Colors.pink;
      case 'psychiatry':
      case 'psychiatrist':
      case 'psychologist':
        return Colors.teal;
      case 'orthopedics':
      case 'orthopedist':
        return Colors.brown;
      case 'gynecology':
      case 'gynecologist':
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  void _showPatientDetails(PatientEntity patient) {
    print(
      '👁️👤 UsersScreen: Navigating to patient details page for: ${patient.fullName}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsPage(patient: patient),
      ),
    );
  }

  void _showDoctorDetails(DoctorEntity doctor) {
    print(
      '👁️👨‍⚕️ UsersScreen: Navigating to doctor details page for: ${doctor.fullName}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsPage(doctor: doctor),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String userId, String userType, String userName) {
    print(
      '⚠️ UsersScreen: Showing delete confirmation for user: $userName (ID: $userId, Type: $userType)',
    );

    // Debug: Check if user ID exists and is valid
    if (userId.isEmpty) {
      print('❌ UsersScreen: User ID is empty!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : L\'ID utilisateur est vide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24.sp),
                SizedBox(width: 12.w),
                Text('Confirmer la suppression'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Êtes-vous sûr de vouloir supprimer cet utilisateur ?'),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nom',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userName.isNotEmpty ? userName : 'Non spécifié',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userType == 'patient' ? 'Patient' : 'Médecin',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              userType == 'patient'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (userId.isNotEmpty) {
                    context.read<UsersBloc>().add(
                      DeleteUserEvent(userId: userId, userType: userType),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur : Données utilisateur invalides'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
