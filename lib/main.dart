import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/pages/main_page.dart';
import 'package:potato_timer/pages/login_page.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/services/notification_service.dart';
import 'package:potato_timer/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  await ApiService().init();
  await NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Potato Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // 国际化支持
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      
      home: ApiService().isLoggedIn 
          ? const MainPage() 
          : const LoginPage(),
    );
  }
}
