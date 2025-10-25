import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // เก็บ swipe action (like/pass)
  Future<void> swipeUser(String targetUserId, bool isLike) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // เก็บ swipe action
      await _firestore.collection('swipes').add({
        'swiperId': currentUserId,
        'targetId': targetUserId,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ถ้าเป็น like ให้ตรวจสอบ match
      if (isLike) {
        await _checkForMatch(currentUserId, targetUserId);
      }
    } catch (e) {
      print('Error swiping user: $e');
    }
  }

  // ตรวจสอบว่ามี match หรือไม่
  Future<void> _checkForMatch(String userId1, String userId2) async {
    try {
      // ตรวจสอบว่า user2 ได้ like user1 หรือไม่
      final swipeQuery = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: userId2)
          .where('targetId', isEqualTo: userId1)
          .where('isLike', isEqualTo: true)
          .get();

      if (swipeQuery.docs.isNotEmpty) {
        // มี match! สร้าง friendship
        await _createMatch(userId1, userId2);
      }
    } catch (e) {
      print('Error checking for match: $e');
    }
  }

  // สร้าง match และ friendship
  Future<void> _createMatch(String userId1, String userId2) async {
    try {
      // สร้าง match document
      await _firestore.collection('matches').add({
        'users': [userId1, userId2],
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // สร้าง friendship สำหรับทั้งสองคน
      await _createFriendship(userId1, userId2);
      await _createFriendship(userId2, userId1);

      // สร้าง chat room
      await _createChatRoom(userId1, userId2);
    } catch (e) {
      print('Error creating match: $e');
    }
  }

  // สร้าง friendship
  Future<void> _createFriendship(String userId1, String userId2) async {
    try {
      await _firestore
          .collection('friends')
          .doc(userId1)
          .collection('list')
          .doc(userId2)
          .set({
        'friendId': userId2,
        'status': 'accepted',
        'timestamp': FieldValue.serverTimestamp(),
        'isMatch': true, // มาจาก swipe match
      });
    } catch (e) {
      print('Error creating friendship: $e');
    }
  }

  // สร้าง chat room
  Future<void> _createChatRoom(String userId1, String userId2) async {
    try {
      final chatId = '${userId1}_${userId2}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'isMatchChat': true, // มาจาก swipe match
      });
    } catch (e) {
      print('Error creating chat room: $e');
    }
  }

  // ตรวจสอบว่าได้ swipe user นี้ไปแล้วหรือไม่
  Future<bool> hasSwipedUser(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final swipeQuery = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: currentUserId)
          .where('targetId', isEqualTo: targetUserId)
          .get();

      return swipeQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking swipe status: $e');
      return false;
    }
  }

  // ตรวจสอบว่าเป็น match กันหรือไม่
  Future<bool> isMatch(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final matchQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in matchQuery.docs) {
        final users = List<String>.from(doc.data()['users']);
        if (users.contains(targetUserId)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking match status: $e');
      return false;
    }
  }

  // ดึงรายการ matches
  Stream<QuerySnapshot> getMatches() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('matches')
        .where('users', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
