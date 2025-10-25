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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom top bar matching mock (light blue background)
          Container(
            padding: const EdgeInsets.only(top: 52, left: 12, right: 12, bottom: 12),
            width: double.infinity,
            color: const Color(0xFFC8ECF7),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _firestore.collection('users').doc(widget.otherUserId).snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data();
                      final name = data?['name'] ?? 'Name';
                      return Text(
                        name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                ),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();
                    final fromMe = m['senderId'] == uid;
                    final text = (m['text'] ?? '') as String;
                    final imageUrl = m['imageUrl'] as String?;
                    final readBy = List<String>.from(m['readBy'] ?? []);
                    final sent = readBy.isNotEmpty;
                    final read = readBy.contains(widget.otherUserId);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!fromMe) ...[
                            const _SmallAvatar(),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE7F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(imageUrl),
                                  ),
                                if (text.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    decoration: BoxDecoration(
                                      color: fromMe ? Colors.black : const Color(0xFFEDE7F6),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        color: fromMe ? Colors.white : const Color(0xFF47424F),
                                        fontWeight: fromMe ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
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
          const SizedBox(height: 8),
          _MockInputBar(
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

class _MockInputBar extends StatefulWidget {
  const _MockInputBar({required this.onSend});
  final Future<void> Function(String text) onSend;

  @override
  State<_MockInputBar> createState() => _MockInputBarState();
}

class _MockInputBarState extends State<_MockInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFC8ECF7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_outlined)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await widget.onSend(text);
                  _controller.clear();
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar();
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFE5DEED),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}


