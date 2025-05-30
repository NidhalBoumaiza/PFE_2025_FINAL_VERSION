import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(File?)? onImageSelected;
  final double size;
  final bool isEditable;
  final String? placeholderText;

  const ProfilePictureWidget({
    Key? key,
    this.initialImageUrl,
    this.onImageSelected,
    this.size = 120,
    this.isEditable = true,
    this.placeholderText,
  }) : super(key: key);

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: widget.isEditable ? _showImageSourceDialog : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: _buildImageContent(isDarkMode)),
          ),
        ),
        if (widget.isEditable) ...[
          const SizedBox(height: 12),
          Text(
            widget.placeholderText ?? 'tap_to_add_photo'.tr,
            style: GoogleFonts.raleway(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent(bool isDarkMode) {
    // Show selected image first
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    }

    // Show network image if available
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.initialImageUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder:
            (context, url) => Container(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
        errorWidget: (context, url, error) => _buildPlaceholder(isDarkMode),
      );
    }

    // Show placeholder
    return _buildPlaceholder(isDarkMode);
  }

  Widget _buildPlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'select_photo_source'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSourceOption(
                        icon: Icons.camera_alt,
                        label: 'camera'.tr,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      _buildSourceOption(
                        icon: Icons.photo_library,
                        label: 'gallery'.tr,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      if (_selectedImage != null ||
                          widget.initialImageUrl != null)
                        _buildSourceOption(
                          icon: Icons.delete,
                          label: 'remove'.tr,
                          onTap: _removeImage,
                          isDestructive: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDestructive
                    ? Colors.red.withOpacity(0.3)
                    : AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDestructive ? Colors.red : AppColors.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validate file size (max 5MB)
        final fileSize = imageFile.lengthSync();
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorSnackBar('image_too_large'.tr);
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });

        // Notify parent widget
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(_selectedImage);
        }
      }
    } catch (e) {
      _showErrorSnackBar('error_selecting_image'.tr);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });

    // Notify parent widget
    if (widget.onImageSelected != null) {
      widget.onImageSelected!(null);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
