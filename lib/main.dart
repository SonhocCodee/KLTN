import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/Animal_detail/widgets/Animal_api_cache_service.dart';
import 'package:kltn_app/screen/ExploreScreen/explore_service.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/Notification_service.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/theme_provider.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/unit_provider.dart';
import 'package:kltn_app/screen/language/Locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kltn_app/screen/home/home_wrapper.dart';
import 'package:kltn_app/screen/Auth/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/app_env.dart';
import 'firebase_options.dart';
import 'core/app_navigator.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await ScreenUtil.ensureScreenSize();

  WidgetsFlutterBinding.ensureInitialized();

  AppEnv.checkRequiredForAppStart();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  await PushNotificationService.instance.init();


  // Load trạng thái guest từ SharedPreferences trước khi runApp
  await AuthService.init();

  await NotificationService().init();

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
        ChangeNotifierProvider(create: (_) => UnitProvider()),
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
          navigatorKey: AppNavigator.navigatorKey,
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
          home: (session != null || AuthService.isGuest)
              ? const HomeWrapper()
              : const WelcomeScreen(),
        );
      },
    );
  }
}