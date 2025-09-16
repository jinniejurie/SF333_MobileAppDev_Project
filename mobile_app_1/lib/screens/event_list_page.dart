// lib/screens/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';
import 'community_home.dart';
import 'create_post_page.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No events found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final event = docs[index].data() as Map<String, dynamic>;
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

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(
                            eventId: docs[index].id,
                            currentUserId: currentUserId,
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
                                      " ${(event['registered'] ?? []).length} Participant${(event['registered'] ?? []).length == 1 ? '' : 's'}",
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
      bottomNavigationBar: _EventBottomBar(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        onPlus: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
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
