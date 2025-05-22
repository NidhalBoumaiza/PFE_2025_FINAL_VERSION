import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SecoursScreen extends StatefulWidget {
  const SecoursScreen({super.key});

  @override
  State<SecoursScreen> createState() => _SecoursScreenState();
}

class _SecoursScreenState extends State<SecoursScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final List<String> _categories = [
    'all',
    'emergency',
    'common',
    'children',
    'elderly',
  ];

  final List<Map<String, dynamic>> _firstAidItems = [
    {
      'title': 'cpr_title'.tr,
      'description': 'cpr_desc'.tr,
      'icon': FontAwesomeIcons.heartPulse,
      'category': 'emergency',
      'color': Colors.red,
    },
    {
      'title': 'bleeding_title'.tr,
      'description': 'bleeding_desc'.tr,
      'icon': FontAwesomeIcons.droplet,
      'category': 'common',
      'color': Colors.red[700],
    },
    {
      'title': 'burns_title'.tr,
      'description': 'burns_desc'.tr,
      'icon': FontAwesomeIcons.fire,
      'category': 'common',
      'color': Colors.orange,
    },
    {
      'title': 'choking_title'.tr,
      'description': 'choking_desc'.tr,
      'icon': FontAwesomeIcons.lungs,
      'category': 'emergency',
      'color': Colors.purple,
    },
    {
      'title': 'fractures_title'.tr,
      'description': 'fractures_desc'.tr,
      'icon': FontAwesomeIcons.bone,
      'category': 'common',
      'color': Colors.blue[700],
    },
    {
      'title': 'Stroke Recognition',
      'description':
          'Recognize the signs of stroke using the FAST method and how to respond quickly.',
      'icon': FontAwesomeIcons.brain,
      'category': 'emergency',
      'color': Colors.deepPurple,
    },
    {
      'title': 'Heart Attack',
      'description':
          'Identify symptoms of a heart attack and the immediate actions to take.',
      'icon': FontAwesomeIcons.heart,
      'category': 'emergency',
      'color': Colors.red,
    },
    {
      'title': 'Allergic Reactions',
      'description':
          'How to recognize and respond to severe allergic reactions, including anaphylaxis.',
      'icon': FontAwesomeIcons.viruses,
      'category': 'common',
      'color': Colors.amber[700],
    },
    {
      'title': 'Poisoning',
      'description':
          'First aid for ingested, inhaled, or contact poisoning and when to seek help.',
      'icon': FontAwesomeIcons.skullCrossbones,
      'category': 'children',
      'color': Colors.green[800],
    },
    {
      'title': 'Seizures',
      'description':
          'How to safely help someone experiencing seizures and prevent injury.',
      'icon': FontAwesomeIcons.bolt,
      'category': 'common',
      'color': Colors.amber,
    },
    {
      'title': 'Heat Stroke',
      'description':
          'Recognizing and treating heat-related illnesses, particularly in hot weather.',
      'icon': FontAwesomeIcons.temperatureHigh,
      'category': 'common',
      'color': Colors.deepOrange,
    },
    {
      'title': 'Diabetes Emergency',
      'description':
          'How to help someone experiencing hypoglycemia or hyperglycemia.',
      'icon': FontAwesomeIcons.fileWaveform,
      'category': 'common',
      'color': Colors.blue,
    },
    {
      'title': 'Child CPR',
      'description':
          'Special CPR techniques adjusted for infants and children.',
      'icon': FontAwesomeIcons.child,
      'category': 'children',
      'color': Colors.lightBlue,
    },
    {
      'title': 'Elderly Falls',
      'description':
          'How to safely help an elderly person who has fallen and assess for injuries.',
      'icon': FontAwesomeIcons.personWalking,
      'category': 'elderly',
      'color': Colors.grey[700],
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _firstAidItems.where((item) {
      final matchesSearch =
          item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['description'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == 'all' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "first_aid_title".tr,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 24, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child:
                _filteredItems.isEmpty
                    ? _buildNoResultsFound()
                    : _buildFirstAidGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.raleway(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          hintText: 'search_condition'.tr,
          hintStyle: GoogleFonts.raleway(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                category.tr,
                style: GoogleFonts.raleway(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFirstAidGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildFirstAidCard(item);
      },
    );
  }

  Widget _buildFirstAidCard(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to detailed first aid instructions
          _showFirstAidDetails(item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in colored circle
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 24,
                  color: item['color'] as Color,
                ),
              ),
              SizedBox(height: 12),

              // Category badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['category'],
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Title
              Text(
                item['title'],
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  item['description'],
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'no_results_found'.tr,
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'try_another_search'.tr,
            style: GoogleFonts.raleway(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFirstAidDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item['title'],
                          style: GoogleFonts.raleway(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'description'.tr,
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          item['description'],
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 24),
                        Text(
                          'recommended_first_aid'.tr,
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Placeholder content for first aid steps
                        _buildFirstAidStep(
                          1,
                          'assess_situation'.tr,
                          'assess_situation_desc'.tr,
                        ),
                        _buildFirstAidStep(
                          2,
                          'call_for_help'.tr,
                          'call_for_help_desc'.tr,
                        ),
                        _buildFirstAidStep(
                          3,
                          'administer_first_aid'.tr,
                          'administer_first_aid_desc'.tr,
                        ),
                        _buildFirstAidStep(
                          4,
                          'monitor_condition'.tr,
                          'monitor_condition_desc'.tr,
                        ),

                        SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Launch emergency call
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.phone, size: 20),
                            label: Text(
                              'emergency_call'.tr,
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFirstAidStep(int stepNumber, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber.toString(),
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
