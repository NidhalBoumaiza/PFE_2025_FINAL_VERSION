import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/appointment_details_page.dart';
import 'package:medical_app/injection_container.dart' as di;

import '../../utils/notification_utils.dart';

class NotificationsMedecin extends StatefulWidget {
  const NotificationsMedecin({super.key});

  @override
  State<NotificationsMedecin> createState() => _NotificationsMedecinState();
}

class _NotificationsMedecinState extends State<NotificationsMedecin> {
  String _selectedFilter = 'all';
  UserEntity? _currentUser;
  bool _isInitialized = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if already initialized and user is available
    if (_isInitialized && _currentUser?.id != null) {
      _refreshNotifications(showLoading: false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();

      // Validate user data
      if (user.id == null || user.id!.isEmpty) {
        setState(() {
          _isInitialized = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Données utilisateur invalides')),
          );
        }
        return;
      }

      setState(() {
        _currentUser = user;
        _isInitialized = true;
      });

      // Load notifications for the current user
      _refreshNotifications();
    } catch (e) {
      setState(() {
        _isInitialized = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données utilisateur'),
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications({bool showLoading = true}) async {
    if (_currentUser?.id == null) {
      return;
    }

    try {
      // Load notifications only - don't mark as read automatically
      context.read<NotificationBloc>().add(
        GetNotificationsEvent(userId: _currentUser!.id!),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'actualisation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () {
              if (_currentUser?.id != null) {
                context.read<NotificationBloc>().add(
                  MarkAllNotificationsAsReadEvent(userId: _currentUser!.id!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Toutes les notifications ont été marquées comme lues',
                    ),
                  ),
                );
              }
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) {
          // Listen for these specific state changes
          return current is NotificationsLoaded || current is NotificationError;
        },
        listener: (context, state) {
          if (state is NotificationError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        buildWhen: (previous, current) {
          // Only rebuild for states that actually affect the UI
          return current is NotificationsLoaded ||
              current is NotificationError ||
              current is NotificationLoading;
        },
        builder: (context, state) {
          // Handle loading state
          if (state is NotificationLoading || !_isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Chargement des notifications',
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show content based on loaded state
          if (state is NotificationsLoaded) {
            final notifications = state.notifications;

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshNotifications,
              color: AppColors.primaryColor,
              child:
                  notifications.isEmpty
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 80.sp,
                                    color:
                                        isDarkMode
                                            ? theme.iconTheme.color
                                                ?.withOpacity(0.4)
                                            : Colors.grey[400],
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Aucune notification',
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          _buildFilterChips(),
                          Expanded(
                            child: _buildNotificationList(notifications),
                          ),
                        ],
                      ),
            );
          } else if (state is NotificationError) {
            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshNotifications,
              color: AppColors.primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60.sp,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: _refreshNotifications,
                            icon: Icon(Icons.refresh),
                            label: Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Default loading indicator for any other state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryColor),
                SizedBox(height: 16.h),
                Text(
                  'Chargement des notifications',
                  style: GoogleFonts.raleway(
                    fontSize: 16.sp,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          _buildFilterChip('all', 'Tout'),
          SizedBox(width: 10.w),
          _buildFilterChip('appointment', 'Rendez-vous'),
          SizedBox(width: 10.w),
          _buildFilterChip('message', 'Messages'),
          SizedBox(width: 10.w),
          _buildFilterChip('prescription', 'Ordonnances'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: AppColors.primaryColor,
      backgroundColor:
          isDarkMode ? theme.cardColor.withOpacity(0.3) : Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  Widget _buildNotificationList(List<NotificationEntity> notifications) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filteredNotifications =
        _selectedFilter == 'all'
            ? notifications
            : notifications.where((n) {
              // Filter by notification type based on the selected filter
              switch (_selectedFilter) {
                case 'appointment':
                  return n.type == NotificationType.newAppointment ||
                      n.type == NotificationType.appointmentAccepted ||
                      n.type == NotificationType.appointmentRejected ||
                      n.type == NotificationType.appointmentCanceled ||
                      n.type == NotificationType.appointmentAssigned ||
                      n.type == NotificationType.appointmentReminder;
                case 'prescription':
                  return n.type == NotificationType.newPrescription ||
                      n.type == NotificationType.prescriptionUpdated ||
                      n.type == NotificationType.prescriptionCanceled ||
                      n.type == NotificationType.prescriptionRefilled;
                case 'message':
                  return n.type == NotificationType.newMessage;
                default:
                  return true;
              }
            }).toList();

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 48.sp,
              color:
                  isDarkMode
                      ? theme.iconTheme.color?.withOpacity(0.4)
                      : Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Aucune notification trouvée',
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUser?.id != null) {
          context.read<NotificationBloc>().add(
            GetNotificationsEvent(userId: _currentUser!.id!),
          );
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildDismissibleNotification(notification);
        },
      ),
    );
  }

  Widget _buildDismissibleNotification(NotificationEntity notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Supprimer la notification'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer cette notification ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Supprimer',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(
          DeleteNotificationEvent(notificationId: notification.id),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Notification supprimée')));
      },
      child: _buildNotificationCard(notification),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get time ago string
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color:
              notification.isRead
                  ? Colors.transparent
                  : AppColors.primaryColor.withOpacity(0.5),
          width: notification.isRead ? 0 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Mark as read
          context.read<NotificationBloc>().add(
            MarkNotificationAsReadEvent(notificationId: notification.id),
          );

          // Navigate to details
          _navigateToDetails(notification);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                notification.title,
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              flex: 1,
                              child: Text(
                                timeAgo,
                                style: GoogleFonts.raleway(
                                  fontSize: 12.sp,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notification.body,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notification.type == NotificationType.newAppointment &&
                  !notification.isRead)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptAppointment(notification),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          child: Text(
                            'Accepter',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rejectAppointment(notification),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          child: Text(
                            'Refuser',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.newAppointment:
        icon = Icons.calendar_today;
        color = Colors.green;
        break;
      case NotificationType.appointmentAccepted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.appointmentRejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.appointmentCanceled:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case NotificationType.appointmentAssigned:
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case NotificationType.appointmentReminder:
        icon = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.newRating:
        icon = Icons.star;
        color = Colors.amber;
        break;
      case NotificationType.newPrescription:
        icon = Icons.medical_services;
        color = AppColors.primaryColor;
        break;
      case NotificationType.prescriptionUpdated:
        icon = Icons.update;
        color = AppColors.primaryColor;
        break;
      case NotificationType.prescriptionCanceled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.prescriptionRefilled:
        icon = Icons.refresh;
        color = Colors.green;
        break;
      case NotificationType.newMessage:
        icon = Icons.message;
        color = Colors.purple;
        break;
      case NotificationType.dossierUpdate:
        icon = Icons.folder;
        color = Colors.teal;
        break;
      case NotificationType.medicationReminder:
        icon = Icons.medication;
        color = Colors.green;
        break;
      case NotificationType.emergencyAlert:
        icon = Icons.emergency;
        color = Colors.red;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, color: color, size: 24.sp),
    );
  }

  void _acceptAppointment(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(width: 20),
                  Text("Traitement en cours", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );

      // Get patient information from notification data
      String patientId = notification.senderId;
      String patientName = '';
      if (notification.data != null &&
          notification.data!['patientName'] != null) {
        patientName = notification.data!['patientName'];
      }

      // Add a BLoC listener to handle state changes
      final blocListener = BlocListener<RendezVousBloc, RendezVousState>(
        listener: (context, state) {
          if (state is RendezVousStatusUpdatedState ||
              state is RendezVousError ||
              state is RendezVousErrorState) {
            // Close the loading dialog
            Navigator.of(context, rootNavigator: true).pop();

            if (state is RendezVousErrorState || state is RendezVousError) {
              // Show error message
              String errorMessage =
                  state is RendezVousErrorState
                      ? state.message
                      : (state as RendezVousError).message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${"Erreur"}: $errorMessage'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RendezVousStatusUpdatedState) {
              // Mark notification as read
              context.read<NotificationBloc>().add(
                MarkNotificationAsReadEvent(notificationId: notification.id),
              );

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rendez-vous accepté'),
                  backgroundColor: Colors.green,
                ),
              );

              // Refresh notifications
              if (_currentUser?.id != null) {
                context.read<NotificationBloc>().add(
                  GetNotificationsEvent(userId: _currentUser!.id!),
                );
              }
            }
          }
        },
        child: Container(), // This won't be rendered
      );

      // Add the listener to the tree temporarily
      Navigator.of(
        context,
      ).overlay?.insert(OverlayEntry(builder: (context) => blocListener));

      // Update the appointment status
      context.read<RendezVousBloc>().add(
        UpdateRendezVousStatus(
          rendezVousId: notification.appointmentId!,
          status: 'accepted',
          patientId: patientId,
          doctorId: _currentUser!.id!,
          patientName: patientName,
          doctorName: '${_currentUser!.name} ${_currentUser!.lastName}',
          recipientRole: 'patient', // Added for notification
        ),
      );
    }
  }

  void _rejectAppointment(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(width: 20),
                  Text("Traitement en cours", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );

      // Get patient information from notification data
      String patientId = notification.senderId;
      String patientName = '';
      if (notification.data != null &&
          notification.data!['patientName'] != null) {
        patientName = notification.data!['patientName'];
      }

      // Add a BLoC listener to handle state changes
      final blocListener = BlocListener<RendezVousBloc, RendezVousState>(
        listener: (context, state) {
          if (state is RendezVousStatusUpdatedState ||
              state is RendezVousError ||
              state is RendezVousErrorState) {
            // Close the loading dialog
            Navigator.of(context, rootNavigator: true).pop();

            if (state is RendezVousErrorState || state is RendezVousError) {
              // Show error message
              String errorMessage =
                  state is RendezVousErrorState
                      ? state.message
                      : (state as RendezVousError).message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${"Erreur"}: $errorMessage'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RendezVousStatusUpdatedState) {
              // Mark notification as read
              context.read<NotificationBloc>().add(
                MarkNotificationAsReadEvent(notificationId: notification.id),
              );

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rendez-vous refusé'),
                  backgroundColor: Colors.red,
                ),
              );

              // Refresh notifications
              if (_currentUser?.id != null) {
                context.read<NotificationBloc>().add(
                  GetNotificationsEvent(userId: _currentUser!.id!),
                );
              }
            }
          }
        },
        child: Container(), // This won't be rendered
      );

      // Add the listener to the tree temporarily
      Navigator.of(
        context,
      ).overlay?.insert(OverlayEntry(builder: (context) => blocListener));

      // Update the appointment status
      context.read<RendezVousBloc>().add(
        UpdateRendezVousStatus(
          rendezVousId: notification.appointmentId!,
          status: 'cancelled',
          patientId: patientId,
          doctorId: _currentUser!.id!,
          patientName: patientName,
          doctorName: '${_currentUser!.name} ${_currentUser!.lastName}',
          recipientRole: 'patient', // Added for notification
        ),
      );
    }
  }

  void _navigateToDetails(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      // First fetch the appointment details
      context.read<RendezVousBloc>().add(
        FetchRendezVous(appointmentId: notification.appointmentId),
      );

      // Listen for the result and navigate when available
      final blocListener = BlocListener<RendezVousBloc, RendezVousState>(
        listener: (context, state) {
          if (state is RendezVousLoaded && state.rendezVous.isNotEmpty) {
            final appointment = state.rendezVous.first;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AppointmentDetailsPage(
                      appointment: appointment,
                      isDoctor: true,
                    ),
              ),
            );
          }
        },
        child: Container(), // This won't be rendered
      );

      // Add the listener temporarily
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Chargement'),
                  backgroundColor: AppColors.primaryColor,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryColor),
                      SizedBox(height: 16),
                      Text('Chargement des détails du rendez-vous'),
                      blocListener,
                    ],
                  ),
                ),
              ),
        ),
      );
    } else if (notification.prescriptionId != null) {
      // Navigate to prescription details
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => OrdonnancesPage()),
      // );
    }
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${"minutes_ago".tr}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${"hours_ago".tr}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${"days_ago".tr}';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7} ${"weeks_ago".tr}';
    } else if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30} ${"months_ago".tr}';
    } else {
      return '${difference.inDays ~/ 365} ${"years_ago".tr}';
    }
  }
}
