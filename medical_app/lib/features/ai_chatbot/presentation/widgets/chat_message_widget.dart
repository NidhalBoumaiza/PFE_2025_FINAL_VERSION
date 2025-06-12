import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import 'package:intl/intl.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    print('=== CHAT MESSAGE WIDGET DEBUG ===');
    print('Message ID: ${message.id}');
    print('Is User: ${message.isUser}');
    print('Content: ${message.content}');
    print('Image URL: ${message.imageUrl}');
    print('PDF URL: ${message.pdfUrl}');

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
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 12.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    message.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          message.isUser
                              ? AppColors.primaryColor
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(18.r).copyWith(
                        bottomRight:
                            message.isUser
                                ? Radius.circular(4.r)
                                : Radius.circular(18.r),
                        bottomLeft:
                            !message.isUser
                                ? Radius.circular(4.r)
                                : Radius.circular(18.r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageUrl != null) ...[
                          _buildImageWidget(),
                          SizedBox(height: 8.h),
                        ],
                        if (message.pdfUrl != null) ...[
                          _buildPdfWidget(),
                          SizedBox(height: 8.h),
                        ],
                        if (message.content.isNotEmpty) ...[
                          Text(
                            message.content,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color:
                                  message.isUser
                                      ? Colors.white
                                      : Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
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

  Widget _buildImageWidget() {
    return Builder(
      builder: (context) {
        print('=== DISPLAYING IMAGE ===');
        print('Image path: ${message.imageUrl}');

        if (message.imageUrl == null || message.imageUrl!.isEmpty) {
          return _buildImageError('No image path provided');
        }

        final imageFile = File(message.imageUrl!);
        print('Image file exists: ${imageFile.existsSync()}');

        if (!imageFile.existsSync()) {
          print('Image file does not exist at path: ${message.imageUrl}');
          return _buildImageError('Image file not found');
        }

        try {
          if (imageFile.existsSync()) {
            print('Image file size: ${imageFile.lengthSync()} bytes');
          }

          return Container(
            constraints: BoxConstraints(maxWidth: 250.w, maxHeight: 200.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('=== IMAGE ERROR ===');
                  print('Error loading image: $error');
                  print('Stack trace: $stackTrace');
                  return _buildImageError('Failed to load image');
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    print('Image loaded synchronously');
                    return child;
                  }
                  print('Image loading frame: $frame');
                  return AnimatedOpacity(
                    child: child,
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          );
        } catch (e) {
          print('Exception while building image widget: $e');
          return _buildImageError('Error displaying image');
        }
      },
    );
  }

  Widget _buildImageError(String errorMessage) {
    return Container(
      width: 200.w,
      height: 120.h,
      decoration: BoxDecoration(
        color:
            message.isUser ? Colors.white.withOpacity(0.2) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              message.isUser
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey[400]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color:
                message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[600],
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            errorMessage,
            style: GoogleFonts.raleway(
              fontSize: 12.sp,
              color:
                  message.isUser
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfWidget() {
    return Builder(
      builder: (context) {
        print('=== DISPLAYING PDF ===');
        print('PDF path: ${message.pdfUrl}');

        String pdfName = 'Document PDF';
        if (message.pdfUrl != null && message.pdfUrl!.isNotEmpty) {
          // Extract filename from path
          final fileName = message.pdfUrl!.split('/').last;
          if (fileName.isNotEmpty) {
            pdfName = fileName;
          }
        }

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color:
                message.isUser
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  message.isUser
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: message.isUser ? Colors.white : AppColors.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdfName,
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color:
                            message.isUser
                                ? Colors.white
                                : AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Document PDF',
                      style: GoogleFonts.raleway(
                        fontSize: 12.sp,
                        color:
                            message.isUser
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
