import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import '../../domain/entities/medical_file_entity.dart';
import '../../domain/entities/patient_entity.dart';
import '../bloc/medical_dossier_bloc.dart';
import '../bloc/medical_dossier_event.dart';
import '../bloc/medical_dossier_state.dart';

class MedicalDossierPage extends StatefulWidget {
  final PatientEntity patient;

  const MedicalDossierPage({Key? key, required this.patient}) : super(key: key);

  @override
  State<MedicalDossierPage> createState() => _MedicalDossierPageState();
}

class _MedicalDossierPageState extends State<MedicalDossierPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<MedicalDossierBloc>().add(
      GetMedicalDossierEvent(patientId: widget.patient.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? theme.colorScheme.background : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context, isDarkMode),
          Expanded(
            child: BlocBuilder<MedicalDossierBloc, MedicalDossierState>(
              builder: (context, state) {
                if (state is MedicalDossierLoading) {
                  return _buildLoadingState(isDarkMode);
                } else if (state is MedicalDossierError) {
                  return _buildErrorState(state.message, isDarkMode);
                } else if (state is MedicalDossierLoaded) {
                  return _buildLoadedState(state, isDarkMode);
                }
                return _buildInitialState(isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  isDarkMode ? theme.colorScheme.onSurface : Colors.grey[700],
              size: 24.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[400]!, Colors.indigo[600]!],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.folder_shared, size: 32.sp, color: Colors.white),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Dossier',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? theme.colorScheme.onSurface
                            : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Patient: ${widget.patient.fullName}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color:
                        isDarkMode
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildRefreshButton(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isDarkMode) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<MedicalDossierBloc>().add(
          GetMedicalDossierEvent(patientId: widget.patient.id!),
        );
      },
      icon: Icon(Icons.refresh, size: 18.sp, color: Colors.blue),
      label: Text(
        'Refresh',
        style: TextStyle(fontSize: 14.sp, color: Colors.blue),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3.w),
          SizedBox(height: 16.h),
          Text(
            'Loading medical dossier...',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48.sp,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Dossier',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MedicalDossierBloc>().add(
                GetMedicalDossierEvent(patientId: widget.patient.id!),
              );
            },
            icon: Icon(Icons.refresh),
            label: Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Ready to load medical dossier',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(MedicalDossierLoaded state, bool isDarkMode) {
    if (state.dossier.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    final filteredFiles = _filterFiles(state.dossier.files);

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildFilterAndStats(state, isDarkMode),
          SizedBox(height: 24.h),
          Expanded(child: _buildFilesGrid(filteredFiles, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.folder_open,
              size: 64.sp,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Aucun fichier médical',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ce patient n\'a pas encore téléchargé de fichiers médicaux.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndStats(MedicalDossierLoaded state, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildStatCard(
                  'Total fichiers',
                  '${state.dossier.fileCount}',
                  Icons.description,
                  Colors.blue,
                  isDarkMode,
                ),
                SizedBox(width: 16.w),
                _buildStatCard(
                  'Images',
                  '${state.dossier.imageFiles.length}',
                  Icons.image,
                  Colors.green,
                  isDarkMode,
                ),
                SizedBox(width: 16.w),
                _buildStatCard(
                  'PDF',
                  '${state.dossier.pdfFiles.length}',
                  Icons.picture_as_pdf,
                  Colors.red,
                  isDarkMode,
                ),
                SizedBox(width: 16.w),
                _buildStatCard(
                  'Autres',
                  '${state.dossier.otherFiles.length}',
                  Icons.insert_drive_file,
                  Colors.orange,
                  isDarkMode,
                ),
              ],
            ),
          ),
          SizedBox(width: 24.w),
          _buildFilterDropdown(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          isDarkMode
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? theme.colorScheme.background.withOpacity(0.5)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              isDarkMode
                  ? theme.colorScheme.outline.withOpacity(0.3)
                  : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
            });
          },
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous les fichiers')),
            DropdownMenuItem(value: 'images', child: Text('Images uniquement')),
            DropdownMenuItem(value: 'pdfs', child: Text('PDF uniquement')),
            DropdownMenuItem(value: 'others', child: Text('Autres fichiers')),
          ],
        ),
      ),
    );
  }

  List<MedicalFileEntity> _filterFiles(List<MedicalFileEntity> files) {
    switch (_selectedFilter) {
      case 'images':
        return files
            .where((file) => file.mimetype.startsWith('image/'))
            .toList();
      case 'pdfs':
        return files
            .where((file) => file.mimetype == 'application/pdf')
            .toList();
      case 'others':
        return files
            .where(
              (file) =>
                  !file.mimetype.startsWith('image/') &&
                  file.mimetype != 'application/pdf',
            )
            .toList();
      default:
        return files;
    }
  }

  Widget _buildFilesGrid(List<MedicalFileEntity> files, bool isDarkMode) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return _buildFileCard(files[index], isDarkMode);
      },
    );
  }

  Widget _buildFileCard(MedicalFileEntity file, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _getFileTypeGradient(file.fileTypeIcon),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getFileTypeIcon(file.fileTypeIcon),
                    size: 48.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      file.sizeFormatted,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.originalName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode
                              ? theme.colorScheme.onSurface
                              : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('MMM dd, yyyy').format(file.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          isDarkMode
                              ? theme.colorScheme.onSurface.withOpacity(0.6)
                              : Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  if (file.description.isNotEmpty)
                    Text(
                      file.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color:
                            isDarkMode
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _viewFile(file),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            side: BorderSide(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          child: Text(
                            'Voir',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getFileTypeGradient(String fileType) {
    switch (fileType) {
      case 'image':
        return LinearGradient(colors: [Colors.green[400]!, Colors.green[600]!]);
      case 'pdf':
        return LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]);
      default:
        return LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
        );
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _viewFile(MedicalFileEntity file) async {
    try {
      // For images, show in a dialog for better UX
      if (file.mimetype.startsWith('image/')) {
        _showImageDialog(file);
        return;
      }

      // For other files, try to open in browser
      final uri = Uri.parse(file.path);

      // For Flutter Web, use a different approach
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } else {
        // Fallback: open directly using html package
        html.window.open(file.path, '_blank');
      }
    } catch (e) {
      print('Error opening file: $e');
      // Fallback: try opening with html package
      try {
        html.window.open(file.path, '_blank');
      } catch (htmlError) {
        _showErrorSnackBar('Error opening file: $htmlError');
      }
    }
  }

  void _showImageDialog(MedicalFileEntity file) {
    print('🖼️ Opening image dialog for: ${file.originalName}');
    print('🔗 Image URL: ${file.path}');

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20.w),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.image,
                          color: Colors.green[600],
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.originalName,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${file.sizeFormatted} • ${DateFormat('MMM dd, yyyy').format(file.createdAt)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              print('🔗 Opening in new tab: ${file.path}');
                              html.window.open(file.path, '_blank');
                            },
                            icon: Icon(Icons.open_in_new, size: 16.sp),
                            label: Text(
                              'New Tab',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            onPressed: () {
                              print('❌ Closing image dialog');
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.close, size: 24.sp),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Image Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildImageWidget(file),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(MedicalFileEntity file) {
    print('🎨 Building image widget for: ${file.path}');

    // For Flutter Web, use a simpler approach that works better with CORS
    return _buildWebImageView(file);
  }

  Widget _buildWebImageView(MedicalFileEntity file) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show image info
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.image, size: 64.sp, color: Colors.blue[400]),
                  SizedBox(height: 16.h),
                  Text(
                    file.originalName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${file.sizeFormatted} • ${DateFormat('MMM dd, yyyy').format(file.createdAt)}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.blue[600]),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Due to browser security restrictions, images are best viewed in a new tab.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔗 Opening image in new tab: ${file.path}');
                      html.window.open(file.path, '_blank');
                    },
                    icon: Icon(Icons.open_in_new, size: 16.sp),
                    label: Text('Voir l\'image complète'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
            SizedBox(height: 20.h),
            // Try to display the image anyway (might work in some cases)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    file.path,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        print(
                          '✅ Image loaded successfully in dialog: ${file.originalName}',
                        );
                        return child;
                      }
                      return Container(
                        height: 200.h,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                strokeWidth: 3.w,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Loading preview...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print(
                        '❌ Image preview failed (expected): ${file.originalName}',
                      );
                      return Container(
                        height: 200.h,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Preview not available',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Please use "View Full Image" button above',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}
