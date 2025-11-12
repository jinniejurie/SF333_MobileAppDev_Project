import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'swipe.dart';
import '../widgets/app_bottom_navbar.dart';
import 'community_thread_page.dart';

class CommunityDiscoverPage extends StatefulWidget {
  const CommunityDiscoverPage({super.key});

  @override
  State<CommunityDiscoverPage> createState() => _CommunityDiscoverPageState();
}

class _CommunityDiscoverPageState extends State<CommunityDiscoverPage> {
  String _searchQuery = '';
  bool _isSearching = false;

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
      }
    });
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {}
    }
  }

  Future<void> _createCommunity() async {
    await _ensureSignedIn();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Color selectedColor = const Color(0xFFF6B48F);
    final colors = <Color>[
      const Color(0xFFF6B48F),
      const Color(0xFFB3E1F4),
      const Color(0xFFF3F0B2),
      const Color(0xFFC9E6C9),
      const Color(0xFFD8C6F0),
    ];
    final ok = await showModalBottomSheet<bool>(
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
                Row(children: const [Icon(Icons.cloud), SizedBox(width: 8), Text('Create community', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))]),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Community name', filled: true, fillColor: Color(0xFFF5F6FF), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)', filled: true, fillColor: Color(0xFFF5F6FF), border: OutlineInputBorder()),
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
                              decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: selectedColor == c ? Colors.black : Colors.black26, width: 2)),
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
    if (ok != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-001';
    final ownerName = FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
    final communities = FirebaseFirestore.instance.collection('communities');
    final doc = communities.doc();
    final colorHex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';
    try {
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
      await doc.collection('threads').add({
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    }
  }

  Future<void> _joinAndOpen(String communityId, String name, String colorHex) async {
    await _ensureSignedIn();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-001';
    final ref = FirebaseFirestore.instance.collection('communities').doc(communityId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>? ?? {};
        final members = (data['members'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        if (!members.contains(uid)) {
          tx.update(ref, {'members': FieldValue.arrayUnion([uid]), 'membersCount': FieldValue.increment(1)});
        }
      });
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityThreadPage(communityId: communityId, communityName: name, coverColorHex: colorHex)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Join failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Image.asset('assets/cloud_logo.png', width: 42, height: 34),
                  const CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16)),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _createCommunity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                          Text('Create your own community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.construction, color: Colors.white, size: 18),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: const Icon(Icons.search, size: 22),
                  ),
                ]),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search communities...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Color(0xFFF5F6FF),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('communities').orderBy('membersCount', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    
                    // Filter communities based on search query
                    final filteredDocs = _searchQuery.isEmpty 
                        ? docs 
                        : docs.where((doc) {
                            final data = doc.data();
                            final name = (data['name'] ?? '').toString().toLowerCase();
                            final description = (data['description'] ?? '').toString().toLowerCase();
                            return name.contains(_searchQuery) || description.contains(_searchQuery);
                          }).toList();
                    
                    if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                      return const Center(
                        child: Text('No communities found matching your search'),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index].data();
                        final name = (data['name'] ?? 'Unknown').toString();
                        final membersCount = (data['membersCount'] ?? 0) as int;
                        final colorHex = (data['coverColor'] ?? '#FFE0B2').toString();
                        final bg = _hexToColor(colorHex);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black54)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('$membersCount members', style: const TextStyle(color: Colors.black87)),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () => _joinAndOpen(filteredDocs[index].id, name, colorHex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black)),
                                      child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                )
                              ]),
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
        onPlus: () => Navigator.of(context).pushNamed('/createPost'),
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


