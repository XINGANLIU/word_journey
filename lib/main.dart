import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'pages/onboarding_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WordJourneyApp());
}

class WordJourneyApp extends StatefulWidget {
  const WordJourneyApp({super.key});

  @override
  State<WordJourneyApp> createState() => _WordJourneyAppState();
}

class _WordJourneyAppState extends State<WordJourneyApp> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _checkOnboarded();
  }

  Future<void> _checkOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboarded = prefs.getBool('word_journey.onboarded') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B6B62),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF155C55),
      secondary: const Color(0xFFCC6B3D),
      tertiary: const Color(0xFF4E7C90),
      surface: const Color(0xFFFFFBF5),
      surfaceContainerHighest: const Color(0xFFE9E2D8),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B6B62),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF6EC4B8),
      secondary: const Color(0xFFFFB088),
      tertiary: const Color(0xFF89BDD4),
      surface: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
    );

    if (!_onboarded!) {
      return MaterialApp(
        title: '词旅背单词',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
        ),
        home: OnboardingPage(
          onComplete: () {
            setState(() {
              _onboarded = true;
            });
          },
        ),
      );
    }

    return MaterialApp(
      title: '词旅背单词',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF5EFE6),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          indicatorColor: const Color(0xFFD8E9E5),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
          indicatorColor: const Color(0xFF2A3F3A),
        ),
      ),
      home: const WordJourneyHome(),
    );
  }
}
