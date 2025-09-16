import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId, required this.otherUserId});

  final String chatId;
  final String otherUserId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setPresence(true);
  }

  @override
  void dispose() {
    _setPresence(false);
    super.dispose();
  }

  Future<void> _setPresence(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('users').doc(widget.otherUserId).snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final name = data?['name'] ?? 'Chat';
            final online = data?['isOnline'] == true;
            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16)),
                    Text(online ? 'Online' : 'Offline',
                        style: TextStyle(fontSize: 12, color: online ? Colors.green : Colors.grey)),
                  ],
                )
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                // Mark as read on new messages
                _chatService.markMessagesAsRead(widget.chatId);
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();
                    final fromMe = m['senderId'] == uid;
                    final text = (m['text'] ?? '') as String;
                    final imageUrl = m['imageUrl'] as String?;
                    final readBy = List<String>.from(m['readBy'] ?? []);
                    final sent = readBy.isNotEmpty;
                    final read = readBy.contains(widget.otherUserId);
                    return Align(
                      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: fromMe ? Colors.blueAccent : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imageUrl),
                              ),
                            if (text.isNotEmpty)
                              Text(
                                text,
                                style: TextStyle(color: fromMe ? Colors.white : Colors.black87),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(((m['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now()),
                                  style: TextStyle(fontSize: 10, color: fromMe ? Colors.white70 : Colors.black45),
                                ),
                                if (fromMe) ...[
                                  const SizedBox(width: 6),
                                  Icon(read ? Icons.done_all : Icons.check,
                                      size: 16, color: read ? Colors.lightBlue[50] : (fromMe ? Colors.white70 : Colors.black45)),
                                ],
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            onSend: (text) => _chatService.sendTextMessage(widget.chatId, text),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({required this.onSend});
  final Future<void> Function(String text) onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () async {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              await widget.onSend(text);
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}


