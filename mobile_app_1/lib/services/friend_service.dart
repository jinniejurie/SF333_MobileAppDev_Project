import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  FriendService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _friendsCollection(String uid) =>
      _firestore.collection('friends').doc(uid).collection('list');

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

  Future<void> rejectOrRemoveFriend(String otherUserId) async {
    final batch = _firestore.batch();
    batch.delete(_friendsCollection(_uid).doc(otherUserId));
    batch.delete(_friendsCollection(otherUserId).doc(_uid));
    await batch.commit();
  }

  Stream<List<String>> watchAcceptedFriendIds({String? uid}) {
    final userId = uid ?? _uid;
    return _friendsCollection(userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchIncomingRequests() {
    return _friendsCollection(_uid)
        .where('status', isEqualTo: 'pending')
        .where('direction', isEqualTo: 'incoming')
        .snapshots()
        .map((s) => s.docs);
  }
}


