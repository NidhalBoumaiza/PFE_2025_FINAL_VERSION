import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/util/snackbar_message.dart';
import 'package:path/path.dart' as path;
import '../../../../core/widgets/loading_widget.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../domain/entities/dossier_medical_entity.dart';
import '../../domain/entities/medical_file_entity.dart';
import '../bloc/dossier_medical_bloc.dart';
import '../bloc/dossier_medical_event.dart';
import '../bloc/dossier_medical_state.dart';
import '../widgets/medical_file_item.dart';

class DossierMedicalScreen extends StatefulWidget {
  final String patientId;

  const DossierMedicalScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<DossierMedicalScreen> createState() => _DossierMedicalScreenState();
}

class _DossierMedicalScreenState extends State<DossierMedicalScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Don't call _loadDossierMedical() here anymore
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDossierMedical();
  }

  void _loadDossierMedical() {
    try {
      final bloc = BlocProvider.of<DossierMedicalBloc>(context);
      bloc.add(FetchDossierMedical(patientId: widget.patientId));
    } catch (e) {
      print('Error getting DossierMedicalBloc: $e');
      // Show a snackbar with the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medical records: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        final description = await _showDescriptionDialog();
        if (description != null) {
          BlocProvider.of<DossierMedicalBloc>(context).add(
            UploadSingleFile(
              patientId: widget.patientId,
              filePath: file.path!,
              description: description,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = <String>[];
      final descriptions = <String, String>{};

      for (final file in result.files) {
        if (file.path != null) {
          paths.add(file.path!);
          // Use the filename as the key for the description
          descriptions[path.basename(file.path!)] = '';
        }
      }

      if (paths.isNotEmpty) {
        BlocProvider.of<DossierMedicalBloc>(context).add(
          UploadMultipleFiles(
            patientId: widget.patientId,
            filePaths: paths,
            descriptions: descriptions,
          ),
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('document_description'.tr),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'enter_description_optional'.tr,
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('confirm'.tr),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('medical_records'.tr)),
      body: BlocConsumer<DossierMedicalBloc, DossierMedicalState>(
        listener: (context, state) {
          if (state is FileUploadSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: 'documents_added_successfully'.tr,
              context: context,
            );
          } else if (state is FileUploadError) {
            SnackBarMessage().showErrorSnackBar(
              message: 'error'.tr + ': ${state.message}',
              context: context,
            );
          } else if (state is FileDeleteSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: 'document_deleted_successfully'.tr,
              context: context,
            );
          } else if (state is FileDeleteError) {
            SnackBarMessage().showErrorSnackBar(
              message: 'error'.tr + ': ${state.message}',
              context: context,
            );
          } else if (state is FileDescriptionUpdateSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: 'description_updated_successfully'.tr,
              context: context,
            );
          } else if (state is FileDescriptionUpdateError) {
            SnackBarMessage().showErrorSnackBar(
              message: 'error'.tr + ': ${state.message}',
              context: context,
            );
          }
        },
        builder: (context, state) {
          if (state is DossierMedicalLoading || state is FileUploadLoading) {
            return const LoadingWidget();
          } else if (state is DossierMedicalLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: _buildDossierContent(state.dossier),
            );
          } else if (state is DossierMedicalEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: _buildEmptyDossier(),
            );
          } else if (state is DossierMedicalError) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Text(
                        'error'.tr + ': ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _loadDossierMedical();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadDossierMedical,
                      icon: const Icon(Icons.refresh),
                      label: Text('load_medical_records'.tr),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _pickAndUploadFile,
            heroTag: 'addSingleFile',
            tooltip: 'add_document'.tr,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _pickAndUploadMultipleFiles,
            heroTag: 'addMultipleFiles',
            tooltip: 'add_multiple_documents'.tr,
            child: const Icon(Icons.add_photo_alternate),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierContent(DossierMedicalEntity dossier) {
    if (dossier.files.isEmpty) {
      return _buildEmptyDossier();
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: dossier.files.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final file = dossier.files[index];
        return MedicalFileItem(
          file: file,
          onDelete: () => _confirmDeleteFile(file),
          onUpdateDescription:
              (description) => _updateFileDescription(file, description),
        );
      },
    );
  }

  Widget _buildEmptyDossier() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'no_documents_in_medical_records'.tr,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(Icons.add),
                  label: Text('add_document'.tr),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteFile(MedicalFileEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_document'.tr),
            content: Text(
              'confirm_delete_document'.trParams({'name': file.displayName}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete'.tr),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      context.read<DossierMedicalBloc>().add(
        DeleteFile(patientId: widget.patientId, fileId: file.id),
      );
    }
  }

  Future<void> _updateFileDescription(
    MedicalFileEntity file,
    String? initialDescription,
  ) async {
    final controller = TextEditingController(
      text: initialDescription ?? file.description,
    );

    final newDescription = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('edit_description'.tr),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'enter_description'.tr),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('save'.tr),
              ),
            ],
          ),
    );

    if (newDescription != null && newDescription != file.description) {
      context.read<DossierMedicalBloc>().add(
        UpdateFileDescription(
          patientId: widget.patientId,
          fileId: file.id,
          description: newDescription,
        ),
      );
    }
  }
}
