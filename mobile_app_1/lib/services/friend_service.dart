/// Service for managing friend relationships.
/// 
/// Handles friend requests, acceptances, and friend list management.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing friend relationships and requests.
class FriendService {
  FriendService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _friendsCollection(String uid) =>
      _firestore.collection('friends').doc(uid).collection('list');

  /// Sends a friend request to a target user.
  /// 
  /// Creates bidirectional pending friend records using a batch write.
  Future<void> sendFriendRequest(String targetUserId) async {
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();

    final myDoc = _friendsCollection(_uid).doc(targetUserId);
    final theirDoc = _friendsCollection(targetUserId).doc(_uid);

    batch.set(myDoc, {
      'friendId': targetUserId,
      'createdAt': now,
      'status': 'pending',
      'direction': 'outgoing',
    }, SetOptions(merge: true));

    batch.set(theirDoc, {
      'friendId': _uid,
      'createdAt': now,
      'status': 'pending',
      'direction': 'incoming',
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Accepts a friend request from a requester.
  /// 
  /// Updates both users' friend records to 'accepted' status.
  Future<void> acceptFriendRequest(String requesterUserId) async {
    final batch = _firestore.batch();
    final myDoc = _friendsCollection(_uid).doc(requesterUserId);
    final theirDoc = _friendsCollection(requesterUserId).doc(_uid);

    batch.set(myDoc, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'direction': 'mutual',
    }, SetOptions(merge: true));

    batch.set(theirDoc, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'direction': 'mutual',
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Rejects a friend request or removes an existing friend.
  /// 
  /// Deletes the friend relationship from both users' friend lists.
  Future<void> rejectOrRemoveFriend(String otherUserId) async {
    final batch = _firestore.batch();
    batch.delete(_friendsCollection(_uid).doc(otherUserId));
    batch.delete(_friendsCollection(otherUserId).doc(_uid));
    await batch.commit();
  }

  /// Watches the list of accepted friend IDs for a user.
  Stream<List<String>> watchAcceptedFriendIds({String? uid}) {
    final userId = uid ?? _uid;
    return _friendsCollection(userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Watches incoming friend requests for the current user.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchIncomingRequests() {
    return _friendsCollection(_uid)
        .where('status', isEqualTo: 'pending')
        .where('direction', isEqualTo: 'incoming')
        .snapshots()
        .map((s) => s.docs);
  }

  /// Handles a like action (right swipe) on a user.
  /// 
  /// If the target user has already liked the current user, automatically
  /// accepts the friend request for both users. Otherwise, sends a friend request.
  Future<void> likeUser(String targetUserId) async {
    final myDoc = _friendsCollection(_uid).doc(targetUserId);
    final theirDoc = _friendsCollection(targetUserId).doc(_uid);

    final theirSnap = await theirDoc.get();

    // If the other side has an outgoing pending (which means I have incoming), accept.
    if (theirSnap.exists) {
      final data = theirSnap.data() as Map<String, dynamic>;
      if (data['status'] == 'pending' && data['direction'] == 'outgoing') {
        await acceptFriendRequest(targetUserId);
        return;
      }
      if (data['status'] == 'accepted') return; // Already friends
    }

    // Otherwise create reciprocal pending entries
    await sendFriendRequest(targetUserId);
  }
}


