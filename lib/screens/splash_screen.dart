// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asksr/services/app_state_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Future<FirebaseApp> firebaseInitFuture;

  const SplashScreen({
    super.key,
    required this.firebaseInitFuture,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 🚀 OPTIMIZATION 1: Wait for Firebase (already initializing in background)
      await widget.firebaseInitFuture;

      // 🚀 OPTIMIZATION 2: Check auth state immediately (no delay)
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Not logged in - go to login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 🚀 OPTIMIZATION 3: Load user data + university check in parallel
      final userDocFuture =
          FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final userDoc = await userDocFuture;

      if (!userDoc.exists) {
        // User doc doesn't exist - go to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final userData = userDoc.data()!;
      final universityId = userData['universityId'] as String?;

      // 🚀 OPTIMIZATION 4: Initialize app state service (singleton, cached)
      AppStateService.instance.initialize(
        userId: user.uid,
        universityId: universityId ?? '',
        universityName: userData['universityName'] as String? ?? '',
        userName: userData['name'] as String? ?? 'User',
        userYear: userData['userYear'] as String? ?? '',
        isSenior: userData['isSenior'] as bool? ?? false,
      );

      if (universityId == null || universityId.isEmpty) {
        // No university selected - go to picker
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/university-picker');
        }
        return;
      }

      // 🚀 OPTIMIZATION 5: Update presence in background (don't await)
      _updatePresenceInBackground(
          user.uid, universityId, userData['isSenior'] ?? false);

      // All set - go to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // On error, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  // 🚀 CRITICAL: Run in background, don't block navigation
  void _updatePresenceInBackground(
      String userId, String universityId, bool isSenior) {
    FirebaseFirestore.instance.collection('presence').doc(userId).set({
      'online': true,
      'isSenior': isSenior,
      'universityId': universityId,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint('Presence update error: $e');
    });
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3b82f6).withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'AS',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AskSr',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting students with seniors',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // Minimal loading indicator
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
