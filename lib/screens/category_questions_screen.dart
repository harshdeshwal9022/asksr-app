// lib/screens/category_questions_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';
import 'package:asksr/services/firestore_cache.dart';

/// ✅ Category Questions Screen
/// Shows questions filtered by category (Placement, DSA, Projects, Academics)

class CategoryQuestionsScreen extends StatefulWidget {
  const CategoryQuestionsScreen({super.key});

  @override
  State<CategoryQuestionsScreen> createState() =>
      _CategoryQuestionsScreenState();
}

class _CategoryQuestionsScreenState extends State<CategoryQuestionsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreCache _cache = FirestoreCache();

  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  String? _category;
  String? _universityId;
  String? _icon;

  List<DocumentSnapshot> _questions = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _hasMore = true;
  String? _error;
  String _currentFilter = 'latest'; // latest, popular, unanswered

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _category == null) {
      _category = args['category'] as String?;
      _universityId = args['universityId'] as String? ??
          AppStateService.instance.universityId;
      _icon = args['icon'] as String?;
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filters = ['latest', 'popular', 'unanswered'];
      if (_currentFilter != filters[_tabController.index]) {
        setState(() {
          _currentFilter = filters[_tabController.index];
          _questions = [];
          _lastDocument = null;
          _hasMore = true;
        });
        _loadQuestions();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadQuestions(loadMore: true);
      }
    }
  }

  Future<void> _loadQuestions({bool loadMore = false}) async {
    if (_category == null || _universityId == null) return;

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Build query based on filter
      Query query = FirebaseFirestore.instance
          .collection('questions')
          .where('category', isEqualTo: _category)
          .where('targetUniversityCode', isEqualTo: _universityId);

      // Apply sorting based on current filter
      switch (_currentFilter) {
        case 'latest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'popular':
          query = query.orderBy('helpfulCount', descending: true);
          break;
        case 'unanswered':
          query = query
              .where('answersCount', isEqualTo: 0)
              .orderBy('createdAt', descending: true);
          break;
      }

      query = query.limit(10);

      // Pagination
      if (loadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // Execute query with cache
      final queryKey =
          '${_category}_${_currentFilter}_${loadMore ? 'p${_questions.length ~/ 10}' : 'initial'}';
      final snapshot = await _cache.deduplicateQuery(
        queryKey,
        () => query.get(),
      );

      debugPrint('✅ Loaded ${snapshot.docs.length} $_category questions');

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
        _hasMore = snapshot.docs.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _questions = [];
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tabs
            _buildTabs(),

            // Questions List
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF0f172a)],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Category icon and title
          if (_icon != null) ...[
            Text(_icon!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category ?? 'Questions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_questions.length} questions',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Latest'),
            Tab(text: 'Popular'),
            Tab(text: 'Unanswered'),
          ],
        ),
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

    if (_error != null && _questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load questions',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.question_answer_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No questions yet',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to ask!',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ask-question');
                },
                icon: const Icon(Icons.add),
                label: const Text('Ask Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF3b82f6),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
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

  Widget _buildQuestionCard(String questionId, Map<String, dynamic> data) {
    final text = data['question'] ?? data['text'] ?? '';
    final answersCount = data['answersCount'] ?? 0;
    final helpfulCount = data['helpfulCount'] ?? 0;
    final viewsCount = data['viewsCount'] ?? 0;
    final userName = data['userName'] ?? 'Anonymous';
    final isAnonymous = data['isAnonymous'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/question-detail',
          arguments: {'questionId': questionId},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                if (!isAnonymous) ...[
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userName.split(' ').first,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.question_answer_outlined,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '$answersCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.favorite_outline,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '$helpfulCount',
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
                  '$viewsCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
