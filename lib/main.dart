import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/pages/main_page.dart';
import 'package:potato_timer/pages/login_page.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/services/offline_first_service.dart';
import 'package:potato_timer/services/media_cache_service.dart';
import 'package:potato_timer/services/notification_service.dart';
import 'package:potato_timer/services/version_update_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  await ApiService().init();
  await OfflineFirstService().init();  // 初始化离线优先服务
  await MediaCacheService().init();     // 初始化媒体缓存服务
  await NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 应用启动后检查版本更新
    _checkForUpdate();
  }

  /// 检查版本更新
  Future<void> _checkForUpdate() async {
    // 延迟1秒，等待UI完全加载
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    try {
      final updateService = VersionUpdateService();
      final apiService = ApiService();
      
      // 检查是否有新版本
      final versionInfo = await updateService.checkForUpdate(apiService.baseUrl);
      
      if (versionInfo != null && mounted) {
        // 显示更新弹窗（不可关闭）
        showDialog(
          context: context,
          barrierDismissible: false, // 不允许点击外部关闭
          builder: (context) => UpdateDialog(versionInfo: versionInfo),
        );
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
      // 不影响应用正常使用
    }
  }

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
