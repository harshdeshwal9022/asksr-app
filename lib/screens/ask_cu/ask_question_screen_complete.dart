// lib/screens/ask_cu/ask_question_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:asksr/services/firestore_service.dart';

class AskQuestionScreen extends StatefulWidget {
  final String universityId;

  const AskQuestionScreen({
    super.key,
    required this.universityId,
  });

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _questionController = TextEditingController();
  final _codeController = TextEditingController();
  final _errorController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAnonymous = true;
  bool _hasCode = false;
  bool _isPosting = false;
  String _selectedCategory = 'Tech/DSA';
  String _selectedLanguage = 'Python';
  final List<String> _tags = [];
  int _charCount = 0;
  int _lineCount = 1;

  final List<Map<String, String>> _categories = [
    {'icon': '💼', 'name': 'Placement'},
    {'icon': '💻', 'name': 'Tech/DSA'},
    {'icon': '📖', 'name': 'Academics'},
    {'icon': '🎯', 'name': 'Projects'},
  ];

  final List<String> _languages = [
    'Python',
    'Java',
    'C++',
    'JavaScript',
    'Dart',
    'C',
    'Go',
    'Rust',
    'TypeScript',
    'Kotlin',
  ];

  final List<String> _suggestedTags = [
    'DSA',
    'Debug',
    'Algorithm',
    'Error',
    'Optimization',
    'Interview',
  ];

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_updateCharCount);
    _codeController.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _codeController.dispose();
    _errorController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _updateCharCount() {
    setState(() => _charCount = _questionController.text.length);
  }

  void _updateLineCount() {
    setState(
        () => _lineCount = '\n'.allMatches(_codeController.text).length + 1);
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed) || _tags.length >= 5) return;
    setState(() => _tags.add(trimmed));
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  String? _validateQuestion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your question';
    }
    if (value.trim().length < 10) {
      return 'Question must be at least 10 characters';
    }
    if (value.length > 500) {
      return 'Question must be less than 500 characters';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (_hasCode && (value == null || value.trim().isEmpty)) {
      return 'Please enter your code';
    }
    return null;
  }

  Future<void> _postQuestion() async {
    if (_isPosting) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors', isError: true);
      return;
    }

    if (_selectedCategory.isEmpty) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    setState(() => _isPosting = true);

    try {
      final questionId = await FirestoreService.postQuestion(
        questionText: _questionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        isAnonymous: _isAnonymous,
        hasCode: _hasCode,
        codeSnippet: _hasCode ? _codeController.text.trim() : null,
        codeLanguage: _hasCode ? _selectedLanguage : null,
        errorMessage: _hasCode ? _errorController.text.trim() : null,
      );

      if (!mounted) return;

      if (questionId != null) {
        _showSnackBar('Question posted successfully! 🎉');
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Failed to post question. Please try again.',
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1e3a8a), Color(0xFF0f172a)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: _buildScrollableContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Ask Question',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 24),
          _buildQuestionInput(),
          const SizedBox(height: 24),
          _buildCodeToggle(),
          if (_hasCode) ...[
            const SizedBox(height: 24),
            _buildLanguageSelector(),
            const SizedBox(height: 16),
            _buildCodeInput(),
            const SizedBox(height: 16),
            _buildErrorInput(),
          ],
          const SizedBox(height: 24),
          _buildCategorySection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          _buildAnonymousToggle(),
          const SizedBox(height: 32),
          _buildPostButton(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hasCode
                  ? 'Include your code, error message, and what you\'ve tried.'
                  : 'Be specific and clear. Good questions get better answers!',
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'YOUR QUESTION',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            _buildRequiredBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: _questionController,
            maxLength: 500,
            maxLines: 6,
            validator: _validateQuestion,
            style:
                const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
            decoration: InputDecoration(
              hintText: _hasCode
                  ? 'Describe your coding problem...\n\nExample:\nWhy is my recursion giving stack overflow?\nHow to optimize this sorting algorithm?'
                  : 'What do you want to know?\n\nExample:\nHow do I prepare for campus placements?\nWhich companies visit CU for CSE students?',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
              counterText: '',
              errorStyle: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_charCount/500',
            style: TextStyle(
              color: _charCount > 0
                  ? const Color(0xFF60a5fa)
                  : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💻', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Include Code Snippet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toggle if you need help with code',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasCode,
            onChanged: (value) => setState(() => _hasCode = value),
            activeThumbColor: const Color(0xFF60a5fa),
            activeTrackColor: const Color(0xFF3b82f6),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💻', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'SELECT LANGUAGE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((lang) {
            final isSelected = lang == _selectedLanguage;
            return GestureDetector(
              onTap: () => setState(() => _selectedLanguage = lang),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  lang,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📄', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'YOUR CODE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRequiredBadge(),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$_lineCount lines',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3b82f6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedLanguage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _codeController.clear(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.clear,
                            color: Colors.white70, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _codeController,
                validator: _validateCode,
                maxLines: 12,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'def factorial(n):\n    if n == 0:\n        return 1\n    return n * factorial(n-1)\n\nprint(factorial(5))',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  errorStyle:
                      const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'ERROR MESSAGE / OUTPUT',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: TextField(
            controller: _errorController,
            maxLines: 6,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Paste error message or describe expected vs actual output...\n\nExample:\nTypeError: \'int\' object is not callable\nExpected: 120\nGot: Error',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'monospace',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'SELECT CATEGORY',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            _buildRequiredBadge(),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['name'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedCategory = category['name']!),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF60a5fa)
                        : Colors.white.withOpacity(0.15),
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category['icon']!,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      category['name']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏷️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'ADD TAGS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Max 5)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  enabled: _tags.length < 5,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g., Python, Recursion, Debug...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              GestureDetector(
                onTap: () => _addTag(_tagController.text),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: _tags.length < 5
                        ? const LinearGradient(
                            colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                          )
                        : null,
                    color: _tags.length >= 5
                        ? Colors.white.withOpacity(0.2)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3b82f6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Suggested tags:',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTags.map((tag) {
            return GestureDetector(
              onTap: () => _addTag(tag),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnonymousToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🕶️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post Anonymously',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your identity will be hidden',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
            activeThumbColor: const Color(0xFF60a5fa),
            activeTrackColor: const Color(0xFF3b82f6),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPosting ? null : _postQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isPosting
                ? LinearGradient(
                    colors: [
                      const Color(0xFF3b82f6).withOpacity(0.5),
                      const Color(0xFF60a5fa).withOpacity(0.5),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isPosting
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF3b82f6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: _isPosting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📤', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        'Post Question',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf59e0b), Color(0xFFf97316)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'REQUIRED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
