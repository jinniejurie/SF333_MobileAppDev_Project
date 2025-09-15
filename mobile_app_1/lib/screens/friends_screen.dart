import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/friend_service.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'swipe.dart';

class FriendsScreen extends StatefulWidget {
  FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  bool _myFriendsTab = true;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gradient = const LinearGradient(
      colors: [Color(0xFF8ED3FF), Color(0xFFF7FBFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('friends')
                .doc(uid)
                .collection('list')
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with cloud and profile icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SizedBox(
                      height: 48,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset('assets/cloud_logo.png', height: 36),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))
                              ]),
                              child: const Icon(Icons.person_outline, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'Friends (${docs.length})',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _Segmented(
                      left: 'My Friends',
                      right: 'Make Friends',
                      leftActive: _myFriendsTab,
                      onLeft: () => setState(() => _myFriendsTab = true),
                      onRight: () {
                        setState(() => _myFriendsTab = false);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CardSwipe()));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: docs.isEmpty
                          ? const Center(child: Text('No friends yet'))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final friendId = docs[index].id;
                                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  stream: _firestore.collection('users').doc(friendId).snapshots(),
                                  builder: (context, userSnap) {
                                    final u = userSnap.data?.data();
                                    final name = u?['name'] ?? 'Name';
                                    final photo = u?['profileImage'] as String?;
                                    final isOnline = u?['isOnline'] == true;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.black, width: 1),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 48,
                                            backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                                            backgroundColor: const Color(0xFFF0F0F0),
                                            child: (photo == null || photo.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                                ),
                                              ),
                                              const Icon(Icons.info_outline, size: 18),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            height: 32,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                side: const BorderSide(color: Colors.black),
                                                shape: const StadiumBorder(),
                                              ),
                                              onPressed: () async {
                                                final chatId = await _chatService.getOrCreateChat(friendId);
                                                if (context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ChatDetailScreen(chatId: chatId, otherUserId: friendId),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('chat', style: TextStyle(color: Colors.black)),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: isOnline ? Colors.green : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String left;
  final String right;
  final bool leftActive;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  const _Segmented({required this.left, required this.right, required this.leftActive, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5EAFE), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onLeft,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: leftActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(left, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onRight,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: leftActive ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(right, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


