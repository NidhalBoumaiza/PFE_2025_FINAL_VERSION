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
import 'package:firebase_auth/firebase_auth.dart';

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
    _loadUnreadCount();
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
      print('NotificationBadge: Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _loadUnreadCount() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<NotificationBloc>().add(
          GetUnreadNotificationsCountEvent(userId: user.uid),
        );
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
      // Don't show error to user for badge, just fail silently
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
    print('NotificationBadge: _navigateToNotificationsPage called');

    // Show a snackbar to confirm the button is being pressed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Badge de notification pressé !'),
        duration: Duration(seconds: 1),
      ),
    );

    if (!mounted) {
      print('NotificationBadge: Widget not mounted');
      return;
    }

    // Try simple navigation first to test if navigation works at all
    try {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => const NotificationsPatient(),
            ),
          )
          .then((_) {
            print('NotificationBadge: Returned from NotificationsPatient');
            if (userId != null) {
              _refreshNotifications();
            }
          });
    } catch (e) {
      print('NotificationBadge: Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'NotificationBadge build: _isInitialized=$_isInitialized, userId=$userId',
    );

    return !_isInitialized || userId == null
        ? IconButton(
          icon: Icon(
            Icons.notifications_none,
            color: widget.iconColor,
            size: widget.iconSize ?? 24,
          ),
          onPressed: () {
            print('NotificationBadge: Simple IconButton pressed');
            _navigateToNotificationsPage();
          },
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
            int unreadCount = 0;

            // Handle different states
            if (state is UnreadNotificationsCountLoaded) {
              unreadCount = state.count;
            } else if (state is NotificationsLoaded) {
              // Fallback: count unread notifications from loaded notifications
              unreadCount = state.notifications.where((n) => !n.isRead).length;
            }

            print('NotificationBadge BlocConsumer: unreadCount=$unreadCount');

            // Don't show badge if no unread notifications
            if (unreadCount <= 0) {
              return IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: widget.iconColor,
                  size: widget.iconSize ?? 24,
                ),
                onPressed: () {
                  print(
                    'NotificationBadge: BlocConsumer IconButton (no unread) pressed',
                  );
                  _navigateToNotificationsPage();
                },
              );
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
                            Icons.notifications_active,
                            color: widget.iconColor,
                            size: widget.iconSize ?? 24,
                          ),
                  onPressed: () {
                    print(
                      'NotificationBadge: BlocConsumer IconButton (with badge) pressed',
                    );
                    _navigateToNotificationsPage();
                  },
                ),
                if (unreadCount > 0 && !_isRefreshing)
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
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
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
