import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase TRƯỚC khi runApp
  await Supabase.initialize(
    url: 'https://dnvlqnixommhjqwpflmw.supabase.co',   // ← thay bằng URL thật
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE',                      // ← thay bằng key thật
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AniQuestApp());
}

class AniQuestApp extends StatelessWidget {
  const AniQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
    );
  }
}