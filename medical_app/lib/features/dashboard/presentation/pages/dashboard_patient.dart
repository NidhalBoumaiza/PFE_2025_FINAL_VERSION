import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/secours/presentation/pages/secours_screen.dart';
import 'package:medical_app/features/settings/presentation/pages/settings_patient.dart';
import 'package:get/get.dart';
import '../../../../core/specialties.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/models/user_model.dart';
import '../../../localisation/presentation/pages/pharmacie_page.dart';
import '../../../rendez_vous/presentation/pages/RendezVousPatient.dart';
import '../../../rendez_vous/presentation/blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import '../../../specialite/presentation/pages/AllSpecialtiesPage.dart';

class Dashboardpatient extends StatefulWidget {
  const Dashboardpatient({super.key});

  @override
  State<Dashboardpatient> createState() => _DashboardpatientState();
}

class _DashboardpatientState extends State<Dashboardpatient> {
  late RendezVousBloc _rendezVousBloc;
  UserModel? currentUser;

  // Data for "Que cherchez-vous ?" section (using Icons)
  final List<Map<String, dynamic>> searchItems = [
    {
      'icon': FontAwesomeIcons.userDoctor,
      'text': 'doctors'.tr,
      'color': AppColors.primaryColor,
    },
    {
      'icon': FontAwesomeIcons.prescriptionBottleMedical,
      'text': 'pharmacies'.tr,
      'color': Colors.green,
    },
    {
      'icon': FontAwesomeIcons.hospital,
      'text': 'hospitals'.tr,
      'color': Colors.redAccent,
    },
  ];

  // Data for "Spécialités" section (using asset images)

  // Data for "Vidéos éducatives de premiers secours" section
  final List<Map<String, dynamic>> firstAidVideos = [
    {
      'image': 'assets/images/cpr1.jpg',
      'text': 'resuscitation'.tr,
      'videoUrl': 'https://example.com/fainting_video',
    },
    {
      'image': 'assets/images/choking.jpg',
      'text': 'choking'.tr,
      'videoUrl': 'https://example.com/choking_video',
    },
    {
      'image': 'assets/images/bleeding2.jpg',
      'text': 'bleeding'.tr,
      'videoUrl': 'https://example.com/bleeding_video',
    },
    {
      'image': 'assets/images/brulure.jpg',
      'text': 'burns'.tr,
      'videoUrl': 'https://example.com/burns_video',
    },
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _rendezVousBloc = di.sl<RendezVousBloc>();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < firstAidVideos.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        setState(() {
          currentUser = user;
        });

        if (user.id != null) {
          // Check and update past appointments
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: user.id!,
              userRole: 'patient',
            ),
          );
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Que cherchez-vous ?" Section
              Text(
                'what_are_you_looking_for'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: searchItems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            final itemText =
                                searchItems[index]["text"] as String;
                            if (itemText == 'doctors'.tr) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AllSpecialtiesPage(
                                        specialties: getSpecialtiesWithImages(),
                                      ),
                                ),
                              );
                            } else if (itemText == 'pharmacies'.tr) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PharmaciePage(),
                                ),
                              );
                            } else if (itemText == 'hospitals'.tr) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PharmaciePage(),
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: theme.cardColor,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  searchItems[index]['icon'],
                                  size: 30,
                                  color: searchItems[index]['color'],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  searchItems[index]['text'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // "Spécialités" Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'specialties'.tr,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AllSpecialtiesPage(
                                specialties: getSpecialtiesWithImages(),
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'see_all'.tr,
                      style: const TextStyle(
                        fontSize: 25,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: getSpecialtiesWithImages().length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                          context,
                          RendezVousPatient(
                            selectedSpecialty:
                                getSpecialtiesWithImages()[index]['text'],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: theme.cardColor,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    AppColors
                                        .primaryColor, //couleur des icones de specialités
                                    BlendMode.srcATop,
                                  ),
                                  child: Image.asset(
                                    getSpecialtiesWithImages()[index]['image']!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.error,
                                        size: 30,
                                        color: Colors.red,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                //nom du spécialité
                                Text(
                                  getSpecialtiesWithImages()[index]['text']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // "Premiers Secours" Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'first_aid'.tr,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecoursScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'see_all'.tr,
                      style: const TextStyle(
                        fontSize: 25,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: firstAidVideos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SecoursScreen(),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: Image.asset(
                                firstAidVideos[index]['image']!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.error,
                                    size: 60,
                                    color: Colors.red,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                firstAidVideos[index]['text']!,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.headlineSmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  firstAidVideos.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index
                              ? AppColors.primaryColor
                              : (isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
