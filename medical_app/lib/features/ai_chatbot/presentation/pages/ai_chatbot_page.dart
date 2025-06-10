import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import '../bloc/ai_chatbot_bloc.dart';
import '../bloc/ai_chatbot_event.dart';
import '../bloc/ai_chatbot_state.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/attachment_bottom_sheet.dart';

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({super.key});

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isAttachmentMenuVisible = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<AiChatbotBloc>().add(SendTextMessageEvent(message: message));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => AttachmentBottomSheet(
        onImageSelected: _handleImageSelection,
        onPdfSelected: _handlePdfSelection,
      ),
    );
  }

  void _handleImageSelection() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      _showImagePromptDialog(File(image.path));
    }
  }

  void _showImagePromptDialog(File imageFile) {
    final TextEditingController promptController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text('Ajouter une instruction pour l\'image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Entrez une instruction pour l\'analyse de l\'image'),
            const SizedBox(height: 16),
            TextField(
              controller: promptController,
              decoration: InputDecoration(
                hintText: 'Décrivez ce que vous voulez analyser',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final prompt = promptController.text.trim();
              if (prompt.isNotEmpty) {
                context.read<AiChatbotBloc>().add(
                  SendImageMessageEvent(
                    imageFile: imageFile,
                    taskPrompt: prompt,
                  ),
                );
                Navigator.pop(context);
                _scrollToBottom();
              }
            },
            child: Text('Analyser'),
          ),
        ],
      ),
    );
  }

  void _handlePdfSelection() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      context.read<AiChatbotBloc>().add(SendPdfMessageEvent(pdfFile: file));
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Assistant IA',
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              context.read<AiChatbotBloc>().add(const ClearChatEvent());
            },
            tooltip: 'Effacer la conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AiChatbotBloc, AiChatbotState>(
              listener: (context, state) {
                if (state is AiChatbotError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                _scrollToBottom();
              },
              builder: (context, state) {
                if (state is AiChatbotInitial) {
                  return _buildWelcomeScreen();
                }

                if (state is AiChatbotLoaded || state is AiChatbotError) {
                  final messages =
                  state is AiChatbotLoaded
                      ? state.messages
                      : (state as AiChatbotError).messages;
                  final isLoading = state is AiChatbotLoaded && state.isLoading;

                  if (messages.isEmpty) {
                    return _buildWelcomeScreen();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading) {
                        return _buildLoadingMessage();
                      }
                      return ChatMessageWidget(message: messages[index]);
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildMessageInput(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Icon(
            Icons.smart_toy_outlined,
            size: 80.sp,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 24.h),
          Text(
            'Bienvenue dans l\'Assistant IA',
            style: GoogleFonts.raleway(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'Posez des questions, téléchargez des images ou des PDF pour une analyse intelligente',
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          _buildFeatureCard(
            icon: Icons.image,
            title: 'Analyse d\'image',
            description: 'Téléchargez une image pour une analyse détaillée par l\'IA',
          ),
          SizedBox(height: 16.h),
          _buildFeatureCard(
            icon: Icons.picture_as_pdf,
            title: 'Analyse de PDF',
            description: 'Envoyez un fichier PDF pour extraire et analyser son contenu',
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppColors.primaryColor,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  'L\'IA réfléchit...',
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: 16.h,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: Icon(
                Icons.attach_file,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 120.h, // Limit max height to prevent overflow
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Tapez votre message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            FloatingActionButton.small(
              onPressed: _sendTextMessage,
              backgroundColor: AppColors.primaryColor,
              child: Icon(Icons.send, color: Colors.white, size: 20.sp),
            ),
          ],
        ),
      ),
    );
  }
}