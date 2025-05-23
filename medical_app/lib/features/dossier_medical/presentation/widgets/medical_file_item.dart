import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/medical_file_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart' as open_file;

class MedicalFileItem extends StatefulWidget {
  final MedicalFileEntity file;
  final VoidCallback onDelete;
  final Function(String?) onUpdateDescription;

  const MedicalFileItem({
    Key? key,
    required this.file,
    required this.onDelete,
    required this.onUpdateDescription,
  }) : super(key: key);

  @override
  State<MedicalFileItem> createState() => _MedicalFileItemState();
}

class _MedicalFileItemState extends State<MedicalFileItem> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _checkIfFileExists();
  }

  Future<void> _checkIfFileExists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.file.filename}';
      final file = File(filePath);

      if (await file.exists()) {
        setState(() {
          _localFile = file;
        });
      }
    } catch (e) {
      print('Error checking if file exists: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFileTypeIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.file.fileType} · ${widget.file.fileSize}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'added_on'.tr +
                            ' ${_formatDate(widget.file.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildPopupMenu(context),
              ],
            ),
            if (widget.file.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'description'.tr + ':',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.file.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'downloading'.tr +
                          ' (${(_downloadProgress * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: _downloadProgress),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewFile(context),
                  icon: const Icon(Icons.visibility, size: 20),
                  label: Text('view'.tr),
                ),
                TextButton.icon(
                  onPressed:
                      _localFile != null ? null : () => _downloadFile(context),
                  icon: Icon(
                    _localFile != null ? Icons.check : Icons.download,
                    size: 20,
                  ),
                  label: Text(
                    _localFile != null ? 'downloaded'.tr : 'download'.tr,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      () => widget.onUpdateDescription(widget.file.description),
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text('edit'.tr),
                ),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  label: Text(
                    'delete'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData iconData;
    Color iconColor;

    if (widget.file.isImage) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (widget.file.isPdf) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.amber;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'view', child: Text('view'.tr)),
            PopupMenuItem(value: 'download', child: Text('download'.tr)),
            PopupMenuItem(value: 'edit', child: Text('edit_description'.tr)),
            PopupMenuItem(value: 'delete', child: Text('delete'.tr)),
          ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewFile(context);
            break;
          case 'download':
            _downloadFile(context);
            break;
          case 'edit':
            widget.onUpdateDescription(widget.file.description);
            break;
          case 'delete':
            widget.onDelete();
            break;
        }
      },
      icon: const Icon(Icons.more_vert),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('storage_permission_denied'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      // Get the directory for app documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.file.filename}';
      final file = File(filePath);

      // Create reference to the file in Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(widget.file.path);

      // Download file
      final downloadTask = storageRef.writeToFile(file);

      // Listen for state changes
      downloadTask.snapshotEvents.listen((taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            setState(() {
              _downloadProgress =
                  taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
            });
            break;
          case TaskState.success:
            setState(() {
              _isDownloading = false;
              _localFile = file;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('download_complete'.tr),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          case TaskState.error:
            setState(() {
              _isDownloading = false;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('download_failed'.tr),
                  backgroundColor: Colors.red,
                ),
              );
            }
            break;
          default:
            break;
        }
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewFile(BuildContext context) async {
    try {
      // If file is already downloaded, open it locally
      if (_localFile != null && await _localFile!.exists()) {
        final result = await open_file.OpenFile.open(_localFile!.path);
        if (result.type != open_file.ResultType.done) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('cannot_open_file'.tr + ': ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      // Otherwise open URL
      final url = Uri.parse(widget.file.path);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_file'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
