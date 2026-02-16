// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════
  // ✅ SIGN UP (No UID Required)
  // ═══════════════════════════════════════════════════════════
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String universityCode,
    required String branchCode,
    required String year,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // 2. Update display name
      await user.updateDisplayName(name);

      // 3. Determine if user is a senior (3rd/4th year or Alumni)
      final isSenior =
          year == '3rd Year' || year == '4th Year' || year == 'Alumni';

      // 4. Get university name
      final universityName = _getUniversityName(universityCode);
      final branchName = _getBranchName(branchCode);

      // 5. Create Firestore user document
      await _firestore.collection('users').doc(user.uid).set({
        // Auth & Basic Info
        'userId': user.uid,
        'name': name,
        'email': email,

        // University Info (multiple fields for compatibility)
        'universityCode': universityCode,
        'universityId': universityCode,
        'universityName': universityName,
        'university': universityName,

        // Branch Info
        'branchCode': branchCode,
        'branch': branchName,

        // Year Info
        'year': year,
        'currentYear': year,

        // Senior Status
        'isSenior': isSenior,
        'canAnswer': isSenior,

        // Profile (editable by user)
        'username': '',
        'bio': '',
        'photoURL': '',
        'interests': '',
        'skills': '',
        'subjectsStrong': '',

        // Stats
        'questionsAsked': 0,
        'answersGiven': 0,
        'helpfulCount': 0,
        'upvotesReceived': 0,

        // System
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ SIGN IN
  // ═══════════════════════════════════════════════════════════
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active timestamp
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ SIGN OUT
  // ═══════════════════════════════════════════════════════════
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ RESET PASSWORD
  // ═══════════════════════════════════════════════════════════
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ GET USER DATA
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ GET USER DATA STREAM (Real-time)
  // ═══════════════════════════════════════════════════════════
  Stream<DocumentSnapshot> getUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ UPDATE USER PROFILE
  // ═══════════════════════════════════════════════════════════
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? photoURL,
    String? username,
    String? interests,
    String? skills,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (username != null) updates['username'] = username;
      if (interests != null) updates['interests'] = interests;
      if (skills != null) updates['skills'] = skills;

      if (updates.length > 1) {
        // Only update if there are fields besides updatedAt
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      throw Exception('Error updating profile: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ CHECK EMAIL EXISTS
  // ═══════════════════════════════════════════════════════════
  /* Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }*/

  // ═══════════════════════════════════════════════════════════
  // ✅ CHECK USERNAME AVAILABILITY
  // ═══════════════════════════════════════════════════════════
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Error checking username: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ DELETE ACCOUNT
  // ═══════════════════════════════════════════════════════════
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw Exception('Error deleting account: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ RE-AUTHENTICATE (for sensitive operations)
  // ═══════════════════════════════════════════════════════════
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ CHANGE PASSWORD
  // ═══════════════════════════════════════════════════════════
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔧 HELPER METHODS
  // ═══════════════════════════════════════════════════════════

  // Get university full name from code
  String _getUniversityName(String code) {
    final universities = {
      'CU': 'Chandigarh University',
      'LPU': 'Lovely Professional University',
      'PU': 'Panjab University',
      'UIET': 'UIET Chandigarh',
      'GGSIPU': 'Guru Gobind Singh Indraprastha University',
      'DU': 'Delhi University',
      'BHU': 'Banaras Hindu University',
      'JNU': 'Jawaharlal Nehru University',
      'AMU': 'Aligarh Muslim University',
      'BITS': 'BITS Pilani',
      'VIT': 'Vellore Institute of Technology',
      'SRM': 'SRM Institute of Science and Technology',
      'NMIMS': 'NMIMS University',
      'MANIPAL': 'Manipal Academy of Higher Education',
    };

    return universities[code] ?? code;
  }

  // Get branch full name from code
  String _getBranchName(String code) {
    final branches = {
      'CSE': 'Computer Science Engineering',
      'IT': 'Information Technology',
      'ECE': 'Electronics & Communication Engineering',
      'EE': 'Electrical Engineering',
      'ME': 'Mechanical Engineering',
      'CE': 'Civil Engineering',
      'AIDS': 'Artificial Intelligence & Data Science',
      'CS': 'Computer Science',
      'CSIT': 'Computer Science & Information Technology',
      'AIML': 'Artificial Intelligence & Machine Learning',
      'IOT': 'Internet of Things',
      'CYBER': 'Cyber Security',
      'BCA': 'Bachelor of Computer Applications',
      'MCA': 'Master of Computer Applications',
      'MBA': 'Master of Business Administration',
      'BTECH': 'Bachelor of Technology',
      'MTECH': 'Master of Technology',
    };

    return branches[code] ?? code;
  }

  // Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'requires-recent-login':
        return 'Please log in again to perform this action';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}
