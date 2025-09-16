import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_page.dart';
import 'dart:convert';
import 'event_list_page.dart';

class PostItem {
  final String postId;
  final String authorId;
  final String authorName;
  final String avatarUrl;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final String? title;
  final String? communityId;
  final List<String> mediaUrls;

  PostItem({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.title,
    this.communityId,
    this.mediaUrls = const [],
  });

  static PostItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    int likes = 0;
    final likesRaw = data['likesCount'] ?? data['likes'];
    if (likesRaw is int) likes = likesRaw;
    if (likesRaw is String) likes = int.tryParse(likesRaw) ?? 0;

    int comments = 0;
    final commentsRaw = data['commentsCount'] ?? data['comments'];
    if (commentsRaw is int) comments = commentsRaw;
    if (commentsRaw is String) comments = int.tryParse(commentsRaw) ?? 0;

    return PostItem(
      postId: data['postId']?.toString() ?? doc.id,
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Unknown',
      avatarUrl: data['avatarUrl']?.toString() ?? 'https://i.pravatar.cc/150?img=1',
      content: data['content']?.toString() ?? '',
      createdAt: createdAt,
      likes: likes,
      comments: comments,
      title: data['title']?.toString(),
      communityId: data['communityId']?.toString(),
      mediaUrls: (data['mediaUrls'] is List)
          ? (data['mediaUrls'] as List).map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}

class CommunityHome extends StatefulWidget {
  const CommunityHome({super.key});

  @override
  State<CommunityHome> createState() => _CommunityHomeState();
}

class _CommunityHomeState extends State<CommunityHome> {
  int _currentIndex = 0;
  int _tabIndex = 0; // 0 = Threads, 1 = Event
  final PageController _pageController = PageController(initialPage: 0);

  Future<void> _openComposer() async {
    await Navigator.of(context).pushNamed('/createPost');
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: const [
                            Text('Explore',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                )),
                            SizedBox(width: 8),
                            Icon(Icons.search, size: 22),
                          ]),
                          Row(children: const [
                            Icon(Icons.emoji_emotions_outlined),
                            SizedBox(width: 12),
                            Icon(Icons.notifications_none),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _pillButton('Make Friends'),
                          const SizedBox(width: 12),
                          _pillButton('Join Community'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Friendzy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 8),
                      // Tabs under Friendzy: Threads | Event (swipeable like X)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _tabIndex = 0);
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Text(
                              'Threads',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _tabIndex == 0 ? FontWeight.w800 : FontWeight.w700,
                                color: _tabIndex == 0 ? Colors.black : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                          GestureDetector(
                            onTap: () {
                              setState(() => _tabIndex = 1);
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Text(
                              'Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _tabIndex == 1 ? FontWeight.w800 : FontWeight.w700,
                                color: _tabIndex == 1 ? Colors.black : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _tabIndex = i),
                  children: [
                    // Page 0: Threads (posts)
                    ThreadsFeed(),
                    // Page 1: Event list page with unified background
                    EventListEmbedded(),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        onPlus: _openComposer,
      ),
    );
  }

  Widget _pillButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black38),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostItem post;
  const _PostCard({required this.post});

  String _timeAgo() {
    final diff = DateTime.now().difference(post.createdAt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(backgroundImage: NetworkImage(post.avatarUrl), radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
                Text(_timeAgo(), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (post.title != null && post.title!.isNotEmpty) ...[
              Text(post.title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
            ],
            Text(post.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            _mediaPreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 18),
                const SizedBox(width: 6),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 6),
                Text('${post.comments}'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview() {
    if (post.mediaUrls.isEmpty) return const SizedBox.shrink();
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(post.mediaUrls.first),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: post.mediaUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(post.mediaUrls[i]),
            width: 220,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 220,
              height: 160,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onPlus;
  const _BottomBar({required this.currentIndex, required this.onChanged, required this.onPlus});

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


class ThreadsFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load posts'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }
        final posts = docs.map((d) => PostItem.fromDoc(d)).toList();
        return ListView.builder(
          padding: const EdgeInsets.only(top: 0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _PostCard(post: post),
            );
          },
        );
      },
    );
  }
}

class EventListEmbedded extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          padding: const EdgeInsets.only(top: 0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final event = data as Map<String, dynamic>;
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
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }
}
