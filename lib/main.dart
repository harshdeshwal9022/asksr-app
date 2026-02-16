// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:asksr/firebase_options.dart';

// Core Screens
import 'package:asksr/screens/splash_screen.dart';
import 'package:asksr/screens/login_screen.dart';
import 'package:asksr/screens/university_picker_screen.dart';
import 'package:asksr/screens/topic_filter_screen.dart';
import 'package:asksr/screens/main_screen.dart';

// Feature Screens
import 'package:asksr/screens/search_screen.dart';
import 'package:asksr/screens/question_detail_screen.dart';
import 'package:asksr/screens/profile_screen.dart';

// Ask CU Module
import 'package:asksr/screens/ask_cu/ask_cu_feed_screen.dart';
import 'package:asksr/screens/ask_cu/ask_question_screen.dart';

// Answers Module

import 'screens/answers/my_questions_screen.dart';
import 'screens/answers/question_thread_screen.dart';
import 'package:asksr/screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase (background optimized)
  final firebaseInitFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(AskSrApp(firebaseInitFuture: firebaseInitFuture));
}

class AskSrApp extends StatelessWidget {
  final Future<FirebaseApp> firebaseInitFuture;

  const AskSrApp({
    super.key,
    required this.firebaseInitFuture,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskSr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        useMaterial3: true,
      ),

      // Splash First
      home: SplashScreen(firebaseInitFuture: firebaseInitFuture),

      // Named Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/university-picker': (context) => const UniversityPickerScreen(),
        '/home': (context) => const MainScreen(),
        '/search': (context) => const SearchScreenSmart(),
        '/ask-cu': (context) => AskCUFeedScreen(),

        '/my-questions': (context) => const MyQuestionsScreen(),

        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),

        //'/question-detail': (context) => const QuestionDetailScreen(),
      },

      // Dynamic Route (for topic filter with arguments)
      onGenerateRoute: (settings) {
        if (settings.name == '/topic-filter') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => TopicFilterScreen(
              category: args['category'],
              universityId: args['universityId'],
            ),
          );
        }

        if (settings.name == '/question-thread') {
          final questionId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) => QuestionThreadScreen(
              questionId: questionId,
            ),
          );
        }

        if (settings.name == '/question-detail') {
          final questionId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) => QuestionDetailScreen(
              questionId: questionId,
            ),
          );
        }

        if (settings.name == '/ask-question') {
          final universityId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) => AskQuestionScreen(
              universityId: universityId,
            ),
          );
        }

        return null;
      },
    );
  }
}
