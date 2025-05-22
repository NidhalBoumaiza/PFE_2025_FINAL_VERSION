import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_medecin.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_patient.dart';
import 'package:medical_app/injection_container.dart' as di;

class NotificationBadge extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;

  const NotificationBadge({Key? key, this.iconColor, this.iconSize})
    : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with WidgetsBindingObserver {
  String? userId;
  String? userRole;
  bool _isInitialized = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh notifications count when app is resumed
    if (state == AppLifecycleState.resumed && userId != null) {
      _refreshNotifications();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when dependencies change (e.g., when returning to screen)
    if (userId != null) {
      _refreshNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();

      if (!mounted) return;

      setState(() {
        userId = user.id;
        userRole = user.role;
        _isInitialized = true;
      });

      if (userId != null) {
        _refreshNotifications();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    if (userId == null || !mounted || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Get notifications first to ensure we have data
    context.read<NotificationBloc>().add(
      GetNotificationsEvent(userId: userId!),
    );

    // Initialize FCM
    context.read<NotificationBloc>().add(SetupFCMEvent());

    // Load unread count
    context.read<NotificationBloc>().add(
      GetUnreadNotificationsCountEvent(userId: userId!),
    );

    // Setup stream
    context.read<NotificationBloc>().add(
      GetNotificationsStreamEvent(userId: userId!),
    );

    // Set refreshing to false after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }

  void _navigateToNotificationsPage() {
    if (!mounted || userId == null) return;

    // Mark all notifications as read when the user taps the notification badge
    context.read<NotificationBloc>().add(
      MarkAllNotificationsAsReadEvent(userId: userId!),
    );

    if (userRole == 'medecin') {
      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
        context,
        const NotificationsMedecin(),
      ).then((_) => _refreshNotifications());
    } else {
      // Default to patient notifications
      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
        context,
        const NotificationsPatient(),
      ).then((_) => _refreshNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_isInitialized || userId == null
        ? IconButton(
          icon: Icon(
            Icons.notifications_none,
            color: widget.iconColor,
            size: widget.iconSize ?? 24,
          ),
          onPressed: _navigateToNotificationsPage,
        )
        : BlocConsumer<NotificationBloc, NotificationState>(
          listenWhen: (previous, current) {
            return current is NotificationsLoaded ||
                current is NotificationError;
          },
          listener: (context, state) {
            if ((state is NotificationsLoaded || state is NotificationError) &&
                _isRefreshing) {
              setState(() {
                _isRefreshing = false;
              });
            }
          },
          buildWhen: (previous, current) {
            // Rebuild when count changes or notifications are loaded
            return current is UnreadNotificationsCountLoaded ||
                current is NotificationsLoaded;
          },
          builder: (context, state) {
            int count = 0;

            if (state is UnreadNotificationsCountLoaded) {
              count = state.count;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon:
                      _isRefreshing
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: widget.iconColor,
                              strokeWidth: 2,
                            ),
                          )
                          : Icon(
                            count > 0
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: widget.iconColor,
                            size: widget.iconSize ?? 24,
                          ),
                  onPressed: _navigateToNotificationsPage,
                ),
                if (count > 0 && !_isRefreshing)
                  Positioned(
                    right: 5,
                    top: 5,
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
                      constraints: BoxConstraints(
                        minWidth: 16.r,
                        minHeight: 16.r,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
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
}
