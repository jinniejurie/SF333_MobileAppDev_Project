// lib/screens/event_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final String currentUserId;

  EventDetailPage({required this.eventId, required this.currentUserId});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> event;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  String formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String formatDateDynamic(dynamic value) {
    if (value is Timestamp) {
      DateTime date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (value is String) {
      try {
        DateTime date = DateTime.parse(
          value,
        );
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return value;
      }
    } else {
      return '';
    }
  }

  String _formatTime12(DateTime date) {
    int hour24 = date.hour;
    final String period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm$period';
  }

  String formatTime12Dynamic(dynamic value) {
    try {
      if (value is Timestamp) {
        return _formatTime12(value.toDate());
      } else if (value is String) {
        final DateTime dt = DateTime.parse(value);
        return _formatTime12(dt);
      }
    } catch (_) {}
    return '';
  }

  String buildTimeRange(Map<String, dynamic> evt) {
    final dynamic start = evt['date'] ?? evt['startDate'] ?? evt['start_time'];
    final dynamic end = evt['endDate'] ?? evt['end_time'];
    final String startStr = formatTime12Dynamic(start);
    if (startStr.isEmpty) return 'N/A';
    final String endStr = formatTime12Dynamic(end);
    return endStr.isEmpty ? startStr : '$startStr - $endStr';
  }

  Future<void> toggleArrayField(String fieldName) async {
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to perform this action.')),
      );
      return;
    }
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId);
    try {
      final List<dynamic> array = List.from(event[fieldName] ?? []);
      final bool hasUser = array.contains(widget.currentUserId);

      if (hasUser) {
        await docRef.update({
          fieldName: FieldValue.arrayRemove([widget.currentUserId])
        });
        setState(() {
          array.remove(widget.currentUserId);
          event[fieldName] = array;
        });
      } else {
        await docRef.update({
          fieldName: FieldValue.arrayUnion([widget.currentUserId])
        });
        setState(() {
          array.add(widget.currentUserId);
          event[fieldName] = array;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> addComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    final Map<String, dynamic> newComment = {
      'id': 'comment_${DateTime.now().microsecondsSinceEpoch}',
      'userId': widget.currentUserId,
      'userName': 'You',
      'text': text,
      'timestamp': Timestamp.now(),
      'profileImage': 'https://via.placeholder.com/40x40.png?text=U',
      'isDeleted': false,
    };

    // เคลียร์ข้อความทันที ให้ผู้ใช้พิมพ์ต่อได้เลย
    _commentController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({'comments': FieldValue.arrayUnion([newComment])});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add comment failed: $e')),
      );
    }
  }

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
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
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final List comments = List.from(event['comments'] ?? []);
                  final int idx = comments.indexWhere((c) => c['id'] == commentId);
                  if (idx != -1) {
                    final Map<String, dynamic> original = Map<String, dynamic>.from(comments[idx]);
                    if (original['userId'] != widget.currentUserId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You can only delete your own comment.')),
                      );
                      return;
                    }
                    final Map<String, dynamic> softDeleted = Map<String, dynamic>.from(original);
                    softDeleted['isDeleted'] = true;

                    final docRef = FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId);

                    // แทนที่จะลบถาวร: ลบอันเดิม แล้วเพิ่มเวอร์ชัน isDeleted:true
                    await docRef.update({
                      'comments': FieldValue.arrayRemove([original])
                    });
                    await docRef.update({
                      'comments': FieldValue.arrayUnion([softDeleted])
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete comment failed: $e')),
                  );
                }
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
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report this event.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventReportDialog(eventId: widget.eventId, reporterId: widget.currentUserId);
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Event not found or error.')),
          );
        }
        event = snapshot.data!.data() as Map<String, dynamic>;
        // กัน null สำหรับฟิลด์สำคัญ
        event['comments'] ??= [];
        event['likes'] ??= [];
        event['favorites'] ??= [];
        event['registered'] ??= [];
        event['upvotes'] ??= [];

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
                    Text(
                      "Held by ${event['organizer']}",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    SizedBox(height: 2),
                    // Event title
                    Text(
                      event['title'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Description
                    Text(
                      event['description'],
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 20),
                    // Event image with rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (() {
                        final String imageUrl = (event['imageUrl'] ?? '').toString().trim();
                        if (imageUrl.isEmpty) {
                          return Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, color: Colors.grey[700]),
                                SizedBox(height: 8),
                                Text('No imageUrl', style: TextStyle(color: Colors.grey[700])),
                              ],
                            ),
                          );
                        }
                        // log URL เพื่อดีบัก
                        // ignore: avoid_print
                        print('Loading image: ' + imageUrl);
                        return Image.network(
                          imageUrl,
                          key: ValueKey(imageUrl),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // ignore: avoid_print
                            print('Image load error for URL: ' + imageUrl + ' -> ' + error.toString());
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey[700]),
                                  SizedBox(height: 6),
                                  Text('Failed to load image', style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                            );
                          },
                        );
                      })(),
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
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Date:${formatDate(event['date'])}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Time: ${buildTimeRange(event)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Location: ${event['location']}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Going pill under location box (full width)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showRegisterConfirmation(),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${event['registered'].length}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(registered ? Icons.how_to_reg : Icons.how_to_reg_outlined, size: 16, color: Colors.white),
                                      SizedBox(width: 6),
                                      const Text(
                                        'Going',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Like
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked
                                    ? const Color.fromARGB(255, 225, 82, 168)
                                    : Colors.black,
                              ),
                              onPressed: () => toggleArrayField('likes'),
                            ),
                            Builder(builder: (context) {
                              final int likesCount = event['likes'].length;
                              final String label = likesCount == 1 ? 'Like' : 'Likes';
                              return Text('${formatNumber(likesCount)} $label');
                            }),
                          ],
                        ),
                        // Interested (favorites) next to Like
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                favorited ? Icons.star : Icons.star_border,
                                color: favorited ? const Color.fromARGB(255, 235, 218, 64) : Colors.black,
                              ),
                              onPressed: () => toggleArrayField('favorites'),
                            ),
                            Text('${formatNumber(event['favorites'].length)} Interested'),
                          ],
                        ),
                        // Upvote
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                upvoted ? Icons.whatshot : Icons.whatshot,
                                color: upvoted
                                    ? const Color.fromARGB(255, 230, 20, 20)
                                    : Colors.black,
                              ),
                              onPressed: () => toggleArrayField('upvotes'),
                            ),
                            Builder(builder: (context) {
                              final int upvotesCount = event['upvotes'].length;
                              final String label = upvotesCount == 1 ? 'Upvote' : 'Upvotes';
                              return Text('${formatNumber(upvotesCount)} $label');
                            }),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // ส่วนคอมเมนต์
                    Divider(),
                    Text(
                      'Comments (${event['comments'].length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    // ฟอร์มเขียนคอมเมนต์
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _commentFocusNode,
                            controller: _commentController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => addComment(),
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
                    ...event['comments']
                        .where((c) => (c is Map && (c['isDeleted'] != true)))
                        .toList()
                        .asMap()
                        .entries
                        .map<Widget>((entry) {
                      int index = entry.key;
                      Map<String, dynamic> comment = Map<String, dynamic>.from(entry.value as Map);

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            formatDateDynamic(comment['timestamp']),
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
                          if (index < event['comments'].where((c) => (c is Map && (c['isDeleted'] != true))).length - 1)
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
      },
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
              dropdownColor: Colors.white,
              style: TextStyle(color: Colors.black),
              iconEnabledColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: Text('Select report type', style: TextStyle(color: Colors.black54)),
              items: reportTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!, style: TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: selectedReportType != null ? (String? newValue) {
                      setState(() {
                        selectedReportType = newValue;
                      });
                    } : null,
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
  final String reporterId;

  EventReportDialog({required this.eventId, required this.reporterId});

  @override
  _EventReportDialogState createState() => _EventReportDialogState();
}

class _EventReportDialogState extends State<EventReportDialog> {
  String? selectedReportType;
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;

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
            Text(
              'Please select report type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReportType,
              dropdownColor: Colors.white,
              style: TextStyle(color: Colors.black),
              iconEnabledColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: Text('Select report type', style: TextStyle(color: Colors.black54)),
              items: reportTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!, style: TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: _submitting
                  ? null
                  : (String? newValue) {
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
              enabled: !_submitting,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (selectedReportType != null && !_submitting) ? _submitReport : null,
          child: _submitting
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Submit Report'),
        ),
      ],
    );
  }

  void _submitReport() async {
    if (selectedReportType == null || _submitting) return;
    setState(() { _submitting = true; });
    final reportDoc = {
      'eventId': widget.eventId,
      'reporterId': widget.reporterId,
      'type': selectedReportType,
      'details': _detailsController.text.trim(),
      'createdAt': Timestamp.now(),
      'status': 'open',
    };
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('reports')
          .add(reportDoc);
      if (mounted) Navigator.pop(context);
      if (mounted) {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report failed: $e')),
      );
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }
}
