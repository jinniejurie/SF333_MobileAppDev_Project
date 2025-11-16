// lib/screens/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'event_detail_page.dart';
import 'community_home.dart';
import 'create_post_page.dart';
import 'create_event_page.dart';
import '../widgets/accessible_container.dart';
import '../providers/accessibility_provider.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CommunityHome()),
                );
              },
              child: const Text(
                'Threads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 28),
            const Text(
              'Event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: AccessibleContainer(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      header: true,
                      child: Expanded(
                        child: Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Consumer<AccessibilityProvider>(
                      builder: (context, accessibility, _) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateEventPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: accessibility.highContrastMode 
                                  ? Colors.black 
                                  : const Color(0xFF90CAF9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Create Event',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collectionGroup('events').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              
              // Filter out past events and sort by upvotes
              final now = DateTime.now();
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                
                // Try to get event end time first, then start time, then date
                dynamic eventTime = data['end_time'] ?? data['start_time'] ?? data['date'];
                
                if (eventTime != null) {
                  DateTime eventDateTime;
                  try {
                    if (eventTime is Timestamp) {
                      eventDateTime = eventTime.toDate();
                    } else if (eventTime is String) {
                      eventDateTime = DateTime.parse(eventTime);
                    } else {
                      // If we can't parse, include the event
                      return true;
                    }
                    // Include event if it hasn't ended yet
                    return !eventDateTime.isBefore(now);
                  } catch (e) {
                    // If parsing fails, include the event
                    return true;
                  }
                }
                // If no date/time field, include the event
                return true;
              }).toList();
              
              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No upcoming events found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total events: ${docs.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              // Sort by upvote count (highest first)
              filteredDocs.sort((a, b) {
                final aUpvotes = (a.data()['upvotes'] as List?)?.length ?? 0;
                final bUpvotes = (b.data()['upvotes'] as List?)?.length ?? 0;
                return bUpvotes.compareTo(aUpvotes);
              });
              
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final event = filteredDocs[index].data() as Map<String, dynamic>;
                  // สีพื้นหลังสำหรับแต่ละ event
                  List<Color> eventColors = [
                    const Color.fromARGB(255, 172, 199, 219),
                    const Color.fromARGB(255, 145, 203, 145),
                    const Color.fromARGB(255, 170, 111, 184),
                    const Color(0xFFFFE4B5),
                    const Color.fromARGB(255, 228, 145, 97),
                  ];

                  // คำนวณจำนวนวันที่เหลือ
                  String getDaysLeft(dynamic dateValue) {
                    try {
                      DateTime eventDate;
                      if (dateValue is String) {
                        List<String> parts = dateValue.split('-');
                        int day = int.parse(parts[0]);
                        int month = int.parse(parts[1]);
                        int year = int.parse(parts[2]);
                        eventDate = DateTime(year, month, day);
                      } else if (dateValue is Timestamp) {
                        eventDate = dateValue.toDate();
                      } else {
                        return "Date error";
                      }
                      DateTime now = DateTime.now();
                      int daysLeft = eventDate.difference(now).inDays;
                      if (daysLeft < 0) return "Past event";
                      if (daysLeft == 0) return "Today";
                      if (daysLeft == 1) return "1 day left";
                      return "$daysLeft days left";
                    } catch (e) {
                      return "Date error";
                    }
                  }

                  // Extract communityId from document reference path
                  // collectionGroup path format: communities/{communityId}/events/{eventId}
                  final docRef = filteredDocs[index].reference;
                  final pathParts = docRef.path.split('/');
                  String? communityId;
                  if (pathParts.length >= 4 && pathParts[0] == 'communities' && pathParts[2] == 'events') {
                    communityId = pathParts[1];
                  }
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(
                            eventId: filteredDocs[index].id,
                            currentUserId: currentUserId,
                            communityId: communityId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: eventColors[index % eventColors.length],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              event['title'] ?? 'N/A',
                              style: const TextStyle(fontSize: 22, color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            // Date with days left circle
                            Row(
                              children: [
                                Text(
                                  event['date'] is Timestamp
                                      ? (event['date'] as Timestamp)
                                          .toDate()
                                          .toString()
                                          .split(' ')[0]
                                      : (event['date'] ?? 'N/A'),
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    getDaysLeft(event['date']),
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Location
                            Text(
                              event['location'] ?? 'N/A',
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            // Participants and Upvotes
                            Row(
                              children: [
                                // Participants
                                Row(
                                  children: [
                                    const Icon(Icons.face_2, size: 18, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      " ${(event['registered'] ?? []).length} Participant${(event['registered'] ?? []).length <= 1 ? '' : 's'}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                // Upvotes
                                Row(
                                  children: [
                                    const Icon(Icons.whatshot, size: 18, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${(event['upvotes'] ?? []).length}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _EventBottomBar(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        onPlus: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
        },
      ),
    );
  }
}

class _EventBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onPlus;
  const _EventBottomBar({required this.currentIndex, required this.onChanged, required this.onPlus});

  Color _color(int i) => currentIndex == i ? const Color(0xFF4C1D95) : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onChanged(0),
            icon: Icon(Icons.home_rounded, color: _color(0)),
          ),
          IconButton(
            onPressed: () => onChanged(1),
            icon: Icon(Icons.explore_outlined, color: _color(1)),
          ),
          GestureDetector(
            onTap: onPlus,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4C1D95),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(3),
            icon: Icon(Icons.group_outlined, color: _color(3)),
          ),
          IconButton(
            onPressed: () => onChanged(4),
            icon: Icon(Icons.person_outline, color: _color(4)),
          ),
        ],
      ),
    );
  }
}
