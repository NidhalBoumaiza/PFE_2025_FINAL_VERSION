import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:medical_app/injection_container.dart' as di;

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      // Set up notifications stream first to ensure we're listening for updates
      if (user.id != null) {
        print('Setting up notifications stream for user: ${user.id}');
        context.read<NotificationBloc>().add(
          GetNotificationsStreamEvent(userId: user.id!),
        );

        // Load notifications for the current user
        print('Loading notifications for user: ${user.id}');
        context.read<NotificationBloc>().add(
          GetNotificationsEvent(userId: user.id!),
        );

        // Mark all as read when the page is opened
        context.read<NotificationBloc>().add(
          MarkAllNotificationsAsReadEvent(userId: user.id!),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_loading_user_data'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'notifications'.tr,
          style: GoogleFonts.raleway(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            tooltip: 'mark_all_read'.tr,
            onPressed: () {
              if (_currentUser.id != null) {
                context.read<NotificationBloc>().add(
                  MarkAllNotificationsAsReadEvent(userId: _currentUser.id!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('all_notifications_marked_as_read'.tr),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'refresh'.tr,
            onPressed: () {
              if (_currentUser.id != null) {
                context.read<NotificationBloc>().add(
                  GetNotificationsEvent(userId: _currentUser.id!),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is NotificationLoading && _isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16.h),
                    Text(
                      'loading_notifications'.tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoaded) {
              final notifications = state.notifications;
              print('Loaded ${notifications.length} notifications');

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 80.sp,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'no_notifications'.tr,
                        style: GoogleFonts.raleway(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'you_have_no_notifications_yet'.tr,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (_currentUser.id != null) {
                    context.read<NotificationBloc>().add(
                      GetNotificationsEvent(userId: _currentUser.id!),
                    );
                  }
                },
                color: AppColors.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    // Add staggered animation for each item
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 500),
                      opacity: 1.0,
                      curve: Curves.easeInOut,
                      child: AnimatedPadding(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.only(
                          top: index == 0 ? 8.h : 0,
                          bottom: 12.h,
                        ),
                        child: _buildNotificationCard(notifications[index]),
                      ),
                    );
                  },
                ),
              );
            }

            // If we're not loading and don't have notifications loaded yet,
            // show a message to encourage refreshing
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 80.sp,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'no_notifications_found'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'try_refreshing_the_page'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentUser.id != null) {
                        context.read<NotificationBloc>().add(
                          GetNotificationsEvent(userId: _currentUser.id!),
                        );
                      }
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('refresh'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
                title: Text('delete_notification'.tr),
                content: Text('confirm_delete_notification'.tr),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'delete'.tr,
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
            content: Text('notification_deleted'.tr),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: notification.isRead ? 1 : 3,
        shadowColor: AppColors.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side:
              notification.isRead
                  ? BorderSide.none
                  : BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
        ),
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
                            Text(
                              notification.title,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
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
                                      color:
                                          isDarkMode
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 12.sp,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          senderName,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.blue,
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
                                    color:
                                        isDarkMode
                                            ? Colors.grey.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
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
                                if (!notification.isRead)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      'new'.tr,
                                      style: GoogleFonts.raleway(
                                        fontSize: 12.sp,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
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

    IconData icon;
    Color color;
    String label = '';

    switch (type) {
      case NotificationType.newAppointment:
        icon = Icons.calendar_today_rounded;
        color = Colors.green;
        label = 'appointment'.tr;
        break;
      case NotificationType.appointmentAccepted:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        label = 'accepted'.tr;
        break;
      case NotificationType.appointmentRejected:
        icon = Icons.cancel_rounded;
        color = Colors.red;
        label = 'rejected'.tr;
        break;
      case NotificationType.newRating:
        icon = Icons.star_rounded;
        color = Colors.amber;
        label = 'rating'.tr;
        break;
      case NotificationType.newPrescription:
        icon = Icons.medical_services_rounded;
        color = AppColors.primaryColor;
        label = 'prescription'.tr;
        break;
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 26.sp),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? color.withOpacity(0.8) : color,
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
                  'accept'.tr,
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                onPressed: () {
                  if (notification.appointmentId != null) {
                    _acceptAppointment(notification.appointmentId!);
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
                  'reject'.tr,
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                onPressed: () {
                  if (notification.appointmentId != null) {
                    _rejectAppointment(notification.appointmentId!);
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
            'view_details'.tr,
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

  void _acceptAppointment(String appointmentId) {
    context.read<RendezVousBloc>().add(
      UpdateRendezVousStatus(
        rendezVousId: appointmentId,
        status: 'accepted',
        patientId: '', // This would need to be fetched
        doctorId: _currentUser.id!,
        patientName: '', // This would need to be fetched
        doctorName: _currentUser.name + ' ' + _currentUser.lastName,
      ),
    );

    // Send notification to patient
    final notification = context.read<NotificationBloc>();
    notification.add(
      SendNotificationEvent(
        title: 'appointment_accepted'.tr,
        body: 'appointment_accepted_message'.tr,
        senderId: _currentUser.id!,
        recipientId: '', // You need to get the patient ID from the appointment
        type: NotificationType.appointmentAccepted,
        appointmentId: appointmentId,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('appointment_accepted'.tr),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectAppointment(String appointmentId) {
    context.read<RendezVousBloc>().add(
      UpdateRendezVousStatus(
        rendezVousId: appointmentId,
        status: 'rejected',
        patientId: '', // This would need to be fetched
        doctorId: _currentUser.id!,
        patientName: '', // This would need to be fetched
        doctorName: _currentUser.name + ' ' + _currentUser.lastName,
      ),
    );

    // Send notification to patient
    final notification = context.read<NotificationBloc>();
    notification.add(
      SendNotificationEvent(
        title: 'appointment_rejected'.tr,
        body: 'appointment_rejected_message'.tr,
        senderId: _currentUser.id!,
        recipientId: '', // You need to get the patient ID from the appointment
        type: NotificationType.appointmentRejected,
        appointmentId: appointmentId,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('appointment_rejected'.tr),
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
}
