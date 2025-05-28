import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_event.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/messageries%20BLoC/messagerie_state.dart';
import 'package:get/get.dart';

// ChatScreen displays the messaging interface for a conversation
class ChatScreen extends StatefulWidget {
  final String chatId; // Unique ID of the conversation
  final String userName; // Name of the recipient
  final String recipientId; // ID of the recipient user

  const ChatScreen({
    required this.chatId,
    required this.userName,
    required this.recipientId,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController(); // Controller for message input
  final ScrollController _scrollController =
      ScrollController(); // Controller for scrolling message list
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  @override
  void initState() {
    super.initState();
    print(
      'ChatScreen initialized with chatId: ${widget.chatId}, userName: ${widget.userName}, recipientId: ${widget.recipientId}',
    );
    // Check if user is authenticated
    if (_auth.currentUser == null) {
      print('User not authenticated, redirecting to login');
      showErrorSnackBar(context, 'User not authenticated');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    // Fetch messages and subscribe to updates
    print(
      'Dispatching FetchMessagesEvent and SubscribeToMessagesEvent for chatId: ${widget.chatId}',
    );
    context.read<MessagerieBloc>().add(FetchMessagesEvent(widget.chatId));
    context.read<MessagerieBloc>().add(SubscribeToMessagesEvent(widget.chatId));
    _setupReadReceipts();

    // Add a slight delay before marking messages as read
    // This improves the user experience by giving time for the UI to render
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _markMessagesAsRead();
      }
    });
  }

  @override
  void dispose() {
    print('Disposing ChatScreen, cleaning up controllers');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Sets up a listener to mark incoming messages as read
  void _setupReadReceipts() {
    print('Setting up read receipts for chatId: ${widget.chatId}');
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user ID, cannot setup read receipts');
      return;
    }

    _firestore
        .collection('conversations')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              print('No messages to mark as read in snapshot');
              return;
            }

            print(
              'Received ${snapshot.docs.length} messages in read receipt listener',
            );
            final batch = _firestore.batch();
            bool updatesNeeded = false;

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final readBy = List<String>.from(data['readBy'] ?? []);

              if (!readBy.contains(currentUserId)) {
                // Add current user to readBy array and update status
                batch.update(doc.reference, {
                  'readBy': FieldValue.arrayUnion([currentUserId]),
                  'status': 'read',
                });
                updatesNeeded = true;
                print('Marking message ${doc.id} as read in listener');

                // Update UI through BLoC
                final readMessage = MessageModel(
                  id: doc.id,
                  conversationId: widget.chatId,
                  senderId: data['senderId'] as String,
                  content: data['content'] as String,
                  type: data['type'] as String,
                  url: data['url'] as String?,
                  fileName: data['fileName'] as String?,
                  timestamp: DateTime.parse(data['timestamp'] as String),
                  status: MessageStatus.read,
                  readBy: [...readBy, currentUserId],
                );

                context.read<MessagerieBloc>().add(
                  UpdateMessageStatusEvent(readMessage),
                );
              }
            }

            if (updatesNeeded) {
              batch
                  .commit()
                  .then((_) {
                    print('Successfully updated read receipts in batch');
                    // Update conversation's last message read status
                    _firestore
                        .collection('conversations')
                        .doc(widget.chatId)
                        .update({'lastMessageRead': true})
                        .then((_) {
                          print(
                            'Updated conversation lastMessageRead status to true',
                          );
                        })
                        .catchError((error) {
                          print(
                            'Error updating conversation read status: $error',
                          );
                        });
                  })
                  .catchError((error) {
                    print('Error committing read receipt batch: $error');
                  });
            }
          },
          onError: (error) {
            print('Read receipts error: $error');
            showErrorSnackBar(
              context,
              'Failed to update read receipts: $error',
            );
          },
        );
  }

  // Marks all unread messages from the recipient as read
  Future<void> _markMessagesAsRead() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user ID, cannot mark messages as read');
      return;
    }

    try {
      print('Marking messages as read for recipientId: ${widget.recipientId}');
      final messages =
          await _firestore
              .collection('conversations')
              .doc(widget.chatId)
              .collection('messages')
              .where('senderId', isEqualTo: widget.recipientId)
              .get();

      if (messages.docs.isEmpty) {
        print('No messages from recipient found to mark as read');
        return;
      }

      print('Found ${messages.docs.length} messages to check for read status');

      final batch = _firestore.batch();
      bool updatesNeeded = false;

      for (final doc in messages.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(currentUserId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([currentUserId]),
            'status': 'read',
          });
          updatesNeeded = true;
          print('Marking message ${doc.id} as read');
        }
      }

      if (updatesNeeded) {
        await batch.commit();
        print('Successfully marked messages as read');

        // Also update the conversation's last message read status
        await _firestore.collection('conversations').doc(widget.chatId).update({
          'lastMessageRead': true,
        });
        print('Updated conversation lastMessageRead status to true');
      } else {
        print('All messages were already marked as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      showErrorSnackBar(context, 'Failed to mark messages as read: $e');
    }
  }

  // Sends a text message
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
        conversationId: widget.chatId,
        senderId: _auth.currentUser!.uid,
        content: _messageController.text,
        type: 'text',
        timestamp: DateTime.now(),
        status: MessageStatus.sending, // Initial status
        readBy: [],
      );

      print('Sending text message ${message.id}: ${message.content}');
      context.read<MessagerieBloc>().add(SendMessageEvent(message: message));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  // Scrolls to the latest message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Displays an image in a dialog
  void _viewMedia(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: 50.sp,
              height: 50.sp,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
    );
  }

  // Placeholder for file download
  void _downloadFile(String url, String fileName) {
    showErrorSnackBar(context, 'File download not implemented yet');
  }

  // Builds the status icon (loader, checkmark, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 2,
      ),
      body: BlocConsumer<MessagerieBloc, MessagerieState>(
        listener: (context, state) {
          if (state is MessagerieError) {
            print('MessagerieError: ${state.message}');
            showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          List<MessageModel> messages = [];
          bool isLoading = false;

          // Handle different states
          if (state is MessagerieLoading) {
            isLoading = true;
            messages = state.messages;
            print('MessagerieLoading with ${messages.length} messages');
          } else if (state is MessagerieStreamActive ||
              state is MessagerieSuccess ||
              state is MessagerieMessageSent) {
            messages = state.messages;
            print(
              'Rendering ${messages.length} messages, state: ${state.runtimeType}, stateId: ${state.stateId}',
            );
          } else if (state is MessagerieError) {
            messages = state.messages;
            print('MessagerieError with ${messages.length} messages');
          }

          return Column(
            children: [
              Expanded(
                child:
                    isLoading && messages.isEmpty
                        ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                        : messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48.sp,
                                color: AppColors.grey.withOpacity(0.5),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'no_messages_yet'.tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  color: AppColors.grey,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'start_conversation'.tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: AppColors.grey.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 8.w,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe =
                                message.senderId == _auth.currentUser!.uid;

                            // Add date header if needed
                            final showDateHeader =
                                index == messages.length - 1 ||
                                !_isSameDay(
                                  messages[index].timestamp,
                                  messages[index + 1].timestamp,
                                );

                            return Column(
                              children: [
                                if (showDateHeader)
                                  _buildDateHeader(message.timestamp),
                                Align(
                                  key: ValueKey(message.id),
                                  alignment:
                                      isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.75,
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: 8.h,
                                        bottom: 8.h,
                                        left: isMe ? 64.w : 8.w,
                                        right: isMe ? 8.w : 64.w,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? AppColors.primaryColor
                                                : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16.r),
                                          topRight: Radius.circular(16.r),
                                          bottomLeft: Radius.circular(
                                            isMe ? 16.r : 0,
                                          ),
                                          bottomRight: Radius.circular(
                                            isMe ? 0 : 16.r,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.content.isEmpty
                                                ? (message.type == 'image'
                                                    ? '[Image]'
                                                    : message.type == 'file'
                                                    ? '[File: ${message.fileName ?? 'Unknown'}]'
                                                    : 'Empty message')
                                                : message.content,
                                            style: GoogleFonts.raleway(
                                              fontSize: 15.sp,
                                              color:
                                                  isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'HH:mm',
                                                ).format(message.timestamp),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 12.sp,
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                              .withOpacity(0.7)
                                                          : Colors.grey,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                SizedBox(width: 4.w),
                                                _buildMessageStatusIcon(
                                                  message.status,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
              if (state is MessagerieError)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                        'Retrying fetch and subscribe for chatId: ${widget.chatId}',
                      );
                      context.read<MessagerieBloc>().add(
                        FetchMessagesEvent(widget.chatId),
                      );
                      context.read<MessagerieBloc>().add(
                        SubscribeToMessagesEvent(widget.chatId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    icon: Icon(Icons.refresh, color: Colors.white, size: 18.sp),
                    label: Text(
                      'retry'.tr,
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, -1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'type_a_message'.tr,
                            hintStyle: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                          ),
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build message status icon
  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12.sp,
          height: 12.sp,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.7),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14.sp,
          color: Colors.white.withOpacity(0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14.sp,
          color: Colors.white.withOpacity(0.7),
        );
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14.sp, color: Colors.blue.shade300);
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14.sp,
          color: Colors.red.shade300,
        );
    }
  }

  // Helper to build date headers
  Widget _buildDateHeader(DateTime messageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      messageTime.year,
      messageTime.month,
      messageTime.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = "today".tr;
    } else if (messageDate == yesterday) {
      dateText = "yesterday".tr;
    } else {
      dateText = DateFormat('EEEE, d MMMM').format(messageTime);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            dateText,
            style: GoogleFonts.raleway(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
