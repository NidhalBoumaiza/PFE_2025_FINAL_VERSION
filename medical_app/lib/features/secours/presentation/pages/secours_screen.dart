import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

class SecoursScreen extends StatefulWidget {
  const SecoursScreen({super.key});

  @override
  State<SecoursScreen> createState() => _SecoursScreenState();
}

class _SecoursScreenState extends State<SecoursScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'tous';
  final List<String> _categories = ['tous', 'urgence'];

  final List<Map<String, dynamic>> _firstAidItems = [
    {
      'title': 'Réanimation cardio-pulmonaire (RCP)',
      'description': 'Appuyer sur la poitrine pour relancer le cœur.',
      'icon': FontAwesomeIcons.heartPulse,
      'category': 'urgence',
      'color': Colors.red,
      'videoPath': 'assets/videos/defibrillator_cpr.mp4',
      'videoDescription':
      'Montre comment appuyer sur la poitrine et utiliser un défibrillateur pour sauver une vie.',
      'quiz': {
        'question': 'Quelle est la première étape de la RCP ?',
        'options': [
          'Vérifier si la personne respire',
          'Appeler les secours immédiatement',
          'Commencer à masser le cœur',
        ],
        'correctAnswer': 'Vérifier si la personne respire',
        'feedback':
        'Il faut d\'abord vérifier si la personne respire avant de commencer la RCP.',
      },
    },
    {
      'title': 'Saignement',
      'description': 'Appuyer sur la plaie pour arrêter le sang.',
      'icon': FontAwesomeIcons.droplet,
      'category': 'urgence',
      'color': Colors.red[700],
      'videoPath': 'assets/videos/first_aid_deep_cut.mp4',
      'videoDescription':
      'Explique comment presser une plaie et la surélever pour réduire le saignement.',
      'quiz': {
        'question': 'Que faire en cas de saignement important ?',
        'options': [
          'Mettre un garrot immédiatement',
          'Appuyer fermement sur la plaie',
          'Rincer la plaie à l\'eau',
        ],
        'correctAnswer': 'Appuyer fermement sur la plaie',
        'feedback':
        'Appuyer fermement sur la plaie aide à contrôler le saignement rapidement.',
      },
    },
    {
      'title': 'Brûlures',
      'description': 'Refroidir la brûlure avec de l\'eau froide.',
      'icon': FontAwesomeIcons.fire,
      'category': 'urgence',
      'color': Colors.orange,
      'videoPath': 'assets/videos/burns_treatment.mp4',
      'videoDescription':
      'Montre comment passer la brûlure sous l\'eau froide et la couvrir d\'un pansement.',
      'quiz': {
        'question': 'Combien de temps faut-il refroidir une brûlure ?',
        'options': ['2 minutes', '10 à 15 minutes', '30 secondes'],
        'correctAnswer': '10 à 15 minutes',
        'feedback':
        'Refroidir une brûlure pendant 10 à 15 minutes aide à réduire la douleur et les dégâts.',
      },
    },
    {
      'title': 'Étouffement',
      'description': 'Aider à dégager les voies respiratoires.',
      'icon': FontAwesomeIcons.lungs,
      'category': 'urgence',
      'color': Colors.purple,
      'videoPath': 'assets/videos/choking_treatment.mp4',
      'videoDescription':
      'Montre comment faire la manœuvre de Heimlich pour libérer les voies respiratoires.',
      'quiz': {
        'question': 'Quelle technique utilise-t-on pour un étouffement ?',
        'options': [
          'Tapoter le dos doucement',
          'Effectuer la manœuvre de Heimlich',
          'Donner de l\'eau à boire',
        ],
        'correctAnswer': 'Effectuer la manœuvre de Heimlich',
        'feedback':
        'La manœuvre de Heimlich est la méthode efficace pour dégager un blocage des voies respiratoires.',
      },
    },
    {
      'title': 'Personne inconsciente qui respire',
      'description': 'Mettre la personne sur le côté pour respirer.',
      'icon': FontAwesomeIcons.userXmark,
      'category': 'urgence',
      'color': Colors.indigo,
      'videoPath': 'assets/videos/unconscious_breathing_person.mp4',
      'videoDescription':
      'Montre comment placer une personne en position latérale pour qu\'elle respire mieux.',
      'quiz': {
        'question':
        'Dans quelle position place-t-on une personne inconsciente qui respire ?',
        'options': ['Sur le dos', 'Sur le côté', 'Assise'],
        'correctAnswer': 'Sur le côté',
        'feedback':
        'La position latérale de sécurité aide à garder les voies respiratoires ouvertes.',
      },
    },
    {
      'title': 'Sauvetage de véhicule',
      'description': 'Sortir une personne d\'une voiture en sécurité.',
      'icon': FontAwesomeIcons.car,
      'category': 'urgence',
      'color': Colors.brown,
      'videoPath': 'assets/videos/car_rescue_rautek_maneuver.mp4',
      'videoDescription':
      'Montre comment utiliser la manœuvre de Rautek pour sortir une personne sans la blesser.',
      'quiz': {
        'question': 'Quel est l\'objectif principal de la manœuvre de Rautek ?',
        'options': [
          'Sortir rapidement sans précaution',
          'Protéger la colonne vertébrale',
          'Vérifier la respiration',
        ],
        'correctAnswer': 'Protéger la colonne vertébrale',
        'feedback':
        'La manœuvre de Rautek vise à minimiser les risques de blessure à la colonne vertébrale.',
      },
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
          _selectedCategory == 'tous' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Premiers Secours',
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
          hintText: 'Rechercher une condition',
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
                category == 'tous' ? 'Tous' : 'Urgence',
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
    final hasVideo = item['videoPath'] != null;

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showFirstAidDetails(item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Urgence',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
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
            if (hasVideo)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
              ),
          ],
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
            'Aucun résultat trouvé',
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Essayez une autre recherche',
            style: GoogleFonts.raleway(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFirstAidDetails(Map<String, dynamic> item) {
    final hasVideo = item['videoPath'] != null;

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
                      Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                          if (hasVideo) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasVideo) ...[
                      Text(
                        'Vidéo de démonstration',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      VideoPlayerWidget(videoPath: item['videoPath']),
                      SizedBox(height: 24),
                    ],
                    Text(
                      'Description',
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
                    if (hasVideo) ...[
                      SizedBox(height: 24),
                      Text(
                        'Vidéo expliquée',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item['videoDescription'],
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    Text(
                      'Quiz',
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildQuiz(item['quiz']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(Map<String, dynamic> quiz) {
    return QuizWidget(quiz: quiz);
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWidget({super.key, required this.videoPath});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Chargement de la vidéo...',
                style: GoogleFonts.raleway(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            VideoPlayer(_controller!),
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.primaryColor,
                  bufferedColor: Colors.grey[300]!,
                  backgroundColor: Colors.grey[600]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizWidget extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizWidget({super.key, required this.quiz});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> with TickerProviderStateMixin {
  String? selectedAnswer;
  bool showFeedback = false;
  bool isCorrect = false;
  late AnimationController _animationController;
  late AnimationController _feedbackController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer) async {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = answer;
      isCorrect = answer == widget.quiz['correctAnswer'];
      showFeedback = true;
    });

    // Play selection animation
    await _animationController.forward();
    await _animationController.reverse();

    // Play feedback animation
    _feedbackController.forward();

    // Haptic feedback
    if (isCorrect) {
      // Light impact for correct answer
    } else {
      // Medium impact for wrong answer
    }
  }

  void _resetQuiz() {
    setState(() {
      selectedAnswer = null;
      showFeedback = false;
      isCorrect = false;
    });
    _feedbackController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quiz de vérification',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (showFeedback)
                IconButton(
                  onPressed: _resetQuiz,
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Recommencer',
                ),
            ],
          ),
          SizedBox(height: 20),

          // Question
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
              showFeedback
                  ? (isCorrect ? Colors.green[50] : Colors.red[50])
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                showFeedback
                    ? (isCorrect ? Colors.green[200]! : Colors.red[200]!)
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Text(
              widget.quiz['question'],
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Answer Options
          ...widget.quiz['options'].asMap().entries.map<Widget>((entry) {
            int index = entry.key;
            String option = entry.value;
            bool isSelectedOption = option == selectedAnswer;
            bool isCorrectOption = option == widget.quiz['correctAnswer'];

            return AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                  isSelectedOption && !showFeedback
                      ? _scaleAnimation.value
                      : 1.0,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getOptionColor(
                              option,
                              isSelectedOption,
                              isCorrectOption,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getOptionBorderColor(
                                option,
                                isSelectedOption,
                                isCorrectOption,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              if (isSelectedOption)
                                BoxShadow(
                                  color: _getOptionColor(
                                    option,
                                    isSelectedOption,
                                    isCorrectOption,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Option Letter
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getOptionLetterColor(
                                    option,
                                    isSelectedOption,
                                    isCorrectOption,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(
                                      65 + index,
                                    ), // A, B, C, etc.
                                    style: GoogleFonts.raleway(
                                      color: _getOptionLetterTextColor(
                                        option,
                                        isSelectedOption,
                                        isCorrectOption,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Option Text
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.raleway(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _getOptionTextColor(
                                      option,
                                      isSelectedOption,
                                      isCorrectOption,
                                    ),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              // Result Icon
                              if (showFeedback && isSelectedOption)
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                    isCorrect ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCorrect ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              if (showFeedback &&
                                  !isSelectedOption &&
                                  isCorrectOption)
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),

          // Feedback Section
          if (showFeedback) ...[
            SizedBox(height: 20),
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                      isCorrect
                          ? [Colors.green[400]!, Colors.green[500]!]
                          : [Colors.orange[400]!, Colors.orange[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect ? Colors.green : Colors.orange)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.celebration : Icons.lightbulb,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isCorrect ? 'Excellent!' : 'Bonne tentative!',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.quiz['feedback'],
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getOptionColor(String option, bool isSelected, bool isCorrect) {
    if (!showFeedback) {
      return isSelected
          ? AppColors.primaryColor.withOpacity(0.1)
          : Colors.white;
    }

    if (option == selectedAnswer) {
      return isCorrect ? Colors.green[100]! : Colors.red[100]!;
    } else if (isCorrect) {
      return Colors.green[50]!;
    }
    return Colors.grey[100]!;
  }

  Color _getOptionBorderColor(String option, bool isSelected, bool isCorrect) {
    if (!showFeedback) {
      return isSelected ? AppColors.primaryColor : Colors.grey[300]!;
    }

    if (option == selectedAnswer) {
      return isCorrect ? Colors.green : Colors.red;
    } else if (isCorrect) {
      return Colors.green;
    }
    return Colors.grey[300]!;
  }

  Color _getOptionLetterColor(String option, bool isSelected, bool isCorrect) {
    if (!showFeedback) {
      return isSelected ? AppColors.primaryColor : Colors.grey[300]!;
    }

    if (option == selectedAnswer) {
      return isCorrect ? Colors.green : Colors.red;
    } else if (isCorrect) {
      return Colors.green;
    }
    return Colors.grey[300]!;
  }

  Color _getOptionLetterTextColor(
      String option,
      bool isSelected,
      bool isCorrect,
      ) {
    if (!showFeedback) {
      return isSelected ? Colors.white : Colors.grey[600]!;
    }

    if (option == selectedAnswer || isCorrect) {
      return Colors.white;
    }
    return Colors.grey[600]!;
  }

  Color _getOptionTextColor(String option, bool isSelected, bool isCorrect) {
    if (!showFeedback) {
      return isSelected ? AppColors.primaryColor : Colors.grey[800]!;
    }

    if (option == selectedAnswer) {
      return isCorrect ? Colors.green[800]! : Colors.red[800]!;
    } else if (isCorrect) {
      return Colors.green[800]!;
    }
    return Colors.grey[600]!;
  }
}
