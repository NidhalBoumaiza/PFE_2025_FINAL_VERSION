import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation%20BLoC/conversations_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation%20BLoC/conversations_event.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation%20BLoC/conversations_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';

import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final bool showAppBar;

  const ConversationsScreen({super.key, this.showAppBar = true});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String _userId = '';
  bool _isDoctor = false;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh conversations when returning to this screen
    if (_userId.isNotEmpty) {
      _refreshConversations();

      // Only mark conversations as read when actually viewing the screen
      if (mounted && widget.showAppBar == false) {
        // This means we're in the tab view, not just navigating to this screen
        context.read<ConversationsBloc>().add(
          MarkAllConversationsReadEvent(userId: _userId),
        );
      }
    }
  }

  @override
  void didUpdateWidget(ConversationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when widget is updated (e.g., when coming back to this tab)
    if (_userId.isNotEmpty) {
      _refreshConversations();
    }
  }

  @override
  void activate() {
    super.activate();
    // This is called when the widget is reinserted into the widget tree
    if (_userId.isNotEmpty) {
      // Add a small delay to ensure database operations from other screens have completed
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _refreshConversations();
        }
      });
    }
  }

  Future<void> _refreshConversations() async {
    print('Refreshing conversations for user: $_userId, isDoctor: $_isDoctor');
    if (_userId.isNotEmpty) {
      // Request immediate refresh
      context.read<ConversationsBloc>().add(
        FetchConversationsEvent(userId: _userId, isDoctor: _isDoctor),
      );

      // Ensure stream subscription is active
      context.read<ConversationsBloc>().add(
        SubscribeToConversationsEvent(userId: _userId, isDoctor: _isDoctor),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final userJson = sharedPreferences.getString('CACHED_USER');
      if (userJson == null) {
        throw Exception('No cached user data found');
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final userId = userMap['id'] as String? ?? '';
      final isDoctor =
          userMap.containsKey('speciality') &&
          userMap.containsKey('numLicence');

      setState(() {
        _userId = userId;
        _isDoctor = isDoctor;
        _isLoading = false;
      });

      print(
        'ConversationsScreen loaded userId: $_userId, isDoctor: $_isDoctor',
      );
      if (_userId.isNotEmpty) {
        context.read<ConversationsBloc>().add(
          SubscribeToConversationsEvent(userId: _userId, isDoctor: _isDoctor),
        );
      } else {
        setState(() {
          _errorMessage = 'error_user_id_missing'.tr;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'error_no_user_data'.tr;
      });
    }
  }

  String _t(String key) {
    return key.tr;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar:
            widget.showAppBar
                ? AppBar(
                  title: Text(
                    'messages'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primaryColor,
                  elevation: 2,
                )
                : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72.sp,
                color: Colors.red.withOpacity(0.7),
              ),
              SizedBox(height: 16.h),
              Text(
                'error_prefix'.tr + _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: Text(
                  'retry'.tr,
                  style: GoogleFonts.raleway(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(
                  'messages'.tr,
                  style: GoogleFonts.raleway(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primaryColor,
                elevation: 2,
              )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ConversationsBloc, ConversationsState>(
                builder: (context, state) {
                  if (state is ConversationsLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  } else if (state is ConversationsLoaded) {
                    if (state.conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64.sp,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'no_conversations'.tr,
                              style: GoogleFonts.raleway(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.w),
                              child: Text(
                                "your_conversations".tr,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: state.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = state.conversations[index];
                        return _buildConversationCard(context, conversation);
                      },
                    );
                  } else if (state is ConversationsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.red.shade700,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: () {
                              if (_userId.isNotEmpty) {
                                context.read<ConversationsBloc>().add(
                                  FetchConversationsEvent(
                                    userId: _userId,
                                    isDoctor: _isDoctor,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                            child: Text(
                              'retry'.tr,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'loading_conversations'.tr,
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine if the other person is a doctor or patient based on user's role
    final bool isOtherDoctor = !_isDoctor;
    final String otherPersonName =
        isOtherDoctor
            ? conversation.doctorName
                .split(' ')
                .take(2)
                .join(' ') // Simplified doctor name
            : conversation.patientName;

    return InkWell(
      onTap: () => _navigateToChat(conversation),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        elevation: 1,
        color:
            conversation.lastMessageRead
                ? theme.cardColor
                : isDarkMode
                ? AppColors.primaryColor.withOpacity(0.15)
                : AppColors.primaryColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color:
                conversation.lastMessageRead
                    ? Colors.transparent
                    : AppColors.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor:
                    isOtherDoctor
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                child: Icon(
                  isOtherDoctor ? Icons.medical_services : Icons.person,
                  color: isOtherDoctor ? AppColors.primaryColor : Colors.orange,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherPersonName,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              fontWeight:
                                  FontWeight.w500, // Use consistent weight
                              color: theme.textTheme.titleMedium?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatLastMessageTime(conversation.lastMessageTime),
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      conversation.lastMessageType == 'image'
                          ? '📷 Image'
                          : conversation.lastMessageType == 'file'
                          ? '📎 File'
                          : conversation.lastMessage.isEmpty
                          ? 'no_message'.tr
                          : conversation.lastMessage,
                      style: GoogleFonts.raleway(
                        fontSize: 13.sp,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                        fontWeight: FontWeight.normal, // Use normal weight
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _formatLastMessageTime(DateTime? lastMessageTime) {
    if (lastMessageTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      lastMessageTime.year,
      lastMessageTime.month,
      lastMessageTime.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(lastMessageTime);
    } else if (messageDate == yesterday) {
      return 'yesterday'.tr;
    } else {
      return DateFormat('dd/MM').format(lastMessageTime);
    }
  }

  void _navigateToChat(ConversationEntity conversation) {
    print(
      'Navigating to ChatScreen with chatId: ${conversation.id}, userName: ${conversation.doctorName}, recipientId: ${conversation.doctorId}',
    );
    navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
      context,
      ChatScreen(
        chatId: conversation.id!,
        userName:
            _isDoctor ? conversation.patientName : conversation.doctorName,
        recipientId: _isDoctor ? conversation.patientId : conversation.doctorId,
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _refreshConversations();
    });
  }
}
