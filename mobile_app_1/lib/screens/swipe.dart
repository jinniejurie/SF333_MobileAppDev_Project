import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CardSwipe extends StatefulWidget {
  const CardSwipe({super.key});

  @override
  State<CardSwipe> createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> {
  final CardSwiperController _cardController = CardSwiperController();

  // Use a nullable variable to store the current user's location
  GeoPoint? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserLocation();
  }

  // Fetch the current user's location from Firestore
  Future<void> _fetchCurrentUserLocation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['location'] != null) {
          setState(() {
            _currentUserLocation = userData['location'] as GeoPoint;
          });
        }
      }
    }
  }

  Future<List<String>> _getInterests(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];
    List<String> interestNames = [];
    for (var ref in references) {
      if (ref is DocumentReference) {
        final doc = await ref.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null) {
            interestNames.add(data['name']);
          }
        }
      }
    }
    return interestNames;
  }

  Future<List<String>> _getDisability(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];
    List<String> disabilityNames = [];
    for (var ref in references) {
      if (ref is DocumentReference) {
        final doc = await ref.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null) {
            disabilityNames.add(data['name']);
          }
        }
      }
    }
    return disabilityNames;
  }

  // Calculate distance between profiles (จาก geopoint ใน data)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                          // Create a list of futures that will return user data with distance
                          final profilesWithDistanceFuture = documents.map((doc) async {
                            final userData = doc.data() as Map<String, dynamic>;
                            final profileLocation = userData['location'] as GeoPoint?;

                            double distance = double.infinity;
                            if (_currentUserLocation != null && profileLocation != null) {
                              distance = _calculateDistance(_currentUserLocation!, profileLocation);
                            }

                            return {'userData': userData, 'distance': distance};
                          }).toList();

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: Future.wait(profilesWithDistanceFuture),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final profilesWithDistance = snapshot.data!;

                              // Sort the profiles by distance, from closest to furthest
                              profilesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

                              // Now, create the widgets from the sorted list
                              final cards = profilesWithDistance.map((profileData) {
                                final userData = profileData['userData'];
                                final distance = profileData['distance'];

                                final profileImage = userData['profileImage'] as String?;
                                final name = userData['name'] ?? 'Unknown';
                                final gender = userData['gender'] ?? '';
                                final bio = userData['bio'] ?? '';
                                final Timestamp? birthTimestamp = userData['birthDate'];
                                final DateTime birthDate = birthTimestamp?.toDate() ?? DateTime(2000, 1, 1);
                                final today = DateTime.now();
                                int age = today.year - birthDate.year;
                                if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
                                  age--;
                                }

                                final interestsRefs = userData['interest'] as List<dynamic>?;
                                // Wait for interests before returning the widget
                                final interests = _getInterests(interestsRefs);

                                final disRefs = userData['disability'] as List<dynamic>?;
                                final disabilities = _getDisability(disRefs);

                                return FutureBuilder<List<String>>(
                                  future: interests,
                                  builder: (context, interestsSnapshot) {
                                    if (!interestsSnapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final interestsList = interestsSnapshot.data!;

                                    return FutureBuilder<List<String>>(
                                      future: disabilities,
                                      builder: (context, disabilitiesSnapshot) {
                                        if (!disabilitiesSnapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        final disabilitiesList = disabilitiesSnapshot.data!;

                                        String distanceText = distance == double.infinity ? 'Distance unknown' : '${distance.toStringAsFixed(1)} km away';

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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: profileImage != null && profileImage.isNotEmpty
                                                      ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: Image.network(
                                                      profileImage,
                                                      height: 300,
                                                      width: 300,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.person, size: 300, color: Color(0xFFD0F3FF)),
                                                    ),
                                                  )
                                                      : const Icon(Icons.person, size: 300, color: Color(0xFFD0F3FF)),
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
                                                    style: const TextStyle(
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
                                                if (disabilitiesList.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 20),
                                                    child: Wrap(
                                                      spacing: 8,
                                                      runSpacing: 4,
                                                      children: disabilitiesList
                                                          .map((i) => Chip(
                                                        label: Text(
                                                          i,
                                                          style: const TextStyle(color: Colors.black),
                                                        ),
                                                        backgroundColor: const Color(0xFFD0F3FF),
                                                        shape: const StadiumBorder(
                                                          side: BorderSide(
                                                              color: Colors.black, width: 1),
                                                        ),
                                                      ))
                                                          .toList(),
                                                    ),
                                                  ),
                                                if (interestsList.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 10),
                                                    child: Wrap(
                                                      spacing: 8,
                                                      runSpacing: 4,
                                                      children: interestsList
                                                          .map((i) => Chip(
                                                        label: Text(
                                                          i,
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                        backgroundColor: Colors.black,
                                                        shape: const StadiumBorder(
                                                          side: BorderSide(
                                                              color: Colors.black, width: 1),
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
                                  },
                                );
                              }).toList();

                              return CardSwiper(
                                controller: _cardController,
                                cardsCount: cards.length,
                                cardBuilder: (context, index, percentX, percentY) => cards[index],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // like/dislike over the cards
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _cardController.swipe(CardSwiperDirection.left),
                            child: Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                              padding: const EdgeInsets.all(20),
                              child: const Icon(Icons.close, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 40),
                          GestureDetector(
                            onTap: () => _cardController.swipe(CardSwiperDirection.right),
                            child: Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                              padding: const EdgeInsets.all(20),
                              child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                            ),
                          ),
                        ],
                      ),
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
}
