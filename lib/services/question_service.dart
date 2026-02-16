import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get recent questions (for home feed)
  Stream<QuerySnapshot> getRecentQuestions({
    required String universityId,
    required String branchCode,
    int limit = 10,
  }) {
    return _firestore
        .collection('questions')
        .where('targetUniversityCode', isEqualTo: universityId)
        .where('targetBranchCode', isEqualTo: branchCode)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get questions by category
  Stream<QuerySnapshot> getQuestionsByCategory({
    required String universityId,
    required String branchCode,
    required String category,
    int limit = 20,
  }) {
    return _firestore
        .collection('questions')
        .where('targetUniversityCode', isEqualTo: universityId)
        .where('targetBranchCode', isEqualTo: branchCode)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get single question by ID (for detail screen)
  Future<DocumentSnapshot> getQuestionById(String questionId) async {
    return await _firestore.collection('questions').doc(questionId).get();
  }

  // Get question stream (real-time updates for detail screen)
  Stream<DocumentSnapshot> getQuestionStream(String questionId) {
    return _firestore.collection('questions').doc(questionId).snapshots();
  }

  // Get user's questions
  Stream<QuerySnapshot> getUserQuestions(String userId) {
    return _firestore
        .collection('questions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get unanswered questions
  Stream<QuerySnapshot> getUnansweredQuestions({
    required String universityId,
    required String branchCode,
  }) {
    return _firestore
        .collection('questions')
        .where('targetUniversityCode', isEqualTo: universityId)
        .where('targetBranchCode', isEqualTo: branchCode)
        .where('answersCount', isEqualTo: 0)
        .orderBy('answersCount')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Increment view count
  Future<void> incrementViews(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment views: $e');
    }
  }

  // Increment helpful count
  Future<void> incrementHelpful(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'helpfulCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment helpful: $e');
    }
  }

  // Mark question as resolved
  Future<void> markAsResolved({
    required String questionId,
    required String bestAnswerId,
  }) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'isResolved': true,
        'bestAnswerId': bestAnswerId,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as resolved: $e');
    }
  }

  // Delete question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // Search questions (basic text search)
  Future<QuerySnapshot> searchQuestions({
    required String universityId,
    required String branchCode,
    required String searchTerm,
  }) async {
    // Note: For production, use Algolia for better search
    // This is basic Firestore search (limited)
    return await _firestore
        .collection('questions')
        .where('targetUniversityCode', isEqualTo: universityId)
        .where('targetBranchCode', isEqualTo: branchCode)
        .orderBy('createdAt', descending: true)
        .get();
    // Filter in app after fetching (not ideal, but works for <1000 questions)
  }
}
