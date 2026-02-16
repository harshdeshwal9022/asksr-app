import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: StreamBuilder<DocumentSnapshot>(
        stream: authService.getUserDataStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3b82f6)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Error loading profile',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] ?? 'User';
          final username = userData['username'] ?? '';
          final bio = userData['bio'] ?? '';
          final isSenior = userData['isSenior'] ?? false;
          final universityName = userData['universityName'] ?? 'University';
          final branch = userData['branch'] ?? 'Branch';
          final year = userData['currentYear'] ?? userData['year'] ?? 'Not Set';

          // Arrays
          final interests = userData['interests'] ?? [];
          final skills = userData['skills'] ?? [];
          final currentlyLearning = userData['currentlyLearning'] ?? [];
          final subjectsStrong = userData['subjectsStrong'] ?? [];

          // Stats
          final questionsAsked = userData['questionsAsked'] ?? 0;
          final answersGiven = userData['answersGiven'] ?? 0;
          final helpfulCount = userData['helpfulCount'] ?? 0;

          return CustomScrollView(
            slivers: [
              // App Bar with Actions
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0a0a0a),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1e3a8a).withOpacity(0.8),
                          const Color(0xFF0a0a0a),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Edit Profile Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  // Settings Button
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Profile Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF3b82f6),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Username
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                          ),
                        ),
                      ],

                      // Senior/Junior Badge
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSenior
                                ? [
                                    const Color(0xFF10b981),
                                    const Color(0xFF059669)
                                  ]
                                : [
                                    const Color(0xFF8b5cf6),
                                    const Color(0xFF7c3aed)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSenior ? '🎓 Senior' : '🌟 Junior',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Bio
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            bio,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // University Details
                      const SizedBox(height: 24),
                      _buildInfoCard(
                        title: '🎓 University Details',
                        items: [
                          _InfoRow(label: 'University', value: universityName),
                          _InfoRow(label: 'Branch', value: branch),
                          _InfoRow(label: 'Year', value: year),
                        ],
                      ),

                      // About Section
                      if (interests.isNotEmpty ||
                          skills.isNotEmpty ||
                          currentlyLearning.isNotEmpty ||
                          subjectsStrong.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          title: '💡 About',
                          items: [
                            if (interests.isNotEmpty)
                              _InfoRow(
                                label: 'Interests',
                                value: _arrayToString(interests),
                              ),
                            if (skills.isNotEmpty)
                              _InfoRow(
                                label: 'Skills',
                                value: _arrayToString(skills),
                              ),
                            if (currentlyLearning.isNotEmpty)
                              _InfoRow(
                                label: 'Currently Learning',
                                value: _arrayToString(currentlyLearning),
                              ),
                            if (subjectsStrong.isNotEmpty)
                              _InfoRow(
                                label: 'Strong Subjects',
                                value: _arrayToString(subjectsStrong),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<_InfoRow> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF60a5fa), size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _arrayToString(dynamic data) {
    if (data == null) return '';
    if (data is List) return data.join(', ');
    if (data is String) return data;
    return '';
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow({required this.label, required this.value});
}
