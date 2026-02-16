// lib/screens/my_questions_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';
import 'package:asksr/services/firestore_cache.dart';

/// ✅ MY QUESTIONS SCREEN (Renamed from "My Answers")
/// Shows ONLY the logged-in user's questions
/// Thread-based Q&A (NOT AI chat)
/// EXTREME read/write optimization
///
/// READ EFFICIENCY:
/// - List: 1 query with .where('userId') + .limit(20)
/// - NO answer reads on list (uses answerCount field)
/// - Answers load ONLY when thread is opened
///
/// WRITE EFFICIENCY:
/// - Post question: 1 write
/// - Post answer: 2 writes (answer + update count)

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  final _appState = AppStateService.instance;

  final _cache = FirestoreCache();

  final _scrollController = ScrollController();

  List<DocumentSnapshot> _questions = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyQuestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ OPTIMIZED: Load ONLY current user's questions
  Future<void> _loadMyQuestions({bool loadMore = false}) async {
    final userId = _appState.userId;

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _questions = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }

    try {
      // ✅ OPTIMIZATION 1: Filter by userId ONLY
      Query query = FirebaseFirestore.instance
          .collection('questions')
          .where('userId', isEqualTo: userId);

      // Apply filter
      if (_selectedFilter == 'answered') {
        query = query.where('answerCount', isGreaterThan: 0);
      } else if (_selectedFilter == 'unanswered') {
        query = query.where('answerCount', isEqualTo: 0);
      }

      // ✅ OPTIMIZATION 2: Sort by recent activity
      query = query.orderBy('lastActivityAt', descending: true);

      // ✅ OPTIMIZATION 3: Pagination with limit
      query = query.limit(20);

      if (loadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // ✅ OPTIMIZATION 4: Use cache + deduplication
      final queryKey =
          'my_questions_${userId}_${_selectedFilter}_${loadMore ? 'p${_questions.length ~/ 20}' : 'initial'}';

      final snapshot = await _cache.deduplicateQuery(
        queryKey,
        () => query.get(),
      );

      debugPrint(
          '✅ Loaded ${snapshot.docs.length} user questions (reads: ${snapshot.docs.length})');

      if (snapshot.docs.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }

      setState(() {
        if (loadMore) {
          _questions.addAll(snapshot.docs);
        } else {
          _questions = snapshot.docs;
        }
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == 20;
      });
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
    } finally {
      if (!loadMore) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMore) {
        _loadMyQuestions(loadMore: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadMyQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildStats(),
            Expanded(
              child: _buildQuestionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a8a), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Questions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Track your asked questions',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/ask-question');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Ask',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildFilterChip('All Questions', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Answered', 'answered'),
            const SizedBox(width: 8),
            _buildFilterChip('Unanswered', 'unanswered'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadMyQuestions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                )
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color:
                isActive ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final totalQuestions = _questions.length;
    final answeredQuestions = _questions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['answerCount'] ?? 0) > 0;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Asked',
              '$totalQuestions',
              Icons.question_answer_outlined,
              const Color(0xFF3b82f6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Answered',
              '$answeredQuestions',
              Icons.check_circle_outline,
              const Color(0xFF10b981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              '${totalQuestions - answeredQuestions}',
              Icons.pending_outlined,
              const Color(0xFFf59e0b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_isLoading && _questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3b82f6),
        ),
      );
    }

    if (_questions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF3b82f6),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _questions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3b82f6),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final doc = _questions[index];
          final data = doc.data() as Map<String, dynamic>;
          return _buildQuestionCard(doc.id, data);
        },
      ),
    );
  }

  // ✅ OPTIMIZED: No answer reads here - uses answerCount field
  Widget _buildQuestionCard(String questionId, Map<String, dynamic> data) {
    final question = data['question'] ?? data['text'] ?? '';
    final category = data['category'] ?? 'General';
    final answerCount = data['answerCount'] ?? 0; // ✅ From denormalized field
    final viewsCount = data['viewsCount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final lastActivityAt = data['lastActivityAt'] as Timestamp?;

    String timeAgo = '';
    if (lastActivityAt != null) {
      final diff = DateTime.now().difference(lastActivityAt.toDate());
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        timeAgo = '${diff.inDays}d ago';
      } else {
        timeAgo = '${diff.inDays ~/ 7}w ago';
      }
    } else if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays < 1) {
        timeAgo = 'Today';
      } else if (diff.inDays < 7) {
        timeAgo = '${diff.inDays}d ago';
      } else {
        timeAgo = '${diff.inDays ~/ 7}w ago';
      }
    }

    final hasAnswers = answerCount > 0;

    return GestureDetector(
      onTap: () {
        // ✅ Open thread view (answers load ONLY here)
        Navigator.pushNamed(
          context,
          '/question-thread',
          arguments: {'questionId': questionId},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: hasAnswers
                ? const Color(0xFF10b981).withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF60a5fa),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasAnswers)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Color(0xFF10b981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Answered',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF10b981),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf59e0b).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Waiting',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFf59e0b),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            Text(
              question,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer stats
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$answerCount ${answerCount == 1 ? 'answer' : 'answers'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$viewsCount views',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),
            Text(
              'No questions yet',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by asking your first question\nand track all your questions here',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/ask-question');
              },
              icon: const Icon(Icons.add),
              label: const Text('Ask a Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
