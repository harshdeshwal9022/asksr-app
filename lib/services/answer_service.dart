import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get answers for a question (real-time)
  Stream<QuerySnapshot> getAnswersForQuestion(String questionId) {
    return _firestore
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .orderBy('createdAt', descending: false) // Oldest first
        .snapshots();
  }

  // Post an answer
  Future<String> postAnswer({
    required String questionId,
    required String answerText,
    required String userId,
    required String userName,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create answer document
      final answerRef = await _firestore
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .add({
        'text': answerText,
        'userId': userId,
        'userName': userName,
        'userYear': 'Year ${userData['yearNumber']}',
        'userBranch': userData['branch'],
        'upvotes': 0,
        'downvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment question's answer count (atomic)
      await _firestore.collection('questions').doc(questionId).update({
        'answersCount': FieldValue.increment(1),
      });

      // Increment user's answersGiven stat (atomic)
      await _firestore.collection('users').doc(userId).update({
        'answersGiven': FieldValue.increment(1),
      });

      return answerRef.id;
    } catch (e) {
      throw Exception('Failed to post answer: $e');
    }
  }

  // Upvote an answer
  Future<void> upvoteAnswer({
    required String questionId,
    required String answerId,
  }) async {
    try {
      await _firestore
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to upvote: $e');
    }
  }

  // Downvote an answer
  Future<void> downvoteAnswer({
    required String questionId,
    required String answerId,
  }) async {
    try {
      await _firestore
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .update({
        'downvotes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to downvote: $e');
    }
  }

  // Mark as best answer
  Future<void> markAsBestAnswer({
    required String questionId,
    required String answerId,
    required String answererUserId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update question with bestAnswerId
      final questionRef = _firestore.collection('questions').doc(questionId);
      batch.update(questionRef, {
        'isResolved': true,
        'bestAnswerId': answerId,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // Mark answer as best
      final answerRef = _firestore
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc(answerId);
      batch.update(answerRef, {
        'isBestAnswer': true,
      });

      // Increment answerer's helpful count (reward for best answer)
      final userRef = _firestore.collection('users').doc(answererUserId);
      batch.update(userRef, {
        'helpfulCount': FieldValue.increment(5), // 5 points for best answer
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark as best answer: $e');
    }
  }

  // Delete answer
  Future<void> deleteAnswer({
    required String questionId,
    required String answerId,
  }) async {
    try {
      await _firestore
          .collection('questions')
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .delete();

      // Decrement question's answer count
      await _firestore.collection('questions').doc(questionId).update({
        'answersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete answer: $e');
    }
  }

  // Get user's answers
  Future<List<Map<String, dynamic>>> getUserAnswers(String userId) async {
    // This requires a composite query across all questions
    // For production, you might want to store this in a separate collection
    // or use Cloud Functions to maintain an index

    // For now, this is a placeholder
    // You'd need to restructure to have answers/{answerId} at root level
    // with questionId as a field for efficient queries

    throw UnimplementedError(
        'getUserAnswers requires denormalized data structure. '
        'Consider storing answers at root level with questionId field.');
  }
}
