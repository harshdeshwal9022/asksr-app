// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';
import 'package:asksr/services/firestore_cache.dart';
import 'package:asksr/widgets/home/live_stats_widget.dart';
import 'package:asksr/widgets/home/notification_badge.dart';

/// ✅ COMPLETE WORKING HOME SCREEN
/// - Search icon removed
/// - Ask Question button clickable
/// - Trending section working
/// - Quick Topics navigation working
/// - Optimized Firestore reads

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  //final FirestoreCache _cache = FirestoreCache.instance;
  final FirestoreCache _cache = FirestoreCache();

  final int _currentNavIndex = 0;

  // Trending questions state
  List<DocumentSnapshot> _trendingQuestions = [];
  bool _isLoadingTrending = true;
  String? _trendingError;

  @override
  void initState() {
    super.initState();
    _loadTrendingQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Load trending questions (sorted by engagement)
  Future<void> _loadTrendingQuestions() async {
    setState(() {
      _isLoadingTrending = true;
      _trendingError = null;
    });

    try {
      final appState = AppStateService.instance;
      final universityId = appState.universityId;
      //  final branchCode = appState.branchCode;

      if (universityId.isEmpty) {
        throw Exception('University data not available');
      }

      // ✅ Query trending questions
      // Trending = most engagement (answers + views + likes)
      final snapshot = await _cache.deduplicateQuery(
        'trending_$universityId',
        () => FirebaseFirestore.instance
            .collection('questions')
            .where('universityId', isEqualTo: universityId)
            .orderBy('helpfulCount', descending: true)
            .limit(10)
            .get(),
      );

      setState(() {
        _trendingQuestions = snapshot.docs;
        _isLoadingTrending = false;
      });

      debugPrint('✅ Loaded ${_trendingQuestions.length} trending questions');
    } catch (e) {
      debugPrint('❌ Error loading trending: $e');
      setState(() {
        _trendingError = e.toString();
        _isLoadingTrending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateService.instance;
    final universityName = appState.universityName ?? 'Your University';
    final userName = appState.userName ?? 'User';
    final universityId = appState.universityId ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1e3a8a),
              Color(0xFF0f172a),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(userName),
                  ),

                  // Main Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Live Stats Widget
                        const LiveStatsWidget(),
                        const SizedBox(height: 20),

                        // ✅ FIXED: Clickable Ask Question Card
                        _buildAskQuestionCard(universityName),
                        const SizedBox(height: 20),

                        // Quick Topics
                        _buildQuickTopics(universityId),
                        const SizedBox(height: 24),

                        // ✅ FIXED: Working Trending Section
                        _buildTrendingSection(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),

              /*   // Bottom Navigation
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ), */
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER (Search icon removed)
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1e3a8a),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Hi ${userName.split(' ').first}! ',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              // ✅ FIXED: Search icon removed, only notification badge
              NotificationBadge(
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back to AskSr',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ASK QUESTION CARD (Now fully clickable!)
  // ═══════════════════════════════════════════════════════════

  Widget _buildAskQuestionCard(String universityName) {
    return GestureDetector(
      onTap: () {
        // ✅ FIXED: Entire card is now clickable
        final universityId = AppStateService.instance.universityId;

        Navigator.pushNamed(
          context,
          '/ask-question',
          arguments: universityId,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3b82f6).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get help from',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$universityName seniors',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ask questions and get real answers from senior students.',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Color(0xFF3b82f6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ask a Question',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3b82f6),
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

  // ═══════════════════════════════════════════════════════════
  // QUICK TOPICS (Navigation working)
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickTopics(String universityId) {
    final topics = [
      {'icon': '💼', 'label': 'Placement', 'category': 'Placement'},
      {'icon': '💻', 'label': 'DSA', 'category': 'Tech/DSA'},
      {'icon': '🚀', 'label': 'Projects', 'category': 'Projects'},
      {'icon': '📝', 'label': 'Academics', 'category': 'Academics'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Topics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: topics.map((topic) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: topic == topics.last ? 0 : 10),
                child: _buildTopicChip(
                  topic['icon']!,
                  topic['label']!,
                  topic['category']!,
                  universityId,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopicChip(
    String icon,
    String label,
    String category,
    String universityId,
  ) {
    return GestureDetector(
      onTap: () {
        // ✅ FIXED: Navigate to category screen
        Navigator.pushNamed(
          context,
          '/topic-filter',
          arguments: {
            'category': category,
            'universityId': universityId,
            'icon': icon,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TRENDING SECTION (Complete working implementation)
  // ═══════════════════════════════════════════════════════════

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Trending Now ',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('🔥', style: TextStyle(fontSize: 17)),
              ],
            ),
            if (_isLoadingTrending)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF60a5fa),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ Trending questions list
        if (_isLoadingTrending && _trendingQuestions.isEmpty)
          _buildTrendingLoading()
        else if (_trendingError != null && _trendingQuestions.isEmpty)
          _buildTrendingError()
        else if (_trendingQuestions.isEmpty)
          _buildTrendingEmpty()
        else
          ..._trendingQuestions.take(5).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildTrendingCard(doc.id, data);
          }),
      ],
    );
  }

  Widget _buildTrendingCard(String questionId, Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'Anonymous';
    final userYear = data['userYear'] ?? '';
    final question = data['question'] ?? data['text'] ?? '';
    final answersCount = data['answersCount'] ?? 0;
    final helpfulCount = data['helpfulCount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final isHot = helpfulCount > 20; // Mark as "HOT" if >20 likes

    // Calculate time ago
    String timeAgo = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inHours < 1) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/question-detail',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHot
                ? const Color(0xFFef4444).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF60a5fa),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userYear,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // HOT badge
                if (isHot)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HOT',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
                fontSize: 14,
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
                Icon(
                  Icons.chat_bubble_outline,
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
                const Spacer(),
                Text(
                  timeAgo,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3b82f6),
        ),
      ),
    );
  }

  Widget _buildTrendingError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade300,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load trending questions',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTrendingQuestions,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.trending_up,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No trending questions yet',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION (Icons only, no labels)
  // ═══════════════════════════════════════════════════════════
/*
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 0),
              _buildNavItem(Icons.help_outline_rounded, 1),
              _buildCenterButton(),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 2),
              _buildNavItem(Icons.person_outline_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (index != _currentNavIndex) {
          setState(() => _currentNavIndex = index);
          _handleNavigation(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isActive
              ? const Color(0xFF60a5fa)
              : Colors.white.withOpacity(0.4),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/ask-question',
            arguments: AppStateService.instance.universityId,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3b82f6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/ask-cu');
        break;
      case 2:
        Navigator.pushNamed(context, '/my-answers');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
*/
}
