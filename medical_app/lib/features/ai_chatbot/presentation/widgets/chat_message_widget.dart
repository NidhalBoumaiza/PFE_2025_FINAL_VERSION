import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import 'package:intl/intl.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primaryColor,
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppColors.primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(18.r).copyWith(
                        bottomRight: message.isUser
                            ? Radius.circular(4.r)
                            : Radius.circular(18.r),
                        bottomLeft: !message.isUser
                            ? Radius.circular(4.r)
                            : Radius.circular(18.r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              File(message.imageUrl!),
                              width: 200.w,
                              height: 150.h,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 200.w,
                                height: 150.h,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                        if (message.pdfUrl != null) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? Colors.white.withOpacity(0.2)
                                  : AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: message.isUser
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    'PDF Document',
                                    style: GoogleFonts.raleway(
                                      fontSize: 14.sp,
                                      color: message.isUser
                                          ? Colors.white
                                          : AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                        Text(
                          message.content,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: message.isUser
                                ? Colors.white
                                : Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: AppColors.primaryColor,
                size: 16.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 