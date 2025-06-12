import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/appointment_details.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:firebase_auth/firebase_auth.dart';

// Define notification colors class at top level
class NotificationColors {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  NotificationColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late UserEntity _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load notifications first
        context.read<NotificationBloc>().add(
          GetNotificationsEvent(userId: user.uid),
        );

        // Then setup stream
        context.read<NotificationBloc>().add(
          GetNotificationsStreamEvent(userId: user.uid),
        );

        // Load unread count
        context.read<NotificationBloc>().add(
          GetUnreadNotificationsCountEvent(userId: user.uid),
        );
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAllAsRead() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<NotificationBloc>().add(
          MarkAllNotificationsAsReadEvent(userId: user.uid),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking notifications as read: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: const Color(0xFF2FA7BB),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              // Only show mark all as read if we have unread notifications
              if (state is UnreadNotificationsCountLoaded && state.count > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () => _markAllAsRead(),
                  tooltip: 'Marquer tout comme lu',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is AllNotificationsMarkedAsRead) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Toutes les notifications ont été marquées comme lues',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2FA7BB)),
              );
            }

            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement des notifications',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA7BB),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _initializeNotifications();
                },
                color: const Color(0xFF2FA7BB),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
              );
            }

            // Default loading state for initial load
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2FA7BB)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get notification type colors
    final notificationColors = _getNotificationColors(notification.type);

    // Extract sender name from data if available
    String senderName = '';
    if (notification.data != null) {
      senderName =
          notification.data!['senderName'] ??
          notification.data!['doctorName'] ??
          notification.data!['patientName'] ??
          '';
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
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
                      style: TextStyle(color: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification supprimée'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              notificationColors.backgroundColor.withOpacity(0.05),
              notificationColors.backgroundColor.withOpacity(0.02),
            ],
          ),
          border: Border.all(
            color:
                notification.isRead
                    ? notificationColors.primaryColor.withOpacity(0.3)
                    : notificationColors.primaryColor.withOpacity(0.6),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: notificationColors.primaryColor.withOpacity(0.1),
              blurRadius: notification.isRead ? 4 : 8,
              offset: Offset(0, 2),
              spreadRadius: notification.isRead ? 0 : 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Mark as read when tapped
              context.read<NotificationBloc>().add(
                MarkNotificationAsReadEvent(notificationId: notification.id),
              );

              // Navigate to details if applicable
              _navigateToDetails(notification);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getNotificationIcon(notification.type),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight:
                                            notification.isRead
                                                ? FontWeight.w600
                                                : FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: notificationColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                notification.body,
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.black54,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (senderName.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: notificationColors.primaryColor
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: notificationColors.primaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 12.sp,
                                            color:
                                                notificationColors.primaryColor,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            senderName,
                                            style: GoogleFonts.raleway(
                                              fontSize: 12.sp,
                                              color:
                                                  notificationColors
                                                      .primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12.sp,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          _getFormattedTime(
                                            notification.createdAt,
                                          ),
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: notificationColors.secondaryColor
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: notificationColors.secondaryColor
                                            .withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getNotificationTypeLabel(
                                        notification.type,
                                      ),
                                      style: GoogleFonts.raleway(
                                        fontSize: 11.sp,
                                        color:
                                            notificationColors.secondaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Show action buttons for appointment notifications
                  if (notification.type == NotificationType.newAppointment &&
                      _currentUser.role == 'medecin' &&
                      !notification.isRead)
                    _buildActionButtons(notification),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Widget _getNotificationIcon(NotificationType type) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final notificationColors = _getNotificationColors(type);

    IconData icon;
    String label = '';

    switch (type) {
      case NotificationType.newAppointment:
        icon = Icons.calendar_today_rounded;
        label = 'Rendez-vous';
        break;
      case NotificationType.appointmentAccepted:
        icon = Icons.check_circle_rounded;
        label = 'Accepté';
        break;
      case NotificationType.appointmentRejected:
        icon = Icons.cancel_rounded;
        label = 'Rejeté';
        break;
      case NotificationType.appointmentCanceled:
        icon = Icons.event_busy_rounded;
        label = 'Annulé';
        break;
      case NotificationType.appointmentAssigned:
        icon = Icons.assignment_rounded;
        label = 'Assigné';
        break;
      case NotificationType.appointmentReminder:
        icon = Icons.alarm_rounded;
        label = 'Rappel';
        break;
      case NotificationType.newRating:
        icon = Icons.star_rounded;
        label = 'Évaluation';
        break;
      case NotificationType.newPrescription:
        icon = Icons.medical_services_rounded;
        label = 'Ordonnance';
        break;
      case NotificationType.prescriptionUpdated:
        icon = Icons.update_rounded;
        label = 'Mis à jour';
        break;
      case NotificationType.prescriptionCanceled:
        icon = Icons.cancel_rounded;
        label = 'Annulé';
        break;
      case NotificationType.prescriptionRefilled:
        icon = Icons.refresh_rounded;
        label = 'Renouvelé';
        break;
      case NotificationType.newMessage:
        icon = Icons.message_rounded;
        label = 'Message';
        break;
      case NotificationType.dossierUpdate:
        icon = Icons.folder_rounded;
        label = 'Dossier';
        break;
      case NotificationType.medicationReminder:
        icon = Icons.medication_rounded;
        label = 'Médicament';
        break;
      case NotificationType.emergencyAlert:
        icon = Icons.emergency_rounded;
        label = 'Urgence';
        break;
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                notificationColors.primaryColor.withOpacity(0.15),
                notificationColors.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: notificationColors.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: notificationColors.primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: notificationColors.primaryColor,
            size: 28.sp,
          ),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: notificationColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(NotificationEntity notification) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Only show action buttons for appointment notifications to doctors
    if (notification.type == NotificationType.newAppointment &&
        _currentUser.role == 'medecin') {
      return Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18.sp,
                ),
                label: Text(
                  'Accepter',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                onPressed: () {
                  if (notification.appointmentId != null) {
                    _acceptAppointment(notification);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Colors.white,
                  size: 18.sp,
                ),
                label: Text(
                  'Rejeter',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                onPressed: () {
                  if (notification.appointmentId != null) {
                    _rejectAppointment(notification);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: ElevatedButton.icon(
          icon: Icon(Icons.visibility, color: Colors.white, size: 18.sp),
          label: Text(
            'Voir les détails',
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          onPressed: () {
            _navigateToDetails(notification);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            minimumSize: Size(double.infinity, 45.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 2,
          ),
        ),
      );
    }
  }

  void _acceptAppointment(NotificationEntity notification) {
    // Get patient information from notification data
    String patientId = notification.senderId;
    String patientName = '';
    if (notification.data != null &&
        notification.data!['patientName'] != null) {
      patientName = notification.data!['patientName'];
    }

    context.read<RendezVousBloc>().add(
      UpdateRendezVousStatus(
        rendezVousId: notification.appointmentId!,
        status: 'accepted',
        patientId: patientId,
        doctorId: _currentUser.id!,
        patientName: patientName,
        doctorName: _currentUser.name + ' ' + _currentUser.lastName,
        recipientRole: 'patient',
      ),
    );

    // Send notification to patient
    final notificationBloc = context.read<NotificationBloc>();
    notificationBloc.add(
      SendNotificationEvent(
        title: 'Rendez-vous accepté',
        body: 'Votre rendez-vous a été accepté par le médecin',
        senderId: _currentUser.id!,
        recipientId: patientId,
        type: NotificationType.appointmentAccepted,
        appointmentId: notification.appointmentId,
        recipientRole: 'patient',
        data: {
          'patientName': patientName,
          'doctorName': _currentUser.name + ' ' + _currentUser.lastName,
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rendez-vous accepté'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectAppointment(NotificationEntity notification) {
    // Get patient information from notification data
    String patientId = notification.senderId;
    String patientName = '';
    if (notification.data != null &&
        notification.data!['patientName'] != null) {
      patientName = notification.data!['patientName'];
    }

    context.read<RendezVousBloc>().add(
      UpdateRendezVousStatus(
        rendezVousId: notification.appointmentId!,
        status: 'rejected',
        patientId: patientId,
        doctorId: _currentUser.id!,
        patientName: patientName,
        doctorName: _currentUser.name + ' ' + _currentUser.lastName,
        recipientRole: 'patient',
      ),
    );

    // Send notification to patient
    final notificationBloc = context.read<NotificationBloc>();
    notificationBloc.add(
      SendNotificationEvent(
        title: 'Rendez-vous rejeté',
        body: 'Votre rendez-vous a été rejeté par le médecin',
        senderId: _currentUser.id!,
        recipientId: patientId,
        type: NotificationType.appointmentRejected,
        appointmentId: notification.appointmentId,
        recipientRole: 'patient',
        data: {
          'patientName': patientName,
          'doctorName': _currentUser.name + ' ' + _currentUser.lastName,
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rendez-vous rejeté'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToDetails(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      // Navigate to appointment details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AppointmentDetailsPage(id: notification.appointmentId!),
        ),
      );
    } else if (notification.prescriptionId != null) {
      // Navigate to prescription details
      // TODO: Implement prescription details navigation
    } else if (notification.ratingId != null) {
      // Navigate to rating details
      // TODO: Implement rating details navigation
    }
  }

  NotificationColors _getNotificationColors(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return NotificationColors(
          primaryColor: const Color(0xFF4CAF50), // Green
          secondaryColor: const Color(0xFF2E7D32),
          backgroundColor: const Color(0xFFE8F5E8),
        );
      case NotificationType.appointmentAccepted:
        return NotificationColors(
          primaryColor: const Color(0xFF4CAF50), // Green
          secondaryColor: const Color(0xFF1B5E20),
          backgroundColor: const Color(0xFFE8F5E8),
        );
      case NotificationType.appointmentRejected:
        return NotificationColors(
          primaryColor: const Color(0xFFF44336), // Red
          secondaryColor: const Color(0xFFC62828),
          backgroundColor: const Color(0xFFFFEBEE),
        );
      case NotificationType.appointmentCanceled:
        return NotificationColors(
          primaryColor: const Color(0xFFFF9800), // Orange
          secondaryColor: const Color(0xFFE65100),
          backgroundColor: const Color(0xFFFFF3E0),
        );
      case NotificationType.appointmentAssigned:
        return NotificationColors(
          primaryColor: const Color(0xFF2196F3), // Blue
          secondaryColor: const Color(0xFF0D47A1),
          backgroundColor: const Color(0xFFE3F2FD),
        );
      case NotificationType.appointmentReminder:
        return NotificationColors(
          primaryColor: const Color(0xFFFF9800), // Orange
          secondaryColor: const Color(0xFFEF6C00),
          backgroundColor: const Color(0xFFFFF3E0),
        );
      case NotificationType.newRating:
        return NotificationColors(
          primaryColor: const Color(0xFFFFC107), // Amber
          secondaryColor: const Color(0xFFFF8F00),
          backgroundColor: const Color(0xFFFFFDE7),
        );
      case NotificationType.newPrescription:
        return NotificationColors(
          primaryColor: const Color(0xFF2FA7BB), // Teal (App primary)
          secondaryColor: const Color(0xFF00695C),
          backgroundColor: const Color(0xFFE0F2F1),
        );
      case NotificationType.prescriptionUpdated:
        return NotificationColors(
          primaryColor: const Color(0xFF00BCD4), // Cyan
          secondaryColor: const Color(0xFF006064),
          backgroundColor: const Color(0xFFE0F7FA),
        );
      case NotificationType.prescriptionCanceled:
        return NotificationColors(
          primaryColor: const Color(0xFFF44336), // Red
          secondaryColor: const Color(0xFFB71C1C),
          backgroundColor: const Color(0xFFFFEBEE),
        );
      case NotificationType.prescriptionRefilled:
        return NotificationColors(
          primaryColor: const Color(0xFF4CAF50), // Green
          secondaryColor: const Color(0xFF2E7D32),
          backgroundColor: const Color(0xFFE8F5E8),
        );
      case NotificationType.newMessage:
        return NotificationColors(
          primaryColor: const Color(0xFF9C27B0), // Purple
          secondaryColor: const Color(0xFF4A148C),
          backgroundColor: const Color(0xFFF3E5F5),
        );
      case NotificationType.dossierUpdate:
        return NotificationColors(
          primaryColor: const Color(0xFF607D8B), // Blue Grey
          secondaryColor: const Color(0xFF263238),
          backgroundColor: const Color(0xFFECEFF1),
        );
      case NotificationType.medicationReminder:
        return NotificationColors(
          primaryColor: const Color(0xFF8BC34A), // Light Green
          secondaryColor: const Color(0xFF33691E),
          backgroundColor: const Color(0xFFF1F8E9),
        );
      case NotificationType.emergencyAlert:
        return NotificationColors(
          primaryColor: const Color(0xFFD32F2F), // Dark Red
          secondaryColor: const Color(0xFF8B0000),
          backgroundColor: const Color(0xFFFFEBEE),
        );
    }
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return 'Nouveau rendez-vous';
      case NotificationType.appointmentAccepted:
        return 'Accepté';
      case NotificationType.appointmentRejected:
        return 'Rejeté';
      case NotificationType.appointmentCanceled:
        return 'Annulé';
      case NotificationType.appointmentAssigned:
        return 'Assigné';
      case NotificationType.appointmentReminder:
        return 'Rappel';
      case NotificationType.newRating:
        return 'Évaluation';
      case NotificationType.newPrescription:
        return 'Ordonnance';
      case NotificationType.prescriptionUpdated:
        return 'Mis à jour';
      case NotificationType.prescriptionCanceled:
        return 'Annulé';
      case NotificationType.prescriptionRefilled:
        return 'Renouvelé';
      case NotificationType.newMessage:
        return 'Message';
      case NotificationType.dossierUpdate:
        return 'Mise à jour du dossier';
      case NotificationType.medicationReminder:
        return 'Médicament';
      case NotificationType.emergencyAlert:
        return 'Urgence';
    }
  }
}
