// lib/pages/event_list_page.dart
import 'package:flutter/material.dart';
import '../data/mock_events.dart';
import 'event_detail_page.dart';

class EventListPage extends StatelessWidget {
  final String currentUserId = "uid1"; // Dummy user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // พื้นหลังของแอป สีขาวเดียวกับหน้า detail
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
          itemCount: mockEvents.length,
          itemBuilder: (context, index) {
            final event = mockEvents[index];
            
            // สีพื้นหลังสำหรับแต่ละ event
            List<Color> eventColors = [
              Color.fromARGB(255, 172, 199, 219), // ม่วงอ่อน
              Color.fromARGB(255, 145, 203, 145), // เขียวอ่อน
              Color.fromARGB(255, 170, 111, 184), // ฟ้าอ่อน
              Color(0xFFFFE4B5), // ส้มอ่อน
              Color.fromARGB(255, 228, 145, 97), // ม่วงอ่อนกว่า
            ];

            // คำนวณจำนวนวันที่เหลือ
            String getDaysLeft(String dateStr) {
              try {
                // แปลงวันที่จากรูปแบบ "18-08-2025" เป็น DateTime
                List<String> parts = dateStr.split('-');
                int day = int.parse(parts[0]);
                int month = int.parse(parts[1]);
                int year = int.parse(parts[2]);
                
                DateTime eventDate = DateTime(year, month, day);
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
                      event: event,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: eventColors[index % eventColors.length],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event['title'] ?? 'N/A',
                      style: TextStyle(fontSize: 22, color: Colors.black),
                    ),
                    SizedBox(height: 12),

                    // Date with days left circle
                    Row(
                      children: [
                        Text(
                          event['date'] ?? 'N/A',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getDaysLeft(event['date'] ?? ''),
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Location
                    Text(
                      event['location'] ?? 'N/A',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(height: 12),

                    // Participants and Upvotes
                    Row(
                      children: [
                        // Participants
                        Row(
                          children: [
                            Icon(Icons.face_2, size: 18, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              " ${(event['registered'] ?? []).length} Participant${(event['registered'] ?? []).length == 1 ? '' : 's'}",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        // Upvotes
                        Row(
                          children: [
                            Icon(Icons.whatshot, size: 18, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              "${(event['upvotes'] ?? []).length}",
                              style: TextStyle(fontSize: 16, color: Colors.black),
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
      ),
    );
  }
}
