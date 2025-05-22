import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../rendez_vous/presentation/pages/patient_profile_page.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? currentUser;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? nextPatientId;

  List<Map<String, dynamic>> patients = [];
  String? searchQuery;
  final TextEditingController _searchController = TextEditingController();
  final int patientsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
        });

        if (currentUser?.id != null) {
          _loadPatients();
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar("Error loading user data: $e");
    }
  }

  Future<void> _loadPatients({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        patients = [];
        nextPatientId = null;
        hasMore = true;
      });
    }

    if (currentUser?.id == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        if (!refresh) isLoadingMore = true;
      });

      // Query without complex ordering to avoid index errors
      final result =
          await _firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: currentUser!.id)
              .get();

      print(
        'Found ${result.docs.length} appointments for doctor ${currentUser!.id}',
      );

      // Extract unique patients
      Set<String> uniquePatientIds = {};
      List<Map<String, dynamic>> newPatients = [];

      for (var doc in result.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String?;

        if (patientId != null && !uniquePatientIds.contains(patientId)) {
          uniquePatientIds.add(patientId);

          try {
            // Get patient details from patients collection
            final patientDoc =
                await _firestore.collection('patients').doc(patientId).get();

            if (patientDoc.exists) {
              final patientData = patientDoc.data() as Map<String, dynamic>;
              patientData['id'] = patientId;

              // Add last appointment info
              final appointmentData = data;
              final timestamp = appointmentData['startTime'];

              DateTime appointmentDate;
              if (timestamp is Timestamp) {
                appointmentDate = timestamp.toDate();
              } else if (timestamp is String) {
                appointmentDate = DateTime.parse(timestamp);
              } else {
                appointmentDate = DateTime.now();
              }

              patientData['lastAppointment'] =
                  appointmentDate.toIso8601String();
              patientData['lastAppointmentStatus'] = appointmentData['status'];

              newPatients.add(patientData);
            } else {
              // Patient document doesn't exist, create a minimal record
              final patientName =
                  data['patientName'] as String? ?? 'unknown_patient'.tr;
              newPatients.add({
                'id': patientId,
                'name': patientName.split(' ').first,
                'lastName':
                    patientName.split(' ').length > 1
                        ? patientName.split(' ').last
                        : '',
                'email': 'patient@example.com',
                'phoneNumber': '',
                'lastAppointment':
                    (data['startTime'] is Timestamp)
                        ? (data['startTime'] as Timestamp)
                            .toDate()
                            .toIso8601String()
                        : DateTime.now().toIso8601String(),
                'lastAppointmentStatus': data['status'] ?? 'unknown',
              });
            }
          } catch (e) {
            print('Error fetching patient $patientId: $e');
          }
        }
      }

      // Sort by most recent appointment
      newPatients.sort((a, b) {
        final aDate = a['lastAppointment'] as String?;
        final bDate = b['lastAppointment'] as String?;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
      });

      // Apply search filter if query exists
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        final query = searchQuery!.toLowerCase();
        newPatients =
            newPatients.where((patient) {
              final name = ((patient['name'] ?? '') as String).toLowerCase();
              final lastName =
                  ((patient['lastName'] ?? '') as String).toLowerCase();
              final fullName = '$name $lastName';
              return fullName.contains(query);
            }).toList();
      }

      // Apply pagination in memory
      final paginatedPatients = newPatients.take(patientsPerPage).toList();

      setState(() {
        if (refresh) {
          patients = paginatedPatients;
        } else {
          patients.addAll(paginatedPatients);
        }

        isLoading = false;
        isLoadingMore = false;
        hasMore = newPatients.length > patientsPerPage;

        // Store all patients for in-memory pagination
        if (hasMore) {
          _allPatients = newPatients;
          _currentPage = 1;
        } else {
          _allPatients = [];
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      _showErrorSnackBar("Error loading patients: $e");
      print("Error loading patients: $e");
    }
  }

  // All patients for in-memory pagination
  List<Map<String, dynamic>> _allPatients = [];
  int _currentPage = 0;

  Future<void> _loadMorePatients() async {
    if (!hasMore || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      // In-memory pagination
      if (_allPatients.isNotEmpty) {
        _currentPage++;
        final startIndex = _currentPage * patientsPerPage;
        final endIndex = startIndex + patientsPerPage;

        if (startIndex < _allPatients.length) {
          final nextPagePatients = _allPatients.sublist(
            startIndex,
            endIndex > _allPatients.length ? _allPatients.length : endIndex,
          );

          setState(() {
            patients.addAll(nextPagePatients);
            hasMore = endIndex < _allPatients.length;
            isLoadingMore = false;
          });
          return;
        }
      }

      // If we don't have all patients in memory or we've reached the end,
      // mark as no more data
      setState(() {
        hasMore = false;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      _showErrorSnackBar("Error loading more patients: $e");
      print("Error loading more patients: $e");
    }
  }

  void _searchPatients(String query) {
    setState(() {
      searchQuery = query;
    });
    _loadPatients(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = null;
    });
    _loadPatients(refresh: true);
  }

  void _navigateToPatientProfile(Map<String, dynamic> patientData) {
    if (patientData['id'] == null) return;

    final patientEntity = PatientEntity(
      id: patientData['id'] as String,
      name: patientData['name'] as String? ?? '',
      lastName: patientData['lastName'] as String? ?? '',
      email: patientData['email'] as String? ?? '',
      role: 'patient',
      gender: patientData['gender'] as String? ?? 'unknown',
      phoneNumber: patientData['phoneNumber'] as String? ?? '',
      dateOfBirth:
          patientData['dateOfBirth'] != null
              ? (patientData['dateOfBirth'] is Timestamp)
                  ? (patientData['dateOfBirth'] as Timestamp).toDate()
                  : DateTime.parse(patientData['dateOfBirth'] as String)
              : null,
      antecedent: patientData['antecedent'] as String? ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfilePage(patient: patientEntity),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.raleway()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "my_patients".tr,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_patient'.tr,
                hintStyle: GoogleFonts.raleway(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                suffixIcon:
                    searchQuery != null && searchQuery!.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.raleway(fontSize: 14.sp),
              onChanged: _searchPatients,
            ),
          ),

          // Patients list
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "loading_patients".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                    : patients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people,
                              size: 64.sp,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            searchQuery != null && searchQuery!.isNotEmpty
                                ? "no_patients_found_for_search".tr
                                : "no_patients_yet".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            searchQuery != null && searchQuery!.isNotEmpty
                                ? "try_different_search".tr
                                : "patients_will_appear_here".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (searchQuery != null && searchQuery!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: ElevatedButton.icon(
                                onPressed: _clearSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(Icons.clear, size: 20.sp),
                                label: Text(
                                  "clear_search".tr,
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _loadPatients(refresh: true),
                      color: AppColors.primaryColor,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              hasMore &&
                              !isLoadingMore) {
                            _loadMorePatients();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: patients.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == patients.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 3.w,
                                  ),
                                ),
                              );
                            }

                            final patient = patients[index];
                            final String fullName =
                                '${patient['name'] ?? ''} ${patient['lastName'] ?? ''}'
                                    .trim();
                            final String lastAppointmentDate =
                                patient['lastAppointment'] != null
                                    ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.parse(
                                        patient['lastAppointment'],
                                      ),
                                    )
                                    : 'N/A';

                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToPatientProfile(patient),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 50.h,
                                        width: 50.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            fullName.isNotEmpty
                                                ? fullName
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : 'P',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName.isEmpty
                                                  ? 'unknown_patient'.tr
                                                  : fullName,
                                              style: GoogleFonts.raleway(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              "last_consultation".tr +
                                                  ": $lastAppointmentDate",
                                              style: GoogleFonts.raleway(
                                                fontSize: 14.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (patient['lastAppointmentStatus'] !=
                                                null)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6.h,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      patient['lastAppointmentStatus'],
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(
                                                      patient['lastAppointmentStatus'],
                                                    ),
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _getStatusColor(
                                                        patient['lastAppointmentStatus'],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                        size: 24.sp,
                                      ),
                                    ],
                                  ),
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
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'status_pending'.tr;
      case 'accepted':
        return 'status_confirmed'.tr;
      case 'cancelled':
        return 'status_cancelled'.tr;
      case 'completed':
        return 'status_completed'.tr;
      default:
        return 'status_unknown'.tr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
