// swipe.dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/app_bottom_navbar.dart';
import '../widgets/accessible_container.dart';
import '../services/swipe_service.dart';
import '../providers/accessibility_provider.dart';

// Particle class for floating animation
class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.y -= particle.speed * 0.01;
      if (particle.y < -0.1) {
        particle.y = 1.1;
        particle.x = Random().nextDouble();
      }

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class CardSwipe extends StatefulWidget {
  const CardSwipe({super.key});

  @override
  State<CardSwipe> createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> with TickerProviderStateMixin {
  final CardSwiperController _cardController = CardSwiperController();
  final SwipeService _swipeService = SwipeService();
  List<String> _userIds = []; // เก็บ userId ของ cards

  bool showMatchAnimation = false;

  // Animation controllers
  late AnimationController _leftButtonController;
  late AnimationController _rightButtonController;
  late Animation<double> _leftButtonScale;
  late Animation<double> _rightButtonScale;
  late Animation<double> _leftButtonOpacity;
  late Animation<double> _rightButtonOpacity;

  // Particle animation controller
  late AnimationController _particleController;
  final List<Particle> _particles = [];

  // Placeholder for the current user's GeoPoint.
  // Replace this with your actual user's location from Firestore. (lat,long)
  final GeoPoint currentUserLocation = const GeoPoint(13.899140468561423, 100.58104394247437);

  @override
  void initState() {
    super.initState();

    // Initialize particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Create particles
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.3,
        opacity: random.nextDouble() * 0.3 + 0.1,
      ));
    }

    // Initialize left button animation
    _leftButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _leftButtonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_leftButtonController);

    _leftButtonOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7),
        weight: 30,
      ),
    ]).animate(_leftButtonController);

    // Initialize right button animation (with delay)
    _rightButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rightButtonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_rightButtonController);

    _rightButtonOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7),
        weight: 30,
      ),
    ]).animate(_rightButtonController);

    // Start animations with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _leftButtonController.forward();
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _rightButtonController.forward();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _leftButtonController.dispose();
    _rightButtonController.dispose();
    super.dispose();
  }

  Future<List<String>> _getInterests(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];
    final List<String> interestNames = [];
    for (final ref in references) {
      if (ref is DocumentReference) {
        // Use the reference id directly to avoid extra reads and permission issues
        if (ref.id.isNotEmpty) interestNames.add(ref.id);
      } else if (ref is String && ref.isNotEmpty) {
        interestNames.add(ref.split('/').isNotEmpty ? ref.split('/').last : ref);
      }
    }
    return interestNames;
  }

  Future<List<String>> _getDisability(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];
    final List<String> disabilityNames = [];
    for (final ref in references) {
      if (ref is DocumentReference) {
        if (ref.id.isNotEmpty) disabilityNames.add(ref.id);
      } else if (ref is String && ref.isNotEmpty) {
        disabilityNames.add(ref.split('/').isNotEmpty ? ref.split('/').last : ref);
      }
    }
    return disabilityNames;
  }

  // Build profile image widget - supports both URL and base64
  Widget _buildProfileImage(String? profileImageUrl, Uint8List? profileImageBytes) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return Image.network(
        profileImageUrl,
        height: 300,
        width: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Consumer<AccessibilityProvider>(
          builder: (context, accessibility, _) {
            return Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: accessibility.highContrastMode
                    ? Colors.white
                    : const Color(0xFFD6F0FF),
                borderRadius: BorderRadius.circular(20),
                border: accessibility.highContrastMode
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person,
                size: 150,
                color: accessibility.highContrastMode
                    ? Colors.black
                    : const Color(0xFF90CAF9),
              ),
            );
          },
        ),
      );
    } else if (profileImageBytes != null) {
      return Image.memory(
        profileImageBytes,
        height: 300,
        width: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Consumer<AccessibilityProvider>(
          builder: (context, accessibility, _) {
            return Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: accessibility.highContrastMode
                    ? Colors.white
                    : const Color(0xFFD6F0FF),
                borderRadius: BorderRadius.circular(20),
                border: accessibility.highContrastMode
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person,
                size: 150,
                color: accessibility.highContrastMode
                    ? Colors.black
                    : const Color(0xFF90CAF9),
              ),
            );
          },
        ),
      );
    } else {
      return Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: accessibility.highContrastMode
                  ? Colors.white
                  : const Color(0xFFD6F0FF),
              borderRadius: BorderRadius.circular(20),
              border: accessibility.highContrastMode
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
            child: Icon(
              Icons.person,
              size: 150,
              color: accessibility.highContrastMode
                  ? Colors.black
                  : const Color(0xFF90CAF9),
            ),
          );
        },
      );
    }
  }

  //Calculate distance between profiles (จาก geopoint ใน data)
  double _calculateDistance(GeoPoint p1, GeoPoint p2) {
    const double earthRadius = 6371; // Radius of Earth in km

    double lat1 = _degreesToRadians(p1.latitude);
    double lon1 = _degreesToRadians(p1.longitude);
    double lat2 = _degreesToRadians(p2.latitude);
    double lon2 = _degreesToRadians(p2.longitude);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // จัดการ swipe action
  Future<void> _handleSwipe(String userId, bool isLike) async {
    try {
      await _swipeService.swipeUser(userId, isLike);

      if (isLike) {
        // แสดงข้อความ match ถ้ามี
        final isMatch = await _swipeService.isMatch(userId);
        if (isMatch && mounted) {
          _showMatchDialog(userId);
        }
      }
    } catch (e) {
      print('Error handling swipe: $e');
    }
  }

  // แสดง dialog เมื่อมี match
  // แสดง dialog เมื่อมี match
  void _showMatchDialog(String matchedUserId) {
    // 1. Trigger the match animation
    setState(() {
      showMatchAnimation = true;
    });

    // 2. Show the dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 It\'s a Match!'),
        content: const Text('You and this person liked each other!\n You can now chat with them.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continue Swiping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ไปหน้า chat list
              Navigator.of(context).pushNamed('/chatList');
            },
            child: const Text('Start Chatting'),
          ),
        ],
      ),
    );

    // 3. Stop the animation after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showMatchAnimation = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEE9DFF),
                  Color(0xFFC1E5FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Main content
          if (showMatchAnimation) const FloatingHearts(),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: Image.asset(
                                'assets/cloud_logo.png',
                                width: 42,
                                height: 34,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Semantics(
                                header: true,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Discover People',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 80), // Add this padding
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 365,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('Something went wrong',
                                    style: TextStyle(color: Colors.white)),
                              );
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final documents = snapshot.data!.docs;
                            if (documents.isEmpty) {
                              return const Center(
                                child: Text('No users found',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                              );
                            }

                            // เก็บ userIds
                            _userIds = documents.map((doc) => doc.id).toList();

                            // Create cards
                            return FutureBuilder<List<Widget>>(
                              future: Future.wait(documents.map((doc) async {
                                try {
                                  final userData = doc.data() as Map<String, dynamic>;

                                  // Handle profile image - support both profileImage (URL) and avatarBase64
                                  String? profileImageUrl;
                                  Uint8List? profileImageBytes;
                                  final profileImage = userData['profileImage'] as String?;
                                  final avatarBase64 = userData['avatarBase64'] as String?;

                                  if (profileImage != null && profileImage.isNotEmpty) {
                                    profileImageUrl = profileImage;
                                  } else if (avatarBase64 != null && avatarBase64.isNotEmpty) {
                                    try {
                                      profileImageBytes = base64Decode(avatarBase64);
                                    } catch (e) {
                                      debugPrint('Failed to decode avatarBase64: $e');
                                    }
                                  }

                                  final name = userData['name'] ?? 'Unknown';
                                  final gender = userData['gender'] ?? '';
                                  final bio = userData['bio'] ?? '';

                                  // Handle birthDate - support both Timestamp and String
                                  DateTime birthDate = DateTime(2000, 1, 1);
                                  final birthDateValue = userData['birthDate'];
                                  if (birthDateValue is Timestamp) {
                                    birthDate = birthDateValue.toDate();
                                  } else if (birthDateValue is String) {
                                    try {
                                      // Try parsing string format like "January 11, 2000 at 12:00:00 AM UTC+7"
                                      // First try standard DateTime.parse
                                      birthDate = DateTime.parse(birthDateValue);
                                    } catch (e) {
                                      // If standard parse fails, try manual parsing for format "January 11, 2000 at 12:00:00 AM UTC+7"
                                      try {
                                        final parts = birthDateValue.split(' at ');
                                        if (parts.isNotEmpty) {
                                          final datePart = parts[0]; // "January 11, 2000"
                                          final monthNames = {
                                            'January': 1, 'February': 2, 'March': 3, 'April': 4,
                                            'May': 5, 'June': 6, 'July': 7, 'August': 8,
                                            'September': 9, 'October': 10, 'November': 11, 'December': 12
                                          };

                                          for (final entry in monthNames.entries) {
                                            if (datePart.contains(entry.key)) {
                                              final dayYear = datePart.replaceAll(entry.key, '').trim();
                                              final dayYearParts = dayYear.split(', ');
                                              if (dayYearParts.length == 2) {
                                                final day = int.parse(dayYearParts[0]);
                                                final year = int.parse(dayYearParts[1]);
                                                birthDate = DateTime(year, entry.value, day);
                                                break;
                                              }
                                            }
                                          }
                                        }
                                      } catch (e2) {
                                        debugPrint('Failed to parse birthDate string: $birthDateValue');
                                      }
                                    }
                                  }

                                  final today = DateTime.now();
                                  int age = today.year - birthDate.year;
                                  if (today.month < birthDate.month ||
                                      (today.month == birthDate.month &&
                                          today.day < birthDate.day)) {
                                    age--;
                                  }

                                  // Get the profile's GeoPoint - support both 'location' and 'location_geopoint'
                                  GeoPoint? profileLocation = userData['location'] as GeoPoint?;
                                  if (profileLocation == null) {
                                    profileLocation = userData['location_geopoint'] as GeoPoint?;
                                  }

                                  String distanceText = '';
                                  if (profileLocation != null) {
                                    final double distance = _calculateDistance(currentUserLocation, profileLocation);
                                    distanceText = '${distance.toStringAsFixed(1)} km away';
                                  }

                                  // Fetch interests
                                  final interestsRefs = userData['interest'] as List<dynamic>?;
                                  final interests = await _getInterests(interestsRefs);
                                  final disRefs = userData['disability'] as List<dynamic>?;
                                  final disabilities = await _getDisability(disRefs);

                                  return Consumer<AccessibilityProvider>(
                                    builder: (context, accessibility, _) {
                                      return Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                          border: accessibility.highContrastMode
                                              ? Border.all(color: Colors.black, width: 3)
                                              : null,
                                          boxShadow: accessibility.highContrastMode
                                              ? null
                                              : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 40,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: _buildProfileImage(
                                                    profileImageUrl,
                                                    profileImageBytes,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    ', $age',
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              if (gender.isNotEmpty)
                                                Text(
                                                  gender,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black),
                                                ),
                                              const SizedBox(height: 8),
                                              if (distanceText.isNotEmpty)
                                                Text(
                                                  distanceText,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[500]),
                                                ),
                                              const SizedBox(height: 15),
                                              if (bio.isNotEmpty)
                                                Text(
                                                  bio,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              if (disabilities.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 20),
                                                  child: Consumer<AccessibilityProvider>(
                                                    builder: (context, accessibility, _) {
                                                      return Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        children: disabilities
                                                            .map((i) => Chip(
                                                          label: Text(
                                                            i,
                                                            style: const TextStyle(color: Colors.black),
                                                          ),
                                                          backgroundColor: accessibility.highContrastMode
                                                              ? Colors.white
                                                              : const Color(0xFFD6F0FF),
                                                          shape: StadiumBorder(
                                                            side: BorderSide(
                                                                color: Colors.black,
                                                                width: accessibility.highContrastMode ? 2 : 1),
                                                          ),
                                                        ))
                                                            .toList(),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              if (interests.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 10),
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: interests
                                                        .map((i) => Chip(
                                                      label: Text(
                                                        i,
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                      backgroundColor: Colors.black,
                                                      shape: const StadiumBorder(
                                                        side: BorderSide(
                                                            color: Colors.black,
                                                            width: 1),
                                                      ),
                                                    ))
                                                        .toList(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } catch (e, stackTrace) {
                                  debugPrint('Error building card for user ${doc.id}: $e');
                                  debugPrint('Stack trace: $stackTrace');
                                  // Return a placeholder card on error
                                  return Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.red, width: 1),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Error loading user data',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  );
                                }
                              }).toList()),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  debugPrint('FutureBuilder error: ${snapshot.error}');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, size: 48, color: Colors.white),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error loading cards: ${snapshot.error}',
                                          style: const TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No cards available',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }
                                final cards = snapshot.data!;
                                return CardSwiper(
                                  controller: _cardController,
                                  cardsCount: cards.length,
                                  cardBuilder: (context, index, percentX, percentY) => cards[index],
                                  onSwipe: (previousIndex, currentIndex, direction) async {
                                    if (previousIndex != null && previousIndex < _userIds.length) {
                                      final userId = _userIds[previousIndex];
                                      final isLike = direction == CardSwiperDirection.right;
                                      await _handleSwipe(userId, isLike);
                                    }
                                    return true;
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: AnimatedBuilder(
                          animation: _leftButtonController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _leftButtonScale.value,
                              child: Opacity(
                                opacity: _leftButtonOpacity.value,
                                child: GestureDetector(
                                  onTap: () async {
                                    // Swipe left (pass)
                                    _cardController.swipe(CardSwiperDirection.left);
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: AnimatedBuilder(
                          animation: _rightButtonController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _rightButtonScale.value,
                              child: Opacity(
                                opacity: _rightButtonOpacity.value,
                                child: GestureDetector(
                                  onTap: () async {
                                    // Swipe right (like)
                                    _cardController.swipe(CardSwiperDirection.right);
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),)
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onChanged: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              break;
            case 1:
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/communityDiscover');
              break;
            case 2:
            // Already on swipe page
              break;
            case 3:
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/friendsScreen');
              break;
            case 4:
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/chatList');
              break;
          }
        },
        onPlus: () {
          Navigator.of(context).pushNamed('/createPost');
        },
      ),
    );
  }
}

class FloatingHearts extends StatefulWidget {
  const FloatingHearts({super.key});

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  final List<_Heart> hearts = [];

  @override
  void initState() {
    super.initState();
    _spawnHearts();
  }

  void _spawnHearts() {
    for (int i = 0; i < 12; i++) {
      hearts.add(
        _Heart(
          id: UniqueKey(),
          left: (50 + i * 20).toDouble() % 300,
          startTime: Duration(milliseconds: i * 200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: hearts.map((h) {
        return TweenAnimationBuilder<double>(
          key: h.id,
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 2800),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Positioned(
              bottom: 0 + (value * -250),
              left: h.left,
              child: Opacity(
                opacity: value,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.pink,
                  size: 36,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _Heart {
  final Key id;
  final double left;
  final Duration startTime;

  _Heart({required this.id, required this.left, required this.startTime});
}
