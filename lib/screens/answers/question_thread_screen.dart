// lib/screens/question_thread_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';

/// ✅ QUESTION THREAD SCREEN
/// Shows full Q&A thread when user clicks on their question
///
/// STRUCTURE:
/// - Question at top
/// - All senior answers below
/// - Chronological order
///
/// READ OPTIMIZATION:
/// - Answers load ONLY when this screen opens
/// - NOT loaded on the list screen
/// - Single query for answers

class QuestionThreadScreen extends StatefulWidget {
  final String questionId;

  const QuestionThreadScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<QuestionThreadScreen> createState() => _QuestionThreadScreenState();
}

class _QuestionThreadScreenState extends State<QuestionThreadScreen> {
  final _appState = AppStateService.instance;
  final _answerController = TextEditingController();

  Map<String, dynamic>? _questionData;
  bool _isLoadingQuestion = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoadingQuestion = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.questionId)
          .get();

      if (!doc.exists) {
        setState(() => _error = 'Question not found');
        return;
      }

      setState(() {
        _questionData = doc.data();
        _isLoadingQuestion = false;
      });

      // Increment views
      _incrementViews();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingQuestion = false;
      });
    }
  }

  Future<void> _incrementViews() async {
    try {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.questionId)
          .update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _appState.userId;
      final userName = _appState.userName;
      final userYear = _appState.userYear;

      final answerText = _answerController.text.trim();

      // ✅ OPTIMIZATION: 2 writes total
      // Write 1: Add answer to subcollection
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .add({
        'text': answerText,
        'userId': userId,
        'userName': userName,
        'userYear': userYear,
        'upvotes': 0,
        'isBestAnswer': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Write 2: Update question document (answerCount + lastActivityAt)
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.questionId)
          .update({
        'answerCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      _answerController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted successfully!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
            _buildAnswerInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Thread',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_questionData != null)
                  Text(
                    '${_questionData!['answerCount'] ?? 0} answers',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
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

  Widget _buildContent() {
    if (_isLoadingQuestion) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3b82f6),
        ),
      );
    }

    if (_error != null) {
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
                _error!,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Question card
        _buildQuestionCard(),
        const SizedBox(height: 24),

        // Answers section
        Text(
          'Answers (${_questionData!['answerCount'] ?? 0})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ OPTIMIZATION: Answers load ONLY here
        _buildAnswersList(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _questionData!['question'] ?? _questionData!['text'] ?? '';
    final category = _questionData!['category'] ?? 'General';
    final userName = _questionData!['userName'] ?? 'You';
    final userYear = _questionData!['userYear'] ?? '';
    final createdAt = _questionData!['createdAt'] as Timestamp?;
    final hasCode = _questionData!['hasCode'] ?? false;
    final code = _questionData!['code'] ?? '';

    String timeAgo = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays < 1) {
        timeAgo = 'Today';
      } else if (diff.inDays < 7) {
        timeAgo = '${diff.inDays} days ago';
      } else {
        timeAgo = '${diff.inDays ~/ 7} weeks ago';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3b82f6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3b82f6).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category,
              style: GoogleFonts.poppins(
                color: const Color(0xFF60a5fa),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Question text
          Text(
            question,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),

          // Code snippet
          if (hasCode && code.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Footer
          Row(
            children: [
              Text(
                '$userName${userYear.isNotEmpty ? ' • $userYear' : ''}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
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
        ],
      ),
    );
  }

  Widget _buildAnswersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                color: Color(0xFF3b82f6),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No answers yet. Be the first to help!',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final answers = snapshot.data!.docs;

        return Column(
          children: answers.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildAnswerCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnswerCard(String answerId, Map<String, dynamic> data) {
    final text = data['text'] ?? '';
    final userName = data['userName'] ?? 'Senior';
    final userYear = data['userYear'] ?? '';
    final upvotes = data['upvotes'] ?? 0;
    final isBestAnswer = data['isBestAnswer'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;

    String timeAgo = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        timeAgo = '${diff.inDays}d ago';
      } else {
        timeAgo = '${diff.inDays ~/ 7}w ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBestAnswer
            ? const Color(0xFF10b981).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        border: Border.all(
          color: isBestAnswer
              ? const Color(0xFF10b981).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best answer badge
          if (isBestAnswer)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10b981),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Best Answer',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF10b981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Answer text
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF60a5fa),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$userName${userYear.isNotEmpty ? ' • $userYear' : ''}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.thumb_up_outlined,
                  size: 18,
                  color: Colors.white.withOpacity(0.5),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('questions')
                      .doc(widget.questionId)
                      .collection('answers')
                      .doc(answerId)
                      .update({
                    'upvotes': FieldValue.increment(1),
                  });
                },
              ),
              Text(
                '$upvotes',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    final isSenior = _appState.isSenior;

    if (!isSenior) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        child: Text(
          'Only seniors can answer questions',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Only show if user is a senior
    /* final userData = _appState.userData;
    if (userData == null) return const SizedBox();

    final isSenior = userData['isSenior'] ?? false;

    if (!isSenior) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        child: Text(
          'Only seniors can answer questions',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }*/

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _answerController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write your answer...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitAnswer,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _isSubmitting
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                        ),
                  color: _isSubmitting ? Colors.white.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
