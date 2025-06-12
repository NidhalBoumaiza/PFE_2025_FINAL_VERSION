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
import 'package:medical_app/features/rendez_vous/presentation/pages/appointment_details.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:medical_app/injection_container.dart' as di;

class NotificationsPatient extends StatefulWidget {
  const NotificationsPatient({super.key});

  @override
  State<NotificationsPatient> createState() => _NotificationsPatientState();
}

class _NotificationsPatientState extends State<NotificationsPatient>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'all';
  UserEntity? _currentUser;
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures notification refresh when page is navigated back to
    if (!_isLoading && _currentUser?.id != null) {
      _refreshNotifications(showLoading: false);
    }
  }

  Future<void> _loadUserDataAndInitialize() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      if (user.id != null && user.id!.isNotEmpty) {
        _initializeNotifications();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Utilisateur non trouvé')));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  void _initializeNotifications() {
    try {
      if (_currentUser?.id != null) {
        // Load notifications first
        context.read<NotificationBloc>().add(
          GetNotificationsEvent(userId: _currentUser!.id!),
        );

        // Then setup stream
        context.read<NotificationBloc>().add(
          GetNotificationsStreamEvent(userId: _currentUser!.id!),
        );

        // Load unread count
        context.read<NotificationBloc>().add(
          GetUnreadNotificationsCountEvent(userId: _currentUser!.id!),
        );
      } else {
        print('Error: User ID is null, cannot initialize notifications');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Utilisateur non trouvé'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAllAsRead() {
    try {
      if (_currentUser?.id != null) {
        context.read<NotificationBloc>().add(
          MarkAllNotificationsAsReadEvent(userId: _currentUser!.id!),
        );
      } else {
        print('Error: User ID is null, cannot mark notifications as read');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors du marquage des notifications comme lues',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du marquage des notifications comme lues',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications({bool showLoading = true}) async {
    if (_currentUser?.id == null) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });

      // Set a timeout to ensure we don't get stuck loading
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Délai d\'attente de chargement')),
          );
        }
      });
    }

    try {
      // Execute just one event at a time and let the bloc handle the rest
      // This prevents multiple loading states from being triggered
      context.read<NotificationBloc>().add(
        GetNotificationsEvent(userId: _currentUser!.id!),
      );

      // Automatically mark all notifications as read when the page is opened
      context.read<NotificationBloc>().add(
        MarkAllNotificationsAsReadEvent(userId: _currentUser!.id!),
      );
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'actualisation')),
        );
      }
    }

    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () {
              if (!_isLoading && _currentUser?.id != null) {
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
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) {
          // Listen for these specific state changes
          return current is NotificationsLoaded ||
              current is NotificationError ||
              current is NotificationInitial;
        },
        listener: (context, state) {
          print('NotificationBloc state: ${state.runtimeType}');

          if (state is NotificationsLoaded) {
            // Only update to not loading when notifications are actually loaded
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
            }

            // When notifications are loaded, also setup other notification features
            if (_currentUser?.id != null) {
              // Set up notifications stream
              context.read<NotificationBloc>().add(
                GetNotificationsStreamEvent(userId: _currentUser!.id!),
              );

              // Update unread count
              context.read<NotificationBloc>().add(
                GetUnreadNotificationsCountEvent(userId: _currentUser!.id!),
              );
            }
          } else if (state is NotificationError) {
            print('Notification Error: ${state.message}');
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        buildWhen: (previous, current) {
          // Only rebuild for states that actually affect the UI
          return current is NotificationsLoaded || current is NotificationError;
        },
        builder: (context, state) {
          print('Building UI with state: ${state.runtimeType}');

          // Show content based on loaded state
          if (state is NotificationsLoaded) {
            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshNotifications,
              color: AppColors.primaryColor,
              child:
                  state.notifications.isEmpty
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
                            child: _buildNotificationList(state.notifications),
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

          // Default loading indicator
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          _buildFilterChip('all', 'Tout'),
          SizedBox(width: 10.w),
          _buildFilterChip('appointment', 'Rendez-vous'),
          SizedBox(width: 10.w),
          _buildFilterChip('prescription', 'Ordonnances'),
          SizedBox(width: 10.w),
          _buildFilterChip('rating', 'Évaluations'),
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
          fontSize: 12,
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
          isDarkMode ? theme.cardColor.withOpacity(0.3) : Colors.grey[100],
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      n.type == NotificationType.appointmentRejected;
                case 'prescription':
                  return n.type == NotificationType.newPrescription;
                case 'rating':
                  return n.type == NotificationType.newRating;
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
              size: 48,
              color:
                  isDarkMode
                      ? theme.iconTheme.color?.withOpacity(0.4)
                      : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildDismissibleNotification(notification);
      },
    );
  }

  Widget _buildDismissibleNotification(NotificationEntity notification) {
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
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text(
                'Supprimer la notification',
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer cette notification ?',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
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
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(
              MarkNotificationAsReadEvent(notificationId: notification.id),
            );
          }

          _handleNotificationTap(notification);
        },
        child: Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 2,
          color:
              isDarkMode
                  ? (notification.isRead
                      ? theme.cardColor
                      : notificationColors.backgroundColor.withOpacity(0.1))
                  : (notification.isRead
                      ? theme.cardColor
                      : notificationColors.backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color:
                  notification.isRead
                      ? (isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300)
                      : notificationColors.primaryColor.withOpacity(0.5),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient:
                  notification.isRead
                      ? null
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          notificationColors.backgroundColor.withOpacity(
                            isDarkMode ? 0.1 : 0.3,
                          ),
                          notificationColors.backgroundColor.withOpacity(
                            isDarkMode ? 0.05 : 0.1,
                          ),
                        ],
                      ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getNotificationIcon(notification.type),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: notificationColors.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: notificationColors.primaryColor
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getNotificationTypeLabel(
                                        notification.type,
                                      ),
                                      style: GoogleFonts.raleway(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: notificationColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: notificationColors.primaryColor,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Nouveau',
                                        style: GoogleFonts.raleway(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: notificationColors.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          notification.title,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            fontWeight:
                                notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notification.body,
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (senderName.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14.sp,
                                color: notificationColors.primaryColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                senderName,
                                style: GoogleFonts.raleway(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: notificationColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatNotificationTime(notification.createdAt),
                              style: GoogleFonts.raleway(
                                fontSize: 10.sp,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18.sp,
                              color: notificationColors.primaryColor
                                  .withOpacity(0.7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        icon = Icons.assignment_ind_rounded;
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
      case NotificationType.prescriptionRefilled:
        icon = Icons.refresh_rounded;
        label = 'Renouvelé';
        break;
      case NotificationType.prescriptionCanceled:
        icon = Icons.block_rounded;
        label = 'Annulé';
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
      default:
        icon = Icons.notifications_rounded;
        label = 'Notification';
    }

    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? notificationColors.primaryColor.withOpacity(0.2)
                : notificationColors.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: notificationColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: notificationColors.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.r),
      child: Icon(icon, color: notificationColors.primaryColor, size: 20.sp),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AppointmentDetailsPage(id: notification.appointmentId!),
        ),
      ).then(
        (_) => _refreshNotifications(showLoading: false),
      ); // Refresh on return
    } else if (notification.prescriptionId != null) {
      // Navigate to prescription details
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => OrdonnancesPage()),
      // ).then(
      //   (_) => _refreshNotifications(showLoading: false),
      // ); // Refresh on return
    }
  }

  String _formatNotificationTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inSeconds}s';
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
          primaryColor: const Color(0xFF2196F3), // Blue
          secondaryColor: const Color(0xFF1565C0),
          backgroundColor: const Color(0xFFE3F2FD),
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
          primaryColor: const Color(0xFF9C27B0), // Purple
          secondaryColor: const Color(0xFF6A1B9A),
          backgroundColor: const Color(0xFFF3E5F5),
        );
      case NotificationType.appointmentReminder:
        return NotificationColors(
          primaryColor: const Color(0xFFFFEB3B), // Yellow
          secondaryColor: const Color(0xFFF57F17),
          backgroundColor: const Color(0xFFFFFDE7),
        );
      case NotificationType.newRating:
        return NotificationColors(
          primaryColor: const Color(0xFFFF5722), // Deep Orange
          secondaryColor: const Color(0xFFD84315),
          backgroundColor: const Color(0xFFFBE9E7),
        );
      case NotificationType.newPrescription:
        return NotificationColors(
          primaryColor: const Color(0xFF00BCD4), // Cyan
          secondaryColor: const Color(0xFF00838F),
          backgroundColor: const Color(0xFFE0F2F1),
        );
      case NotificationType.prescriptionUpdated:
        return NotificationColors(
          primaryColor: const Color(0xFF795548), // Brown
          secondaryColor: const Color(0xFF5D4037),
          backgroundColor: const Color(0xFFEFEBE9),
        );
      case NotificationType.prescriptionRefilled:
        return NotificationColors(
          primaryColor: const Color(0xFF607D8B), // Blue Grey
          secondaryColor: const Color(0xFF455A64),
          backgroundColor: const Color(0xFFECEFF1),
        );
      case NotificationType.prescriptionCanceled:
        return NotificationColors(
          primaryColor: const Color(0xFF795548), // Brown
          secondaryColor: const Color(0xFF5D4037),
          backgroundColor: const Color(0xFFEFEBE9),
        );
      case NotificationType.newMessage:
        return NotificationColors(
          primaryColor: const Color(0xFF3F51B5), // Indigo
          secondaryColor: const Color(0xFF283593),
          backgroundColor: const Color(0xFFE8EAF6),
        );
      case NotificationType.dossierUpdate:
        return NotificationColors(
          primaryColor: const Color(0xFF8BC34A), // Light Green
          secondaryColor: const Color(0xFF689F38),
          backgroundColor: const Color(0xFFF1F8E9),
        );
      case NotificationType.medicationReminder:
        return NotificationColors(
          primaryColor: const Color(0xFFE91E63), // Pink
          secondaryColor: const Color(0xFFC2185B),
          backgroundColor: const Color(0xFFFCE4EC),
        );
      case NotificationType.emergencyAlert:
        return NotificationColors(
          primaryColor: const Color(0xFFD32F2F), // Dark Red
          secondaryColor: const Color(0xFFB71C1C),
          backgroundColor: const Color(0xFFFFCDD2),
        );
      default:
        return NotificationColors(
          primaryColor: const Color(0xFF9E9E9E), // Grey
          secondaryColor: const Color(0xFF616161),
          backgroundColor: const Color(0xFFF5F5F5),
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
      case NotificationType.prescriptionRefilled:
        return 'Renouvelé';
      case NotificationType.prescriptionCanceled:
        return 'Annulé';
      case NotificationType.newMessage:
        return 'Message';
      case NotificationType.dossierUpdate:
        return 'Mise à jour du dossier';
      case NotificationType.medicationReminder:
        return 'Médicament';
      case NotificationType.emergencyAlert:
        return 'Urgence';
      default:
        return 'Notification';
    }
  }
}

// Add this class to define notification colors
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
