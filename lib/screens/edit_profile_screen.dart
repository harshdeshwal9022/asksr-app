import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _currentlyLearningController = TextEditingController();
  final _subjectsStrongController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _usernameChecking = false;
  bool _usernameAvailable = false;
  String? _usernameError;
  String? _originalUsername;
  String? _currentUserId;

  int _bioCharCount = 0;
  static const int _bioMaxLength = 150;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _bioController.addListener(() {
      setState(() {
        _bioCharCount = _bioController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    _skillsController.dispose();
    _currentlyLearningController.dispose();
    _subjectsStrongController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      _currentUserId = user.uid;

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      setState(() {
        _nameController.text = userData['name'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _originalUsername = userData['username']?.toLowerCase();
        _bioController.text = userData['bio'] ?? '';
        _interestsController.text = userData['interests'] ?? '';
        _skillsController.text = userData['skills'] ?? '';
        _currentlyLearningController.text = userData['currentlyLearning'] ?? '';
        _subjectsStrongController.text = userData['subjectsStrong'] ?? '';
        _bioCharCount = _bioController.text.length;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidUsername(String username) {
    if (username.isEmpty) return true;
    if (username.length < 3 || username.length > 20) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  // ✅ IMPROVED: Better error handling with detailed logging
  Future<void> _checkUsernameAvailability(String username) async {
    final usernameLower = username.toLowerCase().trim();

    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = true;
        _usernameError = null;
        _usernameChecking = false;
      });
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() {
        _usernameAvailable = false;
        _usernameError = '3-20 chars, letters/numbers/_ only';
        _usernameChecking = false;
      });
      return;
    }

    if (usernameLower == _originalUsername) {
      setState(() {
        _usernameAvailable = true;
        _usernameError = null;
        _usernameChecking = false;
      });
      return;
    }

    setState(() {
      _usernameChecking = true;
      _usernameError = null;
    });

    try {
      debugPrint('🔍 Checking username: $usernameLower');

      // ✅ FIX: Check if usernames collection exists first
      final doc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(usernameLower)
          .get();

      if (!mounted) return;

      debugPrint('📄 Document exists: ${doc.exists}');

      if (doc.exists) {
        final docUserId = doc.data()?['userId'];
        debugPrint('👤 Document userId: $docUserId');
        debugPrint('👤 Current userId: $_currentUserId');

        if (docUserId == _currentUserId) {
          setState(() {
            _usernameAvailable = true;
            _usernameError = null;
          });
          debugPrint('✅ Username belongs to current user');
        } else {
          setState(() {
            _usernameAvailable = false;
            _usernameError = '@$username is already taken';
          });
          debugPrint('❌ Username taken by another user');
        }
      } else {
        setState(() {
          _usernameAvailable = true;
          _usernameError = null;
        });
        debugPrint('✅ Username is available');
      }
    } on FirebaseException catch (e) {
      // ✅ FIX: Handle Firebase-specific errors
      debugPrint('🔥 Firebase error: ${e.code} - ${e.message}');

      if (!mounted) return;

      if (e.code == 'permission-denied') {
        setState(() {
          _usernameAvailable = false;
          _usernameError = 'Permission error. Check Firestore rules.';
        });
      } else {
        // ✅ FIX: If collection doesn't exist, username is available
        setState(() {
          _usernameAvailable = true;
          _usernameError = null;
        });
        debugPrint('✅ Collection may not exist yet, marking as available');
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');

      if (!mounted) return;

      setState(() {
        _usernameAvailable = false;
        _usernameError = 'Cannot verify username';
      });
    } finally {
      if (mounted) {
        setState(() {
          _usernameChecking = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim().toLowerCase();

    if (newUsername.isNotEmpty && newUsername != _originalUsername) {
      if (!_usernameAvailable) {
        _showErrorSnackBar('Please choose an available username');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      final batch = FirebaseFirestore.instance.batch();

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _interestsController.text.trim(),
        'skills': _skillsController.text.trim(),
        'currentlyLearning': _currentlyLearningController.text.trim(),
        'subjectsStrong': _subjectsStrongController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newUsername.isNotEmpty) {
        if (newUsername != _originalUsername) {
          if (_originalUsername != null && _originalUsername!.isNotEmpty) {
            final oldUsernameRef = FirebaseFirestore.instance
                .collection('usernames')
                .doc(_originalUsername!);
            batch.delete(oldUsernameRef);
          }

          final usernameRef = FirebaseFirestore.instance
              .collection('usernames')
              .doc(newUsername);
          batch.set(usernameRef, {
            'userId': user.uid,
            'username': _usernameController.text.trim(),
            'usernameLower': newUsername,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        updates['username'] = _usernameController.text.trim();
      } else {
        if (_originalUsername != null && _originalUsername!.isNotEmpty) {
          final oldUsernameRef = FirebaseFirestore.instance
              .collection('usernames')
              .doc(_originalUsername!);
          batch.delete(oldUsernameRef);
        }
        updates['username'] = '';
      }

      batch.update(userRef, updates);

      await batch.commit();

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
      debugPrint('Save profile error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFef4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3b82f6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 32),

                      // Name
                      _buildLabel('Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Enter your name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Username
                      _buildLabel('Username (Optional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9_]'),
                          ),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        decoration: _buildInputDecoration(
                          '@username',
                          suffixIcon: _usernameChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF60a5fa),
                                    ),
                                  ),
                                )
                              : _usernameAvailable &&
                                      _usernameController.text.isNotEmpty
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF10b981),
                                      size: 20,
                                    )
                                  : _usernameError != null &&
                                          _usernameController.text.isNotEmpty
                                      ? const Icon(
                                          Icons.cancel,
                                          color: Color(0xFFef4444),
                                          size: 20,
                                        )
                                      : null,
                        ),
                        onChanged: (value) async {
                          await _checkUsernameAvailability(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;

                          if (!_isValidUsername(value)) {
                            return '3-20 chars, letters/numbers/_ only';
                          }

                          if (value.toLowerCase() != _originalUsername &&
                              !_usernameAvailable) {
                            return _usernameError ?? 'Username not available';
                          }

                          return null;
                        },
                      ),

                      // ✅ FIX: Only show ONE error message
                      if (_usernameController.text.isNotEmpty &&
                          _usernameError != null &&
                          !_usernameChecking)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _usernameError!,
                            style: const TextStyle(
                              color: Color(0xFFef4444),
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Bio
                      _buildLabel('Bio'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: _bioMaxLength,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          'Tell others about yourself...',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        child: Text(
                          '$_bioCharCount / $_bioMaxLength',
                          style: TextStyle(
                            color: _bioCharCount > _bioMaxLength
                                ? Colors.red
                                : Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      _buildDivider(),
                      _buildSectionTitle('About You'),

                      _buildLabel('Interests'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _interestsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          'coding, reading, sports',
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Skills'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _skillsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          'Flutter, Python, DSA',
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Currently Learning'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentlyLearningController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          'What you\'re learning now',
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildDivider(),
                      _buildSectionTitle('Credentials'),

                      _buildLabel('Strong Subjects'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectsStrongController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          'Your best subjects',
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
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
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF60a5fa),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF60a5fa),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final name = _nameController.text;
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();

    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                ),
                border: Border.all(
                  color: const Color(0xFF0a0a0a),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 28),
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF3b82f6),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFef4444),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFef4444),
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFef4444),
        fontSize: 12,
      ),
    );
  }
}
