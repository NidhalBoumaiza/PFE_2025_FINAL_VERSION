import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/util/snackbar_message.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:path/path.dart' as path;
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/dossier_files_entity.dart';
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDossierMedical();
  }

  void _loadDossierMedical() {
    try {
      final bloc = context.read<DossierMedicalBloc>();
      bloc.add(FetchDossierMedicalEvent(patientId: widget.patientId));
    } catch (e) {
      print('Error getting DossierMedicalBloc: $e');
      SnackBarMessage().showErrorSnackBar(
        message: 'Erreur lors du chargement des dossiers' + ': $e',
        context: context,
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
        final description = await _showDescriptionDialog(fileName: file.name);
        if (description != null) {
          context.read<DossierMedicalBloc>().add(
            UploadSingleFileEvent(
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
          final description =
              await _showDescriptionDialog(fileName: file.name) ?? '';
          paths.add(file.path!);
          descriptions[path.basename(file.path!)] = description;
        }
      }

      if (paths.isNotEmpty) {
        context.read<DossierMedicalBloc>().add(
          UploadMultipleFilesEvent(
            patientId: widget.patientId,
            filePaths: paths,
            descriptions: descriptions,
          ),
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog({required String fileName}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Description du document $fileName'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Entrez une description (optionnel)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text('Confirmer'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor:
              isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Dossier médical',
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadDossierMedical,
                tooltip: 'Actualiser',
              ),
            ],
          ),
          body: BlocConsumer<DossierMedicalBloc, DossierMedicalState>(
            listener: (context, state) {
              if (state is FileUploadSuccess) {
                SnackBarMessage().showSuccessSnackBar(
                  message: 'Documents ajoutés avec succès',
                  context: context,
                );
              } else if (state is FileUploadError) {
                SnackBarMessage().showErrorSnackBar(
                  message: 'Erreur de téléchargement' + ': ${state.message}',
                  context: context,
                );
              } else if (state is FileDeleteSuccess) {
                SnackBarMessage().showSuccessSnackBar(
                  message: 'Document supprimé avec succès',
                  context: context,
                );
              } else if (state is FileDeleteError) {
                SnackBarMessage().showErrorSnackBar(
                  message: 'Erreur de suppression' + ': ${state.message}',
                  context: context,
                );
              } else if (state is FileDescriptionUpdateSuccess) {
                SnackBarMessage().showSuccessSnackBar(
                  message: 'Description mise à jour avec succès',
                  context: context,
                );
              } else if (state is FileDescriptionUpdateError) {
                SnackBarMessage().showErrorSnackBar(
                  message:
                      'Erreur de mise à jour de la description' +
                      ': ${state.message}',
                  context: context,
                );
              }
            },
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  _loadDossierMedical();
                },
                color: AppColors.primaryColor,
                child: _buildContent(state, constraints),
              );
            },
          ),
          floatingActionButton:
              constraints.maxWidth > 600
                  ? _buildFloatingActionRow()
                  : _buildFloatingActionColumn(),
        );
      },
    );
  }

  Widget _buildContent(DossierMedicalState state, BoxConstraints constraints) {
    if (state is DossierMedicalLoading ||
        state is FileUploadLoading ||
        state is FileDeleteLoading ||
        state is FileDescriptionUpdateLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingWidget(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _getLoadingMessage(state),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else if (state is DossierMedicalLoaded) {
      return _buildDossierContent(state.dossier, constraints);
    } else if (state is DossierMedicalEmpty) {
      return _buildEmptyDossier();
    } else if (state is DossierMedicalError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur' + ': ${state.message}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDossierMedical,
                    icon: const Icon(Icons.refresh),
                    label: Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: constraints.maxHeight * 0.8,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _loadDossierMedical,
              icon: const Icon(Icons.refresh),
              label: Text('Charger le dossier médical'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getLoadingMessage(DossierMedicalState state) {
    if (state is FileUploadLoading) {
      return state.isSingleFile
          ? 'Téléchargement d\'un fichier'
          : 'Téléchargement de plusieurs fichiers';
    } else if (state is FileDeleteLoading) {
      return 'Suppression du fichier';
    } else if (state is FileDescriptionUpdateLoading) {
      return 'Mise à jour de la description';
    }
    return 'Chargement du dossier médical';
  }

  Widget _buildDossierContent(
    DossierFilesEntity dossier,
    BoxConstraints constraints,
  ) {
    if (dossier.isEmpty) {
      return _buildEmptyDossier();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header with file count and actions
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents médicaux',
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dossier.files.length} document(s)',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSortOptions(),
                icon: Icon(Icons.sort, color: AppColors.primaryColor),
                tooltip: 'Trier les documents',
              ),
            ],
          ),
        ),

        // Documents list
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dossier.files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final file = dossier.files[index];
              return MedicalFileItem(
                file: file,
                onDelete: () => _confirmDeleteFile(file),
                onUpdateDescription:
                    (description) => _updateFileDescription(file, description),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trier les documents',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Trier par date'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement sort by date
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: Text('Trier par nom'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement sort by name
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: Text('Trier par type'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement sort by type
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyDossier() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : AppColors.primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 80,
                  color: AppColors.primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun document dans le dossier médical',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ajoutez votre premier document pour commencer',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Ajouter le premier document',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: _pickAndUploadFile,
          heroTag: 'addSingleFile',
          tooltip: 'Ajouter un document',
          icon: const Icon(Icons.add),
          label: Text('Fichier unique'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 16),
        FloatingActionButton.extended(
          onPressed: _pickAndUploadMultipleFiles,
          heroTag: 'addMultipleFiles',
          tooltip: 'Ajouter plusieurs documents',
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Plusieurs fichiers'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFloatingActionColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: _pickAndUploadFile,
          heroTag: 'addSingleFile',
          tooltip: 'Ajouter un document',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _pickAndUploadMultipleFiles,
          heroTag: 'addMultipleFiles',
          tooltip: 'Ajouter plusieurs documents',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add_photo_alternate),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteFile(MedicalFileEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer le document'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer le document "${file.displayName}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      context.read<DossierMedicalBloc>().add(
        DeleteFileEvent(patientId: widget.patientId, fileId: file.id),
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
            title: Text('Modifier la description'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Entrez une description',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text('Enregistrer'),
              ),
            ],
          ),
    );

    if (newDescription != null && newDescription != file.description) {
      context.read<DossierMedicalBloc>().add(
        UpdateFileDescriptionEvent(
          patientId: widget.patientId,
          fileId: file.id,
          description: newDescription,
        ),
      );
    }
  }
}
