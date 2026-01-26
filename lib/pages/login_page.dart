import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/pages/main_page.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/services/auth_service.dart';
import 'package:potato_timer/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  String status = "";
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _ambiguate(WidgetsBinding.instance)?.addObserver(this);

    // 只有支持一键登录的平台才需要监听登录事件
    if (_authService.supportsOneClickLogin) {
      _authService.listenLoginEvent(onEvent: (onEvent) {
        if (kDebugMode) {
          print("----------------> $onEvent <----------------");
        }

        // 自己关闭授权页面
        if (onEvent["code"] == "700005") {
          _authService.quitPage();
        }

        // 登录成功，获取token
        if (onEvent["code"] == "600000" && onEvent["data"] != null) {
          _handleAliAuthLoginSuccess(onEvent["data"]);
        }

        if (onEvent["code"] != "600000") {
          Fluttertoast.showToast(
              msg: "${onEvent['msg']}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }

        setState(() {
          status = onEvent.toString();
        });
      });
    }
  }

  /// 处理阿里云一键登录成功（移动端）
  Future<void> _handleAliAuthLoginSuccess(String token) async {
    setState(() => _isLoading = true);

    try {
      // 使用 ApiService 登录
      await ApiService().login(token);

      // 关闭授权页面
      _authService.quitPage();

      Fluttertoast.showToast(
          msg: "登录成功！",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      // 跳转到主页
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("登录请求失败: $e");
      }
      setState(() {
        status = "登录请求失败: $e";
      });
      Fluttertoast.showToast(
          msg: "登录失败，请重试",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 处理手机号直接登录（Web/Desktop）
  Future<void> _handlePhoneLogin(String phoneNumber) async {
    setState(() => _isLoading = true);

    try {
      // 使用手机号直接登录
      await ApiService().loginWithPhone(phoneNumber);

      Fluttertoast.showToast(
          msg: "登录成功！",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      // 跳转到主页
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("登录请求失败: $e");
      }
      setState(() {
        status = "登录请求失败: $e";
      });
      Fluttertoast.showToast(
          msg: "登录失败，请重试",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 处理登录按钮点击
  Future<void> _handleLoginPressed() async {
    if (_authService.supportsOneClickLogin) {
      // 移动端：显示一键登录界面
      await _authService.showLoginUI(context);
    } else {
      // Web/Desktop：显示手机号输入对话框
      final phoneNumber = await _authService.showLoginUI(context);
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        await _handlePhoneLogin(phoneNumber);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    _ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    if (kDebugMode) {
      print('LoginPage页面被销毁');
    }
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF3E0),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo 和标题
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: const Center(
                    child: Text(
                      '🥔',
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '激励自己，完成目标',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),

                const Spacer(flex: 2),

                // 特性介绍
                _buildFeatureItem(
                  Icons.flag_rounded,
                  '设定目标',
                  '创建微习惯和主线任务',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.auto_awesome_rounded,
                  '激励内容',
                  '记录激励你的经历和见闻',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.notifications_rounded,
                  '智能提醒',
                  '准时提醒，不错过任何目标',
                ),

                const Spacer(flex: 2),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_android_rounded),
                              const SizedBox(width: 8),
                              Text(
                                _authService.supportsOneClickLogin
                                    ? l10n.loginWithPhone
                                    : '手机号登录',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // 协议说明
                Text(
                  '登录即表示同意《用户协议》和《隐私政策》',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// This allows a value of type T or T? to be treated as a value of type T?.
  T? _ambiguate<T>(T? value) => value;
}
