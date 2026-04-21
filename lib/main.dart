import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/ExploreScreen/explore_service.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dnvlqnixommhjqwpflmw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE',
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExploreService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AniQuestApp(),
    ),
  );
}

class AniQuestApp extends StatelessWidget {
  const AniQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'AniQuest',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      // ✅ Inject textScaler toàn app — tất cả Text tự scale theo cài đặt
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.fontSizeFactor),
          ),
          child: child!,
        );
      },
      home: const WelcomeScreen(),
    );
  }
}