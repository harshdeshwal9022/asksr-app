// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';

/// ✅ PRODUCTION-READY NOTIFICATION SCREEN
/// Shows all types of notifications:
/// - Connection requests
/// - Answer received
/// - Likes/upvotes
/// - Best answer
/// - Followers
/// - Comments
/// - Achievements

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appState = AppStateService.instance;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final userId = _appState.userId;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();

      setState(() {
        _unreadCount = snapshot.count ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading unread count: $e');
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
            _buildTabs(),
            Expanded(
              child: _buildNotificationsList(),
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
            color: Colors.white.withOpacity(0.08),
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
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Unread badge
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFef4444), Color(0xFFdc2626)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
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
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Answers'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final userId = _appState.userId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3b82f6),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length + 1, // +1 for section headers
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSectionHeader('Today');
            }

            final doc = notifications[index - 1];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      String notificationId, Map<String, dynamic> data) {
    final type = data['type'] as String;
    final isRead = data['read'] ?? false;
    final userName = data['userName'] ?? 'Someone';
    final userInitial = userName[0].toUpperCase();
    final createdAt = data['createdAt'] as Timestamp?;

    String timeAgo = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} hours ago';
      } else {
        timeAgo = '${diff.inDays} days ago';
      }
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notificationId, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF3b82f6).withOpacity(0.1),
          border: Border.all(
            color: isRead
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFF3b82f6).withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and icon
            Row(
              children: [
                Stack(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          userInitial,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Type icon
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getNotificationGradient(type),
                          border: Border.all(
                            color: const Color(0xFF0f172a),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getNotificationIcon(type),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationText(type, data),
                      const SizedBox(height: 4),
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

            // Preview (if available)
            if (data['preview'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFF3b82f6).withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  data['preview'],
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Action buttons
            if (_hasActions(type)) ...[
              const SizedBox(height: 12),
              _buildActionButtons(type, notificationId, data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationText(String type, Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'Someone';

    switch (type) {
      case 'connection_request':
        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60a5fa),
                ),
              ),
              const TextSpan(text: ' sent you a connection request'),
            ],
          ),
        );
      case 'answer_received':
        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60a5fa),
                ),
              ),
              const TextSpan(text: ' answered your question'),
            ],
          ),
        );
      case 'answer_liked':
        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60a5fa),
                ),
              ),
              const TextSpan(text: ' liked your answer'),
            ],
          ),
        );
      case 'best_answer':
        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            children: const [
              TextSpan(text: 'Your answer was marked as '),
              TextSpan(
                text: 'Best Answer!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFf59e0b),
                ),
              ),
              TextSpan(text: ' +5 helpful points'),
            ],
          ),
        );
      case 'new_follower':
        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60a5fa),
                ),
              ),
              const TextSpan(text: ' started following you'),
            ],
          ),
        );
      default:
        return Text(
          data['message'] ?? 'New notification',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
        );
    }
  }

  Widget _buildActionButtons(
      String type, String notificationId, Map<String, dynamic> data) {
    if (type == 'connection_request') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptConnectionRequest(notificationId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Accept',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _declineConnectionRequest(notificationId),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleNotificationAction(type, data),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3b82f6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _getActionButtonText(type),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
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
            const Text(
              '🔔',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when something happens',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  LinearGradient _getNotificationGradient(String type) {
    switch (type) {
      case 'answer_received':
      case 'comment':
        return const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF059669)],
        );
      case 'answer_liked':
      case 'question_liked':
        return const LinearGradient(
          colors: [Color(0xFFef4444), Color(0xFFdc2626)],
        );
      case 'connection_request':
        return const LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
        );
      case 'best_answer':
      case 'achievement':
        return const LinearGradient(
          colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
        );
      case 'new_follower':
        return const LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF0891b2)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
        );
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'answer_received':
      case 'comment':
        return '💬';
      case 'answer_liked':
      case 'question_liked':
        return '❤️';
      case 'connection_request':
        return '👥';
      case 'best_answer':
        return '🏆';
      case 'achievement':
        return '🎯';
      case 'new_follower':
        return '➕';
      default:
        return '🔔';
    }
  }

  bool _hasActions(String type) {
    return type == 'connection_request' ||
        type == 'answer_received' ||
        type == 'answer_liked';
  }

  String _getActionButtonText(String type) {
    switch (type) {
      case 'answer_received':
        return 'View Answer';
      case 'answer_liked':
        return 'View';
      case 'new_follower':
        return 'View Profile';
      default:
        return 'View';
    }
  }

  // Action handlers

  Future<void> _handleNotificationTap(
      String notificationId, Map<String, dynamic> data) async {
    // Mark as read
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});

    _loadUnreadCount();

    // Navigate based on type
    _handleNotificationAction(data['type'], data);
  }

  void _handleNotificationAction(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'answer_received':
        Navigator.pushNamed(
          context,
          '/question-detail',
          arguments: {'questionId': data['questionId']},
        );
        break;
      case 'answer_liked':
        Navigator.pushNamed(
          context,
          '/question-detail',
          arguments: {'questionId': data['questionId']},
        );
        break;
      case 'new_follower':
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {'userId': data['fromUserId']},
        );
        break;
    }
  }

  Future<void> _acceptConnectionRequest(
      String notificationId, Map<String, dynamic> data) async {
    try {
      final userId = _appState.userId;
      final fromUserId = data['fromUserId'];

      // Add connection
      await FirebaseFirestore.instance
          .collection('connections')
          .doc('${userId}_$fromUserId')
          .set({
        'userId1': userId,
        'userId2': fromUserId,
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete notification
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _loadUnreadCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request accepted!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  Future<void> _declineConnectionRequest(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _loadUnreadCount();
    } catch (e) {
      debugPrint('Error declining request: $e');
    }
  }
}
