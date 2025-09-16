// lib/screens/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_detail_page.dart';

class EventListPage extends StatelessWidget {
  final String currentUserId = "uid1"; // Dummy user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ), // เพิ่ม AppBar
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
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
          return Container(
            color: Colors.transparent,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final event = docs[index].data() as Map<String, dynamic>;
                // สีพื้นหลังสำหรับแต่ละ event
                List<Color> eventColors = [
                  Color.fromARGB(255, 172, 199, 219),
                  Color.fromARGB(255, 145, 203, 145),
                  Color.fromARGB(255, 170, 111, 184),
                  Color(0xFFFFE4B5),
                  Color.fromARGB(255, 228, 145, 97),
                ];

                // คำนวณจำนวนวันที่เหลือ
                String getDaysLeft(dynamic dateValue) {
                  try {
                    DateTime eventDate;
                    if (dateValue is String) {
                      // กรณีเก่า: "18-08-2025"
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
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                                  ? (event['date'] as Timestamp).toDate().toString().split(' ')[0]
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
