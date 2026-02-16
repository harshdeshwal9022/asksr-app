// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Post a new question with atomic operations
  /// Returns questionId on success, null on failure
  static Future<String?> postQuestion({
    required String questionText,
    required String category,
    required List<String> tags,
    required bool isAnonymous,
    required bool hasCode,
    String? codeSnippet,
    String? codeLanguage,
    String? errorMessage,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      // Get user data
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? userData['username'] ?? 'Anonymous';
      final userPhoto = userData['photoUrl'] ?? '';
      final userBranchCode = userData['branchCode'] ?? 'GENERAL';
      final userUniversityCode = userData['universityCode'] ?? 'CU';

      // Create batch for atomic operations
      final batch = _db.batch();

      // 1. Create question document
      final questionRef = _db.collection('questions').doc();
      final questionData = {
        'userId': isAnonymous ? 'anonymous' : uid,
        'userName': isAnonymous ? 'Anonymous' : userName,
        'userPhoto': isAnonymous ? '' : userPhoto,
        'userBranchCode': userBranchCode,
        'userUniversityCode': userUniversityCode,
        'targetBranchCode': userBranchCode,
        'targetUniversityCode': userUniversityCode,
        'question': questionText,
        'category': category,
        'tags': tags,
        'isAnonymous': isAnonymous,
        'hasCode': hasCode,
        'codeSnippet': codeSnippet ?? '',
        'codeLanguage': codeLanguage ?? '',
        'errorMessage': errorMessage ?? '',
        'isResolved': false,
        'bestAnswerId': null,
        'answersCount': 0,
        'helpfulCount': 0,
        'viewsCount': 0,
        'upvotes': 0,
        'downvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(questionRef, questionData);

      // 2. Update user stats (only if not anonymous)
      if (!isAnonymous) {
        final userRef = _db.collection('users').doc(uid);
        batch.update(userRef, {
          'questionsCount': FieldValue.increment(1),
          'lastQuestionAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Create notifications for seniors
      await _createNotificationsForSeniors(
        batch: batch,
        questionId: questionRef.id,
        fromUserId: isAnonymous ? 'anonymous' : uid,
        fromName: isAnonymous ? 'Anonymous' : userName,
        branchCode: userBranchCode,
        universityCode: userUniversityCode,
        category: category,
      );

      // Commit all operations atomically
      await batch.commit();

      return questionRef.id;
    } catch (e) {
      print('❌ Error posting question: $e');
      return null;
    }
  }

  /// Create notifications for seniors in same branch
  static Future<void> _createNotificationsForSeniors({
    required WriteBatch batch,
    required String questionId,
    required String fromUserId,
    required String fromName,
    required String branchCode,
    required String universityCode,
    required String category,
  }) async {
    try {
      // Query seniors (users with isSenior = true in same branch/university)
      final seniorsSnapshot = await _db
          .collection('users')
          .where('isSenior', isEqualTo: true)
          .where('branchCode', isEqualTo: branchCode)
          .where('universityCode', isEqualTo: universityCode)
          .limit(100) // Limit to prevent too many writes
          .get();

      // Create notification for each senior
      for (var seniorDoc in seniorsSnapshot.docs) {
        final seniorId = seniorDoc.id;

        // Skip if same user
        if (seniorId == fromUserId) continue;

        final notificationRef = _db
            .collection('notifications')
            .doc(seniorId)
            .collection('items')
            .doc();

        final notificationData = {
          'type': 'new_question',
          'fromUserId': fromUserId,
          'fromName': fromName,
          'questionId': questionId,
          'category': category,
          'message': 'asked a new question in $category',
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        };

        batch.set(notificationRef, notificationData);
      }
    } catch (e) {
      print('⚠️ Error creating notifications: $e');
      // Don't throw - notifications are non-critical
    }
  }

  /// Increment question view count
  static Future<void> incrementViewCount(String questionId) async {
    try {
      await _db.collection('questions').doc(questionId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error incrementing view count: $e');
    }
  }

  /// Mark question as resolved
  static Future<void> markQuestionResolved({
    required String questionId,
    required String bestAnswerId,
  }) async {
    try {
      await _db.collection('questions').doc(questionId).update({
        'isResolved': true,
        'bestAnswerId': bestAnswerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking question resolved: $e');
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Check if user exists
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream questions by category
  static Stream<QuerySnapshot> getQuestionsByCategory(String category) {
    if (category == 'All') {
      return _db
          .collection('questions')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    }
    return _db
        .collection('questions')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Stream answers for a question
  static Stream<QuerySnapshot> getAnswersForQuestion(String questionId) {
    return _db
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream user's notifications
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as seen
  static Future<void> markNotificationSeen({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _db
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'seen': true});
    } catch (e) {
      print('❌ Error marking notification seen: $e');
    }
  }

  /// Mark all notifications as seen
  static Future<void> markAllNotificationsSeen(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('seen', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'seen': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications seen: $e');
    }
  }

  /// Post answer to a question
  static Future<String?> postAnswer({
    required String questionId,
    required String answerText,
    bool hasCode = false,
    String? codeSnippet,
    String? codeLanguage,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final userData = await getUserData(uid);
      if (userData == null) return null;

      final batch = _db.batch();

      // 1. Create answer document
      final answerRef = _db
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc();

      final answerData = {
        'userId': uid,
        'userName': userData['name'] ?? userData['username'] ?? 'User',
        'userPhoto': userData['photoUrl'] ?? '',
        'isSenior': userData['isSenior'] ?? false,
        'answerText': answerText,
        'hasCode': hasCode,
        'codeSnippet': codeSnippet ?? '',
        'codeLanguage': codeLanguage ?? '',
        'upvotes': 0,
        'downvotes': 0,
        'isAccepted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(answerRef, answerData);

      // 2. Increment answer count in question
      final questionRef = _db.collection('questions').doc(questionId);
      batch.update(questionRef, {
        'answersCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update user stats
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'answersCount': FieldValue.increment(1),
      });

      // 4. Create notification for question author
      final questionDoc = await questionRef.get();
      if (questionDoc.exists) {
        final questionData = questionDoc.data()!;
        final authorId = questionData['userId'];

        if (authorId != null && authorId != 'anonymous' && authorId != uid) {
          final notificationRef = _db
              .collection('notifications')
              .doc(authorId)
              .collection('items')
              .doc();

          batch.set(notificationRef, {
            'type': 'new_answer',
            'fromUserId': uid,
            'fromName': userData['name'] ?? 'Someone',
            'questionId': questionId,
            'answerId': answerRef.id,
            'message': 'answered your question',
            'createdAt': FieldValue.serverTimestamp(),
            'seen': false,
          });
        }
      }

      await batch.commit();
      return answerRef.id;
    } catch (e) {
      print('❌ Error posting answer: $e');
      return null;
    }
  }

  /// Vote on question
  static Future<void> voteQuestion({
    required String questionId,
    required bool isUpvote,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _db.collection('questions').doc(questionId).update({
        if (isUpvote)
          'upvotes': FieldValue.increment(1)
        else
          'downvotes': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error voting question: $e');
    }
  }

  /// Vote on answer
  static Future<void> voteAnswer({
    required String questionId,
    required String answerId,
    required bool isUpvote,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _db
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .update({
        if (isUpvote)
          'upvotes': FieldValue.increment(1)
        else
          'downvotes': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error voting answer: $e');
    }
  }
}
