import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/features/localisation/presentation/pages/pharmacie_page.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_patient.dart';
import 'package:medical_app/features/profile/presentation/pages/ProfilPatient.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/RendezVousPatient.dart';
import 'package:medical_app/features/settings/presentation/pages/settings_patient.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medical_app/features/messagerie/presentation/pages/conversations_list_screen.dart';
import 'package:medical_app/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:medical_app/features/secours/presentation/pages/secours_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medical_app/core/widgets/location_activation_screen.dart';
import 'package:medical_app/features/ai_chatbot/presentation/pages/ai_chatbot_page.dart';
import 'package:medical_app/features/ai_chatbot/presentation/bloc/ai_chatbot_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../dashboard/presentation/pages/dashboard_patient.dart';
import '../../../profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';
import '../../../rendez_vous/presentation/pages/appointments_patients.dart';
import '../../../messagerie/presentation/blocs/conversation BLoC/conversations_bloc.dart';
import '../../../messagerie/presentation/blocs/conversation BLoC/conversations_state.dart';
import '../../../messagerie/presentation/blocs/conversation BLoC/conversations_event.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'dart:async';
import 'package:medical_app/core/widgets/location_indicator.dart';

class HomePatient extends StatefulWidget {
  const HomePatient({super.key});

  @override
  State<HomePatient> createState() => _HomePatientState();
}

class _HomePatientState extends State<HomePatient> {
  int _selectedIndex = 0;
  String userId = '';
  String patientName = 'Nom du patient par défaut';
  String email = 'Email par défaut';
  DateTime? _selectedAppointmentDate;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _printFCMToken(); // Print FCM token for testing

    // Always show location activation screen when app is opened
    // Small delay to ensure context is available
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;

      _showLocationActivationScreen();

      // Always try to update location even if user cancels the permission dialog
      if (userId.isNotEmpty) {
        _updateUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');
    if (userJson != null) {
      print('User JSON: $userJson');
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        userId = userMap['id'] as String? ?? '';
        patientName =
            '${userMap['name'] ?? ''} ${userMap['lastName'] ?? ''}'.trim();
        email = userMap['email'] as String? ?? 'default_email'.tr;
      });

      // Start periodic location updates if we have a user ID
      if (userId.isNotEmpty) {
        _startPeriodicLocationUpdates();
      }
    }
  }

  // Print FCM token for testing
  Future<void> _printFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('FCM_TOKEN');
      print('==========================');
      print('PATIENT FCM TOKEN for testing: $token');
      print('==========================');
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Function to select a date for appointments
  Future<void> _selectAppointmentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedAppointmentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedAppointmentDate) {
      setState(() {
        _selectedAppointmentDate = picked;
        _updatePages();
      });
    }
  }

  // Reset appointment date filter
  void _resetAppointmentDateFilter() {
    setState(() {
      _selectedAppointmentDate = null;
      _updatePages();
    });
  }

  // Update pages list with current state
  void _updatePages() {
    setState(() {
      _pages = [
        const Dashboardpatient(),
        AppointmentsPatients(showAppBar: false),
        const ConversationsScreen(showAppBar: false),
        const ProfilePatient(),
      ];
    });
  }

  List<BottomNavigationBarItem> get _navItems => [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined, size: 22.sp),
      activeIcon: Icon(Icons.home_filled, size: 24.sp),
      label: 'Accueil',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined, size: 22.sp),
      activeIcon: Icon(Icons.calendar_today, size: 24.sp),
      label: 'Rendez-vous',
    ),
    // Message with badge
    BottomNavigationBarItem(
      icon: _buildMessageIcon(false),
      activeIcon: _buildMessageIcon(true),
      label: 'Messages',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline, size: 22.sp),
      activeIcon: Icon(Icons.person, size: 24.sp),
      label: 'Profil',
    ),
  ];

  // Widget to display message icon with badge for unread messages
  Widget _buildMessageIcon(bool isActive) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      buildWhen: (previous, current) {
        // Only rebuild when conversations loaded or loading state changes
        return current is ConversationsLoaded ||
            current is ConversationsLoading ||
            current is ConversationsError;
      },
      builder: (context, state) {
        int unreadCount = 0;

        if (state is ConversationsLoaded) {
          unreadCount =
              state.conversations
                  .where(
                    (conv) =>
                        !conv.lastMessageRead && conv.lastMessage.isNotEmpty,
                  )
                  .length;
        }

        // Load conversations if not loaded yet and we have userId
        if (state is! ConversationsLoaded &&
            state is! ConversationsLoading &&
            userId.isNotEmpty) {
          // Trigger loading conversations
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ConversationsBloc>().add(
                FetchConversationsEvent(userId: userId, isDoctor: false),
              );
            }
          });
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: isActive ? 24.sp : 22.sp,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: BoxConstraints(minWidth: 14.r, minHeight: 14.r),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  late List<Widget> _pages = [
    const Dashboardpatient(),
    AppointmentsPatients(showAppBar: false),
    const ConversationsScreen(showAppBar: false),
    const ProfilePatient(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // When messages tab is selected, mark all conversations as read
    if (index == 2 && userId.isNotEmpty) {
      // Check if there are any unread messages before dispatching the event
      final conversationsState = context.read<ConversationsBloc>().state;
      if (conversationsState is ConversationsLoaded) {
        final unreadCount =
            conversationsState.conversations
                .where(
                  (conv) =>
                      !conv.lastMessageRead && conv.lastMessage.isNotEmpty,
                )
                .length;

        if (unreadCount > 0) {
          context.read<ConversationsBloc>().add(
            MarkAllConversationsReadEvent(userId: userId),
          );
        }
      } else {
        // If we don't know the state yet, just mark all as read to be safe
        context.read<ConversationsBloc>().add(
          MarkAllConversationsReadEvent(userId: userId),
        );
      }
    }
  }

  void _logout() {
    Get.dialog(
      AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: Get.back, child: Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('CACHED_USER');
                await prefs.remove('TOKEN');

                // Replace the entire navigation stack to prevent going back
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );

                // Optional: show success message
                Get.snackbar(
                  'Succès',
                  'Déconnexion réussie',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                // Show error message if logout fails
                Get.snackbar(
                  'Erreur',
                  'Erreur lors de la déconnexion',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                print("Logout error: $e");
              }
            },
            child: Text(
              'Déconnexion',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    int? badgeCount,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final textColor =
        color ?? (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.white);
    final iconColor =
        color ?? (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.white);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show the location activation screen every time the app is opened
  void _showLocationActivationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationActivationScreen(
              onLocationEnabled: () {
                if (userId.isNotEmpty) {
                  _updateUserLocation();
                }
              },
            ),
      ),
    ).then((enabled) {
      // Even if user denied, try to get location with current permissions
      if (enabled != true && userId.isNotEmpty) {
        _updateUserLocation();
      }
    });
  }

  // Placeholder methods to maintain compatibility with existing code
  void _checkLocationPermission() {
    _showLocationActivationScreen();
  }

  void _showLocationPermissionDialog() {
    _showLocationActivationScreen();
  }

  void _showLocationServiceDialog() {
    _showLocationActivationScreen();
  }

  void _requestLocationPermission() {
    _showLocationActivationScreen();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    _showLocationActivationScreen();
  }

  // Update user location using the improved service
  Future<void> _updateUserLocation() async {
    try {
      if (userId.isEmpty) return;

      // Get fresh location
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        print(
          'Got accurate position: ${position.latitude}, ${position.longitude}',
        );

        // Update user location in Firestore
        final success = await LocationService.updateUserLocation(
          userId,
          'patient',
        );
        if (success) {
          print('Location updated successfully for user: $userId');
        } else {
          print('Failed to update location for user: $userId');
        }
      } else {
        print('Could not get current position');
      }
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  void _startPeriodicLocationUpdates() {
    // Cancel any existing timer
    _locationUpdateTimer?.cancel();

    // Update location immediately
    _updateUserLocation();

    // Set up timer for periodic updates (every 15 minutes)
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _updateUserLocation();
    });
  }

  // Get the title for the app bar based on the selected index
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'MediLink';
      case 1:
        return 'Rendez-vous';
      case 2:
        return 'Messages';
      case 3:
        return 'Profil';
      default:
        return 'MediLink';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    print("1111111111111111111111111111111");
    print("userId : $userId");
    return SafeArea(
      child: BlocListener<UpdateUserBloc, UpdateUserState>(
        listener: (context, state) {
          if (state is UpdateUserSuccess) {
            setState(() {
              patientName = '${state.user.name} ${state.user.lastName}'.trim();
              email = state.user.email;
              userId = state.user.id ?? '';
              _pages = [
                const Dashboardpatient(),
                AppointmentsPatients(showAppBar: false),
                const ConversationsScreen(showAppBar: false),
                const ProfilePatient(),
              ];
            });
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
            title: Text(
              _getAppBarTitle(),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_selectedIndex == 1) ...[
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () => _selectAppointmentDate(context),
                  tooltip: 'Filtrer par date',
                ),
                if (_selectedAppointmentDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _resetAppointmentDateFilter,
                    tooltip: 'Réinitialiser le filtre',
                  ),
              ],
              NotificationBadge(iconColor: Colors.white, iconSize: 24),

              SizedBox(width: 8.w),
            ],
          ),
          body: _pages[_selectedIndex],

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode ? theme.colorScheme.surface : AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : AppColors.textSecondary.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                items: _navItems,
                currentIndex: _selectedIndex,
                selectedItemColor: AppColors.primaryColor,
                unselectedItemColor:
                    isDarkMode
                        ? theme.textTheme.bodySmall?.color?.withOpacity(0.7)
                        : AppColors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                    isDarkMode
                        ? theme.colorScheme.surface
                        : AppColors.whiteColor,
                elevation: 10,
                selectedLabelStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                onTap: _onItemTapped,
              ),
            ),
          ),

          drawer: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Drawer(
              width: MediaQuery.of(context).size.width * 0.8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
              ),
              elevation: 10,
              shadowColor: Colors.black26,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.colorScheme.surface : null,
                  gradient:
                      isDarkMode
                          ? null
                          : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2fa7bb),
                              const Color(0xFF2fa7bb).withOpacity(0.85),
                            ],
                          ),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 50,
                        left: 25,
                        right: 25,
                        bottom: 25,
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  isDarkMode
                                      ? theme.colorScheme.primary.withOpacity(
                                        0.2,
                                      )
                                      : AppColors.whiteColor,
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color:
                                    isDarkMode
                                        ? theme.colorScheme.primary
                                        : const Color(0xFF2fa7bb),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            patientName,
                            style: GoogleFonts.raleway(
                              fontSize: 18,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodyLarge?.color
                                      : AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'patient'.tr,
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodyMedium?.color
                                      : AppColors.whiteColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            email,
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodySmall?.color
                                      : AppColors.whiteColor.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                    ),
                    SizedBox(height: 15),

                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        children: [
                          _buildDrawerItem(
                            icon: FontAwesomeIcons.hospital,
                            title: 'hospitals'.tr,
                            onTap: () {
                              Navigator.pop(context);
                              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                context,
                                const PharmaciePage(),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            icon: FontAwesomeIcons.kitMedical,
                            title: 'first_aid'.tr,
                            onTap: () {
                              Navigator.pop(context);
                              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                context,
                                const SecoursScreen(),
                              );
                            },
                          ),

                          _buildDrawerItem(
                            icon: FontAwesomeIcons.gear,
                            title: 'settings'.tr,
                            onTap: () {
                              Navigator.pop(context);
                              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                context,
                                const SettingsPatient(),
                              );
                            },
                          ),
                          // Theme toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: BlocBuilder<ThemeCubit, ThemeState>(
                              builder: (context, state) {
                                final isDarkModeState =
                                    state is ThemeLoaded
                                        ? state.themeMode == ThemeMode.dark
                                        : false;
                                return Row(
                                  children: [
                                    Icon(
                                      isDarkModeState
                                          ? FontAwesomeIcons.moon
                                          : FontAwesomeIcons.sun,
                                      color:
                                          isDarkMode
                                              ? theme.textTheme.bodyLarge?.color
                                              : Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      isDarkModeState
                                          ? 'dark_mode'.tr
                                          : 'light_mode'.tr,
                                      style: GoogleFonts.raleway(
                                        color:
                                            isDarkMode
                                                ? theme
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color
                                                : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: const ThemeCubitSwitch(
                                        compact: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      child: _buildDrawerItem(
                        icon: FontAwesomeIcons.rightFromBracket,
                        title: 'logout'.tr,
                        onTap: _logout,
                        color: Colors.red[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              print('=== NAVIGATION TO AI CHATBOT DEBUG ===');
              print('Navigating to AiChatbotPage...');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiChatbotPage()),
              );
            },
            backgroundColor: AppColors.primaryColor,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 28.sp),
            tooltip: 'ai_assistant'.tr,
          ),
        ),
      ),
    );
  }
}
