import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_bottom_navbar.dart';
import 'event_detail_page.dart';
import 'create_event_page.dart';

class CommunityThreadPage extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String coverColorHex;
  
  const CommunityThreadPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.coverColorHex,
  });

  @override
  State<CommunityThreadPage> createState() => _CommunityThreadPageState();
}

class _CommunityThreadPageState extends State<CommunityThreadPage> {
  int _tab = 0;
  final Set<String> _likedThreadIds = <String>{};

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {}
    }
  }

  Future<void> _toggleLike(String threadId, int currentLikes) async {
    await _ensureSignedIn();
    final doc = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('threads')
        .doc(threadId);
    final already = _likedThreadIds.contains(threadId);
    setState(() {
      if (already) {
        _likedThreadIds.remove(threadId);
      } else {
        _likedThreadIds.add(threadId);
      }
    });
    try {
      await doc.update({
        'likesCount': FieldValue.increment(already ? -1 : 1),
      });
    } catch (_) {/* ignore */}
  }

  Future<void> _openComments(String threadId) async {
    final TextEditingController controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final commentsRef = FirebaseFirestore.instance
                .collection('communities')
                .doc(widget.communityId)
                .collection('threads')
                .doc(threadId)
                .collection('comments')
                .orderBy('createdAt', descending: true);
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: commentsRef.snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(child: Text('Cannot load comments (permission/rules).'));
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snap.data!.docs;
                        if (items.isEmpty) {
                          return const Center(child: Text('Be the first to comment'));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final c = items[i].data();
                            return ListTile(
                              leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
                              title: Text(c['authorName']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(c['text']?.toString() ?? ''),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              filled: true,
                              fillColor: Color(0xFFF5F6FF),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            controller.clear();
                            await _ensureSignedIn();
                            final comments = FirebaseFirestore.instance
                                .collection('communities')
                                .doc(widget.communityId)
                                .collection('threads')
                                .doc(threadId)
                                .collection('comments');
                            await comments.add({
                              'text': text,
                              'authorName': 'Anonymous',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            await FirebaseFirestore.instance
                                .collection('communities')
                                .doc(widget.communityId)
                                .collection('threads')
                                .doc(threadId)
                                .update({'commentsCount': FieldValue.increment(1)});
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createThread() async {
    await _ensureSignedIn();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Create Thread', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thread title',
                  filled: true,
                  fillColor: Color(0xFFF5F6FF),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  filled: true,
                  fillColor: Color(0xFFF5F6FF),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Post'),
                ),
              )
            ],
          ),
        );
      },
    );
    if (created != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-001';
    final authorName = FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
    try {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('threads')
          .add({
        'title': titleCtrl.text.trim(),
        'text': contentCtrl.text.trim(),
        'authorUid': uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create thread: $e')),
      );
    }
  }

  Future<void> _createEvent() async {
    await _ensureSignedIn();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventPage(communityId: widget.communityId),
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
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/cloud_logo.png', width: 42, height: 34),
                    const CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.communityName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const Icon(Icons.search, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    child: Text(
                      'Threads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _tab == 0 ? FontWeight.w800 : FontWeight.w700,
                        color: _tab == 0 ? Colors.black : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    child: Text(
                      'Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _tab == 1 ? FontWeight.w800 : FontWeight.w700,
                        color: _tab == 1 ? Colors.black : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _tab == 0
                    ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('communities')
                            .doc(widget.communityId)
                            .collection('threads')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(child: Text('No threads yet'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final t = docs[index].data();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                (t['authorName'] ?? 'User').toString(),
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            Text(_timeAgoFrom(t['createdAt'])),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if ((t['title'] ?? '').toString().isNotEmpty) ...[
                                          Text(
                                            (t['title'] ?? '').toString(),
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        Text((t['text'] ?? '').toString()),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _toggleLike(docs[index].id, t['likesCount'] ?? 0),
                                              borderRadius: BorderRadius.circular(20),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Row(children: [
                                                  Icon(
                                                    _likedThreadIds.contains(docs[index].id) ? Icons.favorite : Icons.favorite_border,
                                                    size: 18,
                                                    color: _likedThreadIds.contains(docs[index].id) ? Colors.black : null,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text('${t['likesCount'] ?? 0}'),
                                                ]),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _openComments(docs[index].id),
                                              borderRadius: BorderRadius.circular(20),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Row(children: [
                                                  const Icon(Icons.chat_bubble_outline, size: 18),
                                                  const SizedBox(width: 6),
                                                  Text('${t['commentsCount'] ?? 0}'),
                                                ]),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('communities')
                            .doc(widget.communityId)
                            .collection('events')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(child: Text('No events yet'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final event = docs[index].data();
                              final colors = <Color>[
                                const Color.fromARGB(255, 172, 199, 219),
                                const Color.fromARGB(255, 145, 203, 145),
                                const Color.fromARGB(255, 170, 111, 184),
                                const Color(0xFFFFE4B5),
                                const Color.fromARGB(255, 228, 145, 97),
                              ];
                              
                              String getDaysLeft(dynamic dateValue) {
                                try {
                                  DateTime eventDate;
                                  if (dateValue is String) {
                                    final parts = dateValue.split('-');
                                    eventDate = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                  } else if (dateValue is Timestamp) {
                                    eventDate = dateValue.toDate();
                                  } else {
                                    return 'Date error';
                                  }
                                  final daysLeft = eventDate.difference(DateTime.now()).inDays;
                                  if (daysLeft < 0) return 'Past event';
                                  if (daysLeft == 0) return 'Today';
                                  if (daysLeft == 1) return '1 day left';
                                  return '$daysLeft days left';
                                } catch (_) {
                                  return 'Date error';
                                }
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailPage(
                                        eventId: docs[index].id,
                                        currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                        communityId: widget.communityId,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['title'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 22, color: Colors.black),
                                        ),
                                        const SizedBox(height: 12),
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
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        Text(
                                          event['location'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 16, color: Colors.black),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.face_2, size: 18, color: Colors.black),
                                                const SizedBox(width: 4),
                                                Text(
                                                  ' ${(event['registered'] ?? []).length} Participant${(event['registered'] ?? []).length == 1 ? '' : 's'}',
                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 20),
                                            Row(
                                              children: [
                                                const Icon(Icons.whatshot, size: 18, color: Colors.black),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${(event['upvotes'] ?? []).length}',
                                                  style: const TextStyle(fontSize: 16, color: Colors.black),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tab == 0 ? _createThread : _createEvent,
        backgroundColor: const Color(0xFF4C1D95),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onChanged: (i) {
          if (i == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        onPlus: () {
          if (_tab == 1) {
            _createEvent();
          } else {
            _createThread();
          }
        },
      ),
    );
  }
}

String _timeAgoFrom(dynamic ts) {
  try {
    DateTime d;
    if (ts is Timestamp) d = ts.toDate();
    else if (ts is String) d = DateTime.tryParse(ts) ?? DateTime.now();
    else d = DateTime.now();
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  } catch (_) {
    return '';
  }
}
