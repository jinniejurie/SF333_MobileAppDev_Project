import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/friend_service.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class FriendsScreen extends StatelessWidget {
  FriendsScreen({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('friends')
            .doc(uid)
            .collection('list')
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final friendId = docs[index].id;
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection('users').doc(friendId).snapshots(),
                builder: (context, userSnap) {
                  final u = userSnap.data?.data();
                  final name = u?['name'] ?? 'Unknown';
                  final photo = u?['profileImage'] as String?;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                      child: (photo == null || photo.isEmpty)
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(name),
                    trailing: ElevatedButton(
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
                      child: const Text('chat'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


