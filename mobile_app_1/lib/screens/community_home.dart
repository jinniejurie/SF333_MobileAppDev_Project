import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'swipe.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'event_detail_page.dart';
import 'community_discover_page.dart';
import 'community_thread_page.dart';
import '../widgets/app_bottom_navbar.dart';
import '../widgets/accessible_container.dart';
import '../providers/accessibility_provider.dart';
import 'create_event_page.dart';

class PostItem {
  final String postId;
  final String uid;
  final String authorName;
  final String avatarUrl;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final String? title;
  final String? communityId;
  final List<String> mediaUrls;
  final List<String> tags;

  PostItem({
    required this.postId,
    required this.uid,
    required this.authorName,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.title,
    this.communityId,
    this.mediaUrls = const [],
    this.tags = const [],
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
      uid: data['uid']?.toString() ?? data['authorId']?.toString() ?? '',
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
      tags: (data['tags'] is List)
          ? (data['tags'] as List).map((e) => e.toString()).toList()
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
  final Set<String> _likedPostIds = <String>{};
  String _searchQuery = '';
  bool _isSearching = false;
  
  String get _pageTitle => _currentIndex == 0 ? 'Explore' : 'Events';

  Future<void> _openComposer() async {
    if (_currentIndex == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CreateEventPage()),
      );
    } else {
      await Navigator.of(context).pushNamed('/createPost');
    }
  }

  Future<void> _toggleLike(PostItem post) async {
    final doc = FirebaseFirestore.instance.collection('posts').doc(post.postId);
    final already = _likedPostIds.contains(post.postId);
    setState(() {
      if (already) {
        _likedPostIds.remove(post.postId);
      } else {
        _likedPostIds.add(post.postId);
      }
    });
    try {
      // In a real app, replace with the authenticated user's uid
      const String currentUid = 'demo-user-001';
      await doc.update({
        'likesCount': FieldValue.increment(already ? -1 : 1),
        'likes': already
            ? FieldValue.arrayRemove([currentUid])
            : FieldValue.arrayUnion([currentUid]),
      });
    } catch (_) {/* ignore */}
  }

  Future<void> _openComments(PostItem post) async {
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
                .collection('posts')
                .doc(post.postId)
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
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
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
                            final comments = FirebaseFirestore.instance
                                .collection('posts')
                                .doc(post.postId)
                                .collection('comments');
                            await comments.add({
                              'text': text,
                              'authorName': 'Anonymous',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(post.postId)
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
      }
    });
  }

  Future<void> _openTagSearch() async {
    final controller = TextEditingController();
    List<String> suggestions = [];
    try {
      final s = await FirebaseFirestore.instance.collection('tags').limit(20).get();
      suggestions = s.docs.map((d) => d.id).toList();
    } catch (_) {
      // fallback: sample from recent posts
      final s = await FirebaseFirestore.instance.collection('posts').limit(50).get();
      final set = <String>{};
      for (final d in s.docs) {
        final data = d.data();
        if (data['tags'] is List) {
          for (final t in (data['tags'] as List)) {
            if (t is String && t.isNotEmpty) set.add(t);
          }
        }
      }
      suggestions = set.take(20).toList();
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = '';
        List<String> filtered = suggestions;
        return StatefulBuilder(builder: (context, setSt) {
          void onChanged(String v) {
            query = v.trim();
            setSt(() {
              filtered = suggestions
                  .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            });
          }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                const Text('Search tags', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type a tag...',
                      filled: true,
                      fillColor: Color(0xFFF5F6FF),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: filtered
                        .map((t) => ListTile(
                              leading: const Icon(Icons.tag),
                              title: Text('#$t'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => TagFeedPage(tag: t)),
                                );
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AccessibleContainer(
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
                      // Top cloud/logo and actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/cloud_logo.png', width: 42, height: 34),
                          Row(children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profileSettings');
                              },
                              child: const CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16)),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                // TODO: Navigate to notifications page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications feature coming soon!')),
                                );
                              },
                              icon: const Icon(Icons.notifications, size: 26),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Semantics(
                          header: true,
                          child: Expanded(
                            child: Text('Explore',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleSearch,
                          child: const Icon(Icons.search, size: 22),
                        ),
                      ]),
                      if (_isSearching) ...[
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search posts...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF5F6FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 400;
                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CardSwipe()),
                                      );
                                    },
                                    child: _pillButton('Make Friends'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CommunityDiscoverPage()),
                                      );
                                    },
                                    child: _pillButton('Join Community'),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CardSwipe()),
                                      );
                                    },
                                    child: _pillButton('Make Friends'),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CommunityDiscoverPage()),
                                      );
                                    },
                                    child: _pillButton('Join Community'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Friendzy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    final allPosts = docs.map((d) => PostItem.fromDoc(d)).toList();
                    
                    // Filter posts based on search query
                    final filteredPosts = _searchQuery.isEmpty 
                        ? allPosts 
                        : allPosts.where((post) {
                            return post.content.toLowerCase().contains(_searchQuery) ||
                                   (post.title?.toLowerCase().contains(_searchQuery) ?? false) ||
                                   post.authorName.toLowerCase().contains(_searchQuery) ||
                                   post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
                          }).toList();
                    
                    if (filteredPosts.isEmpty && _searchQuery.isNotEmpty) {
                      return const Center(
                        child: Text('No posts found matching your search'),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 0),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        final isLiked = _likedPostIds.contains(post.postId);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: _PostCard(
                            post: post,
                            onLike: _toggleLike,
                            onComment: _openComments,
                            isLiked: isLiked,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onChanged: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              // Already on home page
              break;
            case 1:
              Navigator.of(context).pushNamed('/communityDiscover');
              break;
            case 2:
              // Plus button handled by onPlus
              break;
            case 3:
              Navigator.of(context).pushNamed('/friendsScreen');
              break;
            case 4:
              Navigator.of(context).pushNamed('/chatList');
              break;
          }
        },
        onPlus: _openComposer,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _pillButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostItem post;
  final void Function(PostItem) onLike;
  final void Function(PostItem) onComment;
  final bool isLiked;
  const _PostCard({required this.post, required this.onLike, required this.onComment, this.isLiked = false});

  String _timeAgo() {
    final diff = DateTime.now().difference(post.createdAt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: accessibility.highContrastMode
                ? Border.all(color: Colors.black, width: 3)
                : null,
            boxShadow: accessibility.highContrastMode
                ? null // Remove shadows in high contrast mode
                : const [
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
                      Semantics(
                        label: 'Post author',
                        child: Text(post.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Posted ${_timeAgo()}',
                  child: Text(_timeAgo(), style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.title != null && post.title!.isNotEmpty) ...[
              Semantics(
                header: true,
                child: Text(post.title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 6),
            ],
            Semantics(
              label: 'Post content',
              child: Text(post.content, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 8),
            _mediaPreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                Semantics(
                  label: isLiked ? 'Unlike post' : 'Like post',
                  value: '${post.likes} likes',
                  button: true,
                  child: InkWell(
                    onTap: () => onLike(post),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.black : null),
                        const SizedBox(width: 6),
                        Text('${post.likes}'),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'View comments',
                  value: '${post.comments} comments',
                  button: true,
                  child: InkWell(
                    onTap: () => onComment(post),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline, size: 18),
                        const SizedBox(width: 6),
                        Text('${post.comments}'),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.tags
                    .map((t) => GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TagFeedPage(tag: t)),
                            );
                          },
                          child: Chip(
                            label: Text('#$t'),
                            backgroundColor: const Color(0xFFF5F6FF),
                            elevation: 2,
                            shadowColor: Colors.black12,
                            shape: const StadiumBorder(),
                          ),
                        ))
                    .toList(),
              ),
            ]
          ],
        ),
      ),
        );
      },
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

class TagFeedPage extends StatelessWidget {
  final String tag;
  const TagFeedPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#$tag'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('tags', arrayContains: tag)
            // Remove orderBy to avoid composite index requirement
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No posts for this tag yet'));
          }
          final posts = docs.map((d) => PostItem.fromDoc(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _PostCard(
                post: posts[index],
                onLike: (_) {},
                onComment: (_) {},
              ),
            ),
          );
        },
      ),
    );
  }
}

class CommunityDiscoverPage extends StatefulWidget {
  const CommunityDiscoverPage({super.key});

  @override
  State<CommunityDiscoverPage> createState() => _CommunityDiscoverPageState();
}

class _CommunityDiscoverPageState extends State<CommunityDiscoverPage> {
  final TextEditingController _search = TextEditingController();

  Future<void> _createCommunity() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Color selectedColor = const Color(0xFFF6B48F);
    final colors = <Color>[
      const Color(0xFFF6B48F), // orange
      const Color(0xFFB3E1F4), // blue
      const Color(0xFFF3F0B2), // yellow
      const Color(0xFFC9E6C9), // green
      const Color(0xFFD8C6F0), // purple
    ];
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
          child: StatefulBuilder(
            builder: (context, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.cloud, size: 20),
                    SizedBox(width: 8),
                    Text('Create community', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Community name',
                    filled: true,
                    fillColor: Color(0xFFF5F6FF),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    filled: true,
                    fillColor: Color(0xFFF5F6FF),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Card color', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: colors
                      .map((c) => GestureDetector(
                            onTap: () => setSt(() => selectedColor = c),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: selectedColor == c ? Colors.black : Colors.black26, width: 2),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Create'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
    if (created != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-001';
    final ownerName = FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
    final communities = FirebaseFirestore.instance.collection('communities');
    final doc = communities.doc();
    final colorHex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';
    await doc.set({
      'communityId': doc.id,
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
      'ownerName': ownerName,
      'membersCount': 1,
      'members': [uid],
      'coverColor': colorHex,
      'avatarUrl': null,
      'latestThreadAt': FieldValue.serverTimestamp(),
    });

    // Initialize threads subcollection with a welcome thread
    final threads = doc.collection('threads');
    await threads.add({
      'title': 'Welcome to ${nameCtrl.text.trim()} 👋',
      'text': 'Say hi to your new community!',
      'authorUid': uid,
      'authorName': ownerName,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
    });

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommunityThreadPage(communityId: doc.id, communityName: nameCtrl.text.trim(), coverColorHex: colorHex)),
    );
  }

  Future<void> _joinAndOpen(String communityId, String name, String colorHex) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-001';
    final ref = FirebaseFirestore.instance.collection('communities').doc(communityId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final members = (data['members'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      if (!members.contains(uid)) {
        tx.update(ref, {
          'members': FieldValue.arrayUnion([uid]),
          'membersCount': FieldValue.increment(1),
        });
      }
    });
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommunityThreadPage(communityId: communityId, communityName: name, coverColorHex: colorHex)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _createCommunity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Create your own community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              SizedBox(width: 8),
                              Icon(Icons.construction, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.search, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('communities')
                      .orderBy('membersCount', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final name = (data['name'] ?? 'Unknown').toString();
                        final desc = (data['description'] ?? '').toString();
                        final membersCount = (data['membersCount'] ?? 0) as int;
                        final colorHex = (data['coverColor'] ?? '#FFE0B2').toString();
                        final bg = _hexToColor(colorHex);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('$membersCount members', style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () => _joinAndOpen(docs[index].id, name, colorHex),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                                          ],
                                        ),
                                        child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  )
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
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onChanged: (i) {
          switch (i) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              break;
            case 1:
              // Already on community discover page
              break;
            case 2:
              // Plus button handled by onPlus
              break;
            case 3:
              Navigator.of(context).pushNamed('/friendsScreen');
              break;
            case 4:
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

Color _hexToColor(String hex) {
  try {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return const Color(0xFFFFE0B2);
  }
}

class EventListEmbedded extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collectionGroup('events').snapshots(),
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

        DateTime? _parseDate(dynamic v) {
          try {
            if (v is Timestamp) return v.toDate();
            if (v is String) {
              // Try common formats: dd-MM-yyyy, yyyy-MM-dd
              final dashParts = v.split('-');
              if (dashParts.length == 3 && dashParts[0].length <= 2) {
                return DateTime(
                  int.parse(dashParts[2]),
                  int.parse(dashParts[1]),
                  int.parse(dashParts[0]),
                );
              }
              return DateTime.tryParse(v);
            }
          } catch (_) {}
          return null;
        }

        final now = DateTime.now();
        final enriched = docs.map((d) {
          final data = d.data();
          final Map<String, dynamic> event = data;
          final List<dynamic> upArr = (event['upvotes'] ?? []) as List<dynamic>;
          final int upvoteCount = upArr.length;

          // Prefer endDate for past detection, else date
          DateTime? endDt = _parseDate(event['endDate']);
          DateTime? dateDt = _parseDate(event['date']);
          final DateTime eventEdge = endDt ?? dateDt ?? now;
          final bool isPast = eventEdge.isBefore(now);

          return {
            'doc': d,
            'data': event,
            'upvotes': upvoteCount,
            'eventDate': dateDt ?? eventEdge,
            'isPast': isPast,
          };
        }).toList();

        final upcoming = enriched.where((e) => e['isPast'] == false).toList();
        final past = enriched.where((e) => e['isPast'] == true).toList();

        // Upcoming: sort by upvotes desc, then by date asc
        upcoming.sort((a, b) {
          final int upB = b['upvotes'] as int;
          final int upA = a['upvotes'] as int;
          if (upB != upA) return upB.compareTo(upA);
          final DateTime da = a['eventDate'] as DateTime;
          final DateTime db = b['eventDate'] as DateTime;
          return da.compareTo(db);
        });

        // Past: push to bottom, optionally newest first
        past.sort((a, b) {
          final DateTime da = a['eventDate'] as DateTime;
          final DateTime db = b['eventDate'] as DateTime;
          return db.compareTo(da);
        });

        // Only show upcoming events (sorted by upvotes)
        final ordered = <Map<String, dynamic>>[...upcoming];

        return ListView.builder(
          padding: const EdgeInsets.only(top: 0),
          itemCount: ordered.length,
          itemBuilder: (context, index) {
            final d = ordered[index]['doc'] as QueryDocumentSnapshot<Map<String, dynamic>>;
            final event = ordered[index]['data'] as Map<String, dynamic>;
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
                      communityId: d.reference.parent.parent!.id,
                      eventId: d.id,
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
                                ' ${(event['registered'] ?? []).length} Participant${(event['registered'] ?? []).length <= 1 ? '' : 's'}',
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



