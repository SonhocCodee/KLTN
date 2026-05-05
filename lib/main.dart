import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/ExploreScreen/explore_service.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/Notification_service.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/theme_provider.dart';
import 'package:kltn_app/screen/language/Locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kltn_app/screen/home/home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenUtil.ensureScreenSize();

  await Supabase.initialize(
    url: 'https://dnvlqnixommhjqwpflmw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE',
  );

  // ── Khởi tạo Notification Service ──
  await NotificationService().init();

  // ── Load bản dịch tiếng Anh trước khi chạy app ──
  final localeProvider = LocaleProvider();
  await localeProvider.loadTranslations();

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
        ChangeNotifierProvider.value(value: localeProvider),
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
    final session = Supabase.instance.client.auth.currentSession;

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'AniQuest',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themeProvider.fontSizeFactor),
              ),
              child: widget!,
            );
          },
          home: session != null ? const HomeWrapper() : const WelcomeScreen(),
        );
      },
    );
  }
}