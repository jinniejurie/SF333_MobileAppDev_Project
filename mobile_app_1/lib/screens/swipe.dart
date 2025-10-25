// swipe.dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../widgets/app_bottom_navbar.dart';
import '../services/swipe_service.dart';

class CardSwipe extends StatefulWidget {
  const CardSwipe({super.key});

  @override
  State<CardSwipe> createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> {
  final CardSwiperController _cardController = CardSwiperController();
  final SwipeService _swipeService = SwipeService();
  List<String> _userIds = []; // เก็บ userId ของ cards

  // Placeholder for the current user's GeoPoint.
  // Replace this with your actual user's location from Firestore. (lat,long)
  final GeoPoint currentUserLocation = const GeoPoint(13.899140468561423, 100.58104394247437);

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
  void _showMatchDialog(String matchedUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 It\'s a Match!'),
        content: const Text('You and this person liked each other! You can now chat with them.'),
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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8736CE),
              Color(0xFFE0CFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/cloud_logo.png',
                    width: 70,
                    height: 60,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Discover People',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
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
                              final userData =
                              doc.data() as Map<String, dynamic>;
                              final profileImage = userData['profileImage'] as String?;
                              final name = userData['name'] ?? 'Unknown';
                              final gender = userData['gender'] ?? '';
                              final bio = userData['bio'] ?? '';
                              final Timestamp? birthTimestamp =
                              userData['birthDate'];
                              final DateTime birthDate =
                                  birthTimestamp?.toDate() ?? DateTime(2000, 1, 1);
                              final today = DateTime.now();
                              int age = today.year - birthDate.year;
                              if (today.month < birthDate.month ||
                                  (today.month == birthDate.month &&
                                      today.day < birthDate.day)) {
                                age--;
                              }

                              // Get the profile's GeoPoint
                              final GeoPoint? profileLocation = userData['location'] as GeoPoint?;
                              String distanceText = '';
                              if (profileLocation != null) {
                                final double distance = _calculateDistance(currentUserLocation, profileLocation);
                                distanceText = '${distance.toStringAsFixed(1)} km away';
                              }

                              // Fetch interests
                              final interestsRefs =
                              userData['interest'] as List<dynamic>?;
                              final interests =
                              await _getInterests(interestsRefs);
                              final disRefs =
                              userData['disability'] as List<dynamic>?;
                              final disabilities =
                              await _getDisability(disRefs);


                              return Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.black, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: const Offset(0, 5))
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: (profileImage != null && profileImage.isNotEmpty)
                                            ? ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            profileImage,
                                            height: 300,
                                            width: 300,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                              Icons.person,
                                              size: 300,
                                              color: Color(0xFFD0F3FF),
                                            ),
                                          ),
                                        )
                                            : const Icon(
                                          Icons.person,
                                          size: 300,
                                          color: Color(0xFFD0F3FF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                fontSize: 28,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            ', $age',
                                            style: const TextStyle(
                                                fontSize: 28,
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
                                      const SizedBox(height: 2),
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
                                          padding:
                                          const EdgeInsets.only(top: 20),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: disabilities
                                                .map((i) => Chip(
                                              label: Text(
                                                i,
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                              backgroundColor:
                                              const Color(0xFFD0F3FF),
                                              shape: const StadiumBorder(
                                                side: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                              ),
                                            ))
                                                .toList(),
                                          ),
                                        ),
                                      if (interests.isNotEmpty)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(top: 10),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: interests
                                                .map((i) => Chip(
                                              label: Text(
                                                i,
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              backgroundColor:
                                              Colors.black,
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
                            }).toList()),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final cards = snapshot.data!;
                              return CardSwiper(
                                controller: _cardController,
                                cardsCount: cards.length,
                                cardBuilder:
                                    (context, index, percentX, percentY) =>
                                cards[index],
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
                      child: GestureDetector(
                        onTap: () async {
                          // Swipe left (pass)
                          _cardController.swipe(CardSwiperDirection.left);
                        },
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                          padding: const EdgeInsets.all(20),
                          child: const Icon(Icons.close, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () async {
                          // Swipe right (like)
                          _cardController.swipe(CardSwiperDirection.right);
                        },
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                          padding: const EdgeInsets.all(20),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onChanged: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).popUntil((route) => route.isFirst);
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
