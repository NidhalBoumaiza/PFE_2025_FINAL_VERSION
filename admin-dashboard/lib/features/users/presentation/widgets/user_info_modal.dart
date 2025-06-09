import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserInfoModal extends StatelessWidget {
  final dynamic user;
  final String userType;

  const UserInfoModal({Key? key, required this.user, required this.userType})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        userType == 'patient'
                            ? Colors.blue[100]
                            : Colors.green[100],
                    child: Icon(
                      userType == 'patient'
                          ? Icons.person
                          : Icons.medical_services,
                      size: 30,
                      color:
                          userType == 'patient'
                              ? Colors.blue[600]
                              : Colors.green[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                userType == 'patient'
                                    ? Colors.blue[100]
                                    : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userType == 'patient' ? 'Patient' : 'Médecin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  userType == 'patient'
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Account status instead of online status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          user.accountStatus
                              ? Colors.green[100]
                              : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                user.accountStatus ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.accountStatus ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                user.accountStatus
                                    ? Colors.green[700]
                                    : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      _buildSection('Informations de base', [
                        _buildInfoRow('E-mail', user.email),
                        _buildInfoRow(
                          'Téléphone',
                          user.phoneNumber ?? 'Non fourni',
                        ),
                        _buildInfoRow('Sexe', user.gender ?? 'Non spécifié'),
                        if (user.dateOfBirth != null)
                          _buildInfoRow('Date de naissance', user.dateOfBirth!),
                        if (user.address != null)
                          _buildInfoRow('Adresse', user.address!),
                        _buildInfoRow(
                          'Inscrit le',
                          user.createdAt != null
                              ? DateFormat(
                                'dd/MM/yyyy à HH:mm',
                              ).format(user.createdAt!)
                              : 'Inconnu',
                        ),
                        if (user.lastLogin != null)
                          _buildInfoRow(
                            'Dernière connexion',
                            user.lastLoginAt != null
                                ? DateFormat(
                                  'dd/MM/yyyy à HH:mm',
                                ).format(user.lastLoginAt!)
                                : 'Jamais connecté',
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // Type-specific information
                      if (userType == 'patient') ...[
                        _buildSection('Informations médicales', [
                          _buildInfoRow(
                            'Groupe sanguin',
                            user.bloodType ?? 'Inconnu',
                          ),
                          if (user.height != null)
                            _buildInfoRow('Taille', '${user.height} cm'),
                          if (user.weight != null)
                            _buildInfoRow('Poids', '${user.weight} kg'),
                          if (user.allergies != null &&
                              user.allergies!.isNotEmpty)
                            _buildInfoRow(
                              'Allergies',
                              user.allergies!.join(', '),
                            ),
                          if (user.chronicDiseases != null &&
                              user.chronicDiseases!.isNotEmpty)
                            _buildInfoRow(
                              'Maladies chroniques',
                              user.chronicDiseases!.join(', '),
                            ),
                          if (user.antecedent != null &&
                              user.antecedent!.isNotEmpty)
                            _buildInfoRow(
                              'Antécédents médicaux',
                              user.antecedent!,
                            ),
                          if (user.emergencyContactName != null)
                            _buildInfoRow(
                              'Contact d\'urgence',
                              user.emergencyContactName!,
                            ),
                          if (user.emergencyContactPhone != null)
                            _buildInfoRow(
                              'Téléphone d\'urgence',
                              user.emergencyContactPhone!,
                            ),
                        ]),
                      ] else if (userType == 'doctor') ...[
                        _buildSection('Informations professionnelles', [
                          _buildInfoRow(
                            'Spécialité',
                            user.speciality ?? 'Médecine générale',
                          ),
                          if (user.numLicence != null)
                            _buildInfoRow(
                              'Numéro de licence',
                              user.numLicence!,
                            ),
                          if (user.experienceYears != null)
                            _buildInfoRow(
                              'Années d\'expérience',
                              user.experienceYears!,
                            ),
                          if (user.educationSummary != null)
                            _buildInfoRow('Formation', user.educationSummary!),
                          if (user.consultationFee != null)
                            _buildInfoRow(
                              'Tarif de consultation',
                              user.consultationFee != null
                                  ? '${user.consultationFee} €'
                                  : 'Non spécifié',
                            ),
                          _buildInfoRow(
                            'Durée de rendez-vous',
                            user.appointmentDuration != null
                                ? '${user.appointmentDuration} minutes'
                                : 'Non spécifiée',
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
