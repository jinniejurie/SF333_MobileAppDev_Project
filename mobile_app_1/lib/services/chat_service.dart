/// Service for managing chat functionality.
/// 
/// Handles chat creation, message sending, and read status tracking.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing chat rooms and messages.
class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _firestore.collection('chats');

  /// Gets an existing chat ID or creates a new chat between current user and other user.
  /// 
  /// Returns the chat document ID. Participants are sorted to ensure consistency.
  Future<String> getOrCreateChat(String otherUserId) async {
    final participants = [_uid, otherUserId]..sort();
    final existing = await _chatsCol
        .where('participants', arrayContains: _uid)
        .get();
    for (final d in existing.docs) {
      final list = List<String>.from(d.data()['participants'] ?? []);
      if (list.toSet().containsAll(participants)) {
        return d.id;
      }
    }

    final doc = await _chatsCol.add({
      'participants': participants,
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Watches all chats for a given user, ordered by last message timestamp.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChatsForUser(String uid) {
    return _chatsCol
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  /// Watches all messages in a chat, ordered chronologically.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    return _chatsCol
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Sends a text message to a chat and updates the chat's last message.
  /// 
  /// Empty messages are ignored. Uses a batch write for atomicity.
  Future<void> sendTextMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;
    final msgRef = _chatsCol.doc(chatId).collection('messages').doc();
    final data = {
      'senderId': _uid,
      'text': text,
      'imageUrl': null,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': <String>[_uid],
    };
    final batch = _firestore.batch();
    batch.set(msgRef, data);
    batch.set(_chatsCol.doc(chatId), {
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Marks all recent messages in a chat as read by the current user.
  /// 
  /// Only processes the last 50 messages for performance.
  Future<void> markMessagesAsRead(String chatId) async {
    final uid = _uid;
    final qs = await _chatsCol.doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    for (final d in qs.docs) {
      final List<dynamic> rb = (d.data()['readBy'] ?? []) as List<dynamic>;
      if (!rb.contains(uid)) {
        await d.reference.update({
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  /// Counts unread messages in a chat for a given user.
  /// 
  /// Only checks the last 50 messages for performance.
  Future<int> countUnread(String chatId, String uid) async {
    final qs = await _chatsCol.doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    int count = 0;
    for (final d in qs.docs) {
      final List<dynamic> rb = (d.data()['readBy'] ?? []) as List<dynamic>;
      if (!rb.contains(uid)) count++;
    }
    return count;
  }
}


