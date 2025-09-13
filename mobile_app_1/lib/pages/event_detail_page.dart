// lib/pages/event_detail_page.dart

import 'package:flutter/material.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String currentUserId;

  EventDetailPage({required this.event, required this.currentUserId});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> event;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    event = widget.event;
    // ตรวจสอบว่ามี comments array หรือไม่ ถ้าไม่มีให้สร้างใหม่
    if (event['comments'] == null) {
      event['comments'] = [];
    }
  }

  void toggleArrayField(String fieldName) {
    setState(() {
      List array = event[fieldName];
      if (array.contains(widget.currentUserId)) {
        array.remove(widget.currentUserId);
      } else {
        array.add(widget.currentUserId);
      }
    });
  }

  void addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        event['comments'].add({
          'id': 'comment_${DateTime.now().millisecondsSinceEpoch}',
          'userId': widget.currentUserId,
          'userName': 'You', // ในระบบจริงจะดึงจาก user profile
          'text': _commentController.text.trim(),
          'timestamp': DateTime.now().toString().substring(0, 19),
          'profileImage':
              'https://via.placeholder.com/40x40.png?text=U', // Mock profile image
        });
        _commentController.clear();
      });
    }
  }

  String formatDate(String timestamp) {
    try {
      DateTime date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return timestamp;
    }
  }

  String formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  void deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  event['comments'].removeWhere(
                    (comment) => comment['id'] == commentId,
                  );
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void reportComment(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportDialog(commentId: commentId);
      },
    );
  }

  void showEventReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventReportDialog(eventId: event['id']);
      },
    );
  }

  void showRegisterConfirmation() {
    bool isRegistered = event['registered'].contains(widget.currentUserId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            isRegistered ? 'Unregister from Event' : 'Register for Event',
          ),
          content: Text(
            isRegistered
                ? 'Are you sure you want to unregister from this event?'
                : 'Are you sure you want to register for this event?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                toggleArrayField('registered');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRegistered
                          ? 'Unregistered successfully'
                          : 'Registered successfully',
                    ),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text(
                isRegistered ? 'Unregister' : 'Register',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void showCommentMenu(String commentId, String userId, BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(-10, 0)),
        button.localToGlobal(button.size.bottomRight(Offset(-10, 0))),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        if (userId == widget.currentUserId)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Delete Comment'),
              ],
            ),
          )
        else
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.report, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text('Report Comment'),
              ],
            ),
          ),
      ],
    ).then((String? value) {
      if (value == 'delete') {
        deleteComment(commentId);
      } else if (value == 'report') {
        reportComment(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool liked = event['likes'].contains(widget.currentUserId);
    bool favorited = event['favorites'].contains(widget.currentUserId);
    bool registered = event['registered'].contains(widget.currentUserId);
    bool upvoted = event['upvotes'].contains(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Event'), 
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.report, color: Colors.black),
            onPressed: () => showEventReportDialog(),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Held by
                Text("Held by ${event['heldBy']}", style: TextStyle(fontSize: 14, color: Colors.black)),
                SizedBox(height: 2),
                // Event title
                Text(event['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                // Description
                Text(event['description'], style: TextStyle(fontSize: 16, height: 1.5)),
                SizedBox(height: 20),
                // Event image with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    event['imageUrl'], 
                    width: double.infinity, 
                    height: 250, 
                    fit: BoxFit.cover
                  ),
                ),
                SizedBox(height: 20),
                // Event details
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text("Date: ${event['date']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text("Time: ${event['time']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text("Location: ${event['location']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? const Color.fromARGB(255, 225, 82, 168) : Colors.black,
                      ),
                      onPressed: () => toggleArrayField('likes'),
                    ),
                    Text(formatNumber(event['likes'].length)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        favorited ? Icons.star : Icons.star_border,
                        color: favorited ? const Color.fromARGB(255, 235, 218, 64) : Colors.black,
                      ),
                      onPressed: () => toggleArrayField('favorites'),
                    ),
                    Text(formatNumber(event['favorites'].length)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        registered
                            ? Icons.how_to_reg
                            : Icons.how_to_reg_outlined,
                        color: Colors.black,
                      ),
                      onPressed: () => showRegisterConfirmation(),
                    ),
                    Text(formatNumber(event['registered'].length)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        upvoted ? Icons.whatshot : Icons.whatshot,
                        color: upvoted ? const Color.fromARGB(255, 230, 20, 20) : Colors.black,
                      ),
                      onPressed: () => toggleArrayField('upvotes'),
                    ),
                    Text(formatNumber(event['upvotes'].length)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // ส่วนคอมเมนต์
            Divider(),
            Text(
              'Comments (${event['comments'].length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // ฟอร์มเขียนคอมเมนต์
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: addComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            // รายการคอมเมนต์
            ...event['comments'].asMap().entries.map<Widget>((entry) {
              int index = entry.key;
              Map<String, dynamic> comment = entry.value;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // รูปโปรไฟล์
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            comment['profileImage'] ??
                                'https://via.placeholder.com/40x40.png?text=U',
                          ),
                        ),
                        SizedBox(width: 12),
                        // เนื้อหาคอมเมนต์
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment['userName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    formatDate(comment['timestamp']),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Spacer(),
                                  Builder(
                                    builder: (context) => IconButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                      onPressed: () => showCommentMenu(
                                        comment['id'],
                                        comment['userId'],
                                        context,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                comment['text'],
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // เส้นแบ่ง (ยกเว้นคอมเมนต์สุดท้าย)
                  if (index < event['comments'].length - 1)
                    Divider(height: 1, color: Colors.grey[300]),
                ],
              );
            }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  final String commentId;

  ReportDialog({required this.commentId});

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? selectedReportType;
  final TextEditingController _detailsController = TextEditingController();

  final List<Map<String, String>> reportTypes = [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'inappropriate', 'label': 'Inappropriate Content'},
    {'value': 'harassment', 'label': 'Harassment'},
    {'value': 'hate_speech', 'label': 'Hate Speech'},
    {'value': 'false_info', 'label': 'False Information'},
    {'value': 'violence', 'label': 'Violence'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Report Comment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select report type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReportType,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: Text('Select report type'),
              items: reportTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedReportType = newValue;
                });
              },
            ),
            SizedBox(height: 15),
            Text(
              'Additional details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                hintText: 'Enter additional details (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedReportType != null ? _submitReport : null,
          child: Text('Submit Report'),
        ),
      ],
    );
  }

  void _submitReport() {
    if (selectedReportType != null) {
      // ในระบบจริงจะส่งข้อมูลไปยัง backend
      String reportTypeLabel = reportTypes.firstWhere(
        (type) => type['value'] == selectedReportType,
      )['label']!;

      Navigator.pop(context);

      // แสดง dialog แทน SnackBar
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Report Submitted'),
            content: Text('Your report has been submitted successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }
}

class EventReportDialog extends StatefulWidget {
  final String eventId;

  EventReportDialog({required this.eventId});

  @override
  _EventReportDialogState createState() => _EventReportDialogState();
}

class _EventReportDialogState extends State<EventReportDialog> {
  String? selectedReportType;
  final TextEditingController _detailsController = TextEditingController();
  
  final List<Map<String, String>> reportTypes = [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'inappropriate', 'label': 'Inappropriate Content'},
    {'value': 'harassment', 'label': 'Harassment'},
    {'value': 'hate_speech', 'label': 'Hate Speech'},
    {'value': 'false_info', 'label': 'False Information'},
    {'value': 'violence', 'label': 'Violence'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Report Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please select report type:', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReportType,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Select report type'),
              items: reportTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedReportType = newValue;
                });
              },
            ),
            SizedBox(height: 15),
            Text('Additional details:', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                hintText: 'Enter additional details (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedReportType != null ? _submitReport : null,
          child: Text('Submit Report'),
        ),
      ],
    );
  }

  void _submitReport() {
    if (selectedReportType != null) {
      // ในระบบจริงจะส่งข้อมูลไปยัง backend
      String reportTypeLabel = reportTypes
          .firstWhere((type) => type['value'] == selectedReportType)['label']!;
      
      Navigator.pop(context);
      
      // แสดง dialog แทน SnackBar
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Report Submitted'),
            content: Text('Your event report has been submitted successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }
}
