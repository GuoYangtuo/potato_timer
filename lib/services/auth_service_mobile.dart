/// 移动端平台的认证服务实现
/// 使用阿里云一键登录

import 'dart:io';
import 'dart:ui';

import 'package:ali_auth/ali_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato_timer/config/env_config.dart';

/// 认证服务 - 移动端实现
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Android 密钥（从环境配置获取）
  String get _androidSk => EnvConfig.aliAuthAndroidSecret;

  /// iOS 密钥（从环境配置获取）
  String get _iosSk => EnvConfig.aliAuthIosSecret;

  /// 是否支持一键登录（仅 Android 和 iOS）
  bool get supportsOneClickLogin => Platform.isAndroid || Platform.isIOS;

  /// 平台名称
  String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// 初始化 SDK
  Future<void> initSdk() async {
    if (!supportsOneClickLogin) return;
    await AliAuth.initSdk(_getLoginConfig());
  }

  /// 显示登录界面
  /// 移动端：显示阿里云一键登录界面
  /// 桌面端：显示手机号输入对话框
  Future<String?> showLoginUI(BuildContext context) async {
    if (supportsOneClickLogin) {
      // 移动端使用一键登录，通过回调处理
      await AliAuth.initSdk(_getLoginConfig());
      return null; // 移动端通过 loginListen 回调处理
    } else {
      // 桌面端（Windows/macOS/Linux）显示手机号输入
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _PhoneLoginDialog(),
      );
    }
  }

  /// 监听登录事件（仅移动端）
  void listenLoginEvent({required void Function(dynamic) onEvent}) {
    if (supportsOneClickLogin) {
      AliAuth.loginListen(onEvent: onEvent);
    }
  }

  /// 关闭授权页面（仅移动端）
  void quitPage() {
    if (supportsOneClickLogin) {
      AliAuth.quitPage();
    }
  }

  /// 释放资源
  void dispose() {
    if (supportsOneClickLogin) {
      AliAuth.dispose();
    }
  }

  /// 获取登录配置
  AliAuthModel _getLoginConfig() {
    final screenHeight =
        (PlatformDispatcher.instance.views.first.physicalSize.height /
                PlatformDispatcher.instance.views.first.devicePixelRatio)
            .floor();
    final unit = screenHeight ~/ 10;

    Map<String, dynamic> configMap = {
      "width": -1,
      "height": -1,
      "top": unit * 12 + 80,
      "space": 20,
      "size": 16,
      "color": "#026ED2",
      'itemWidth': 50,
      'itemHeight': 50,
      "viewItemName": ["支付宝", "淘宝", "微博"],
      "viewItemPath": [
        "assets/alipay.png",
        "assets/taobao.png",
        "assets/sina.png"
      ]
    };
    final customThirdView = CustomThirdView.fromJson(configMap);

    return AliAuthModel(_androidSk, _iosSk,
        isDebug: true,
        isDelay: false,
        pageType: PageType.customXml,
        statusBarColor: "#026ED2",
        bottomNavColor: "#FFFFFF",
        lightColor: true,
        navHidden: false,
        navReturnImgPath: "assets/return_btn.png",
        logoHidden: true,
        sloganHidden: true,
        numberColor: "#ffffff",
        numberSize: 28,
        logBtnBackgroundPath:
            "assets/login_btn_normal.png,assets/login_btn_unable.png,assets/login_btn_press.png",
        logBtnText: "一键登录",
        logBtnTextSize: 16,
        logBtnTextColor: "#FFF000",
        logBtnOffsetY: -1,
        logBtnOffsetY_B: -1,
        logBtnWidth: -1,
        logBtnHeight: 51,
        logBtnOffsetX: 0,
        logBtnMarginLeftAndRight: 28,
        logBtnLayoutGravity: Gravity.centerHorizntal,
        protocolOneName: "《用户协议》",
        protocolOneURL: "https://example.com/user-agreement",
        protocolTwoName: "《隐私政策》",
        protocolTwoURL: "https://example.com/privacy-policy",
        protocolCustomColor: "#026ED2",
        protocolColor: "#bfbfbf",
        protocolLayoutGravity: Gravity.centerHorizntal,
        numFieldOffsetY: -1,
        numberFieldOffsetX: 0,
        numberLayoutGravity: Gravity.centerHorizntal,
        privacyOffsetX: -1,
        privacyOffsetY: -1,
        privacyOffsetY_B: 28,
        checkBoxWidth: 18,
        checkBoxHeight: 18,
        checkboxHidden: false,
        switchAccHidden: true,
        uncheckedImgPath: "assets/btn_unchecked.png",
        checkedImgPath: "assets/btn_checked.png",
        privacyState: false,
        protocolGravity: Gravity.centerHorizntal,
        privacyTextSize: 12,
        privacyMargin: 28,
        vendorPrivacyPrefix: "",
        vendorPrivacySuffix: "",
        dialogBottom: false,
        webViewStatusBarColor: "#026ED2",
        webNavColor: "#FF00FF",
        webNavTextColor: "#F0F0F8",
        webNavReturnImgPath: "assets/return_btn.png",
        webSupportedJavascript: true,
        authPageActIn: "in_activity",
        activityOut: "out_activity",
        authPageActOut: "in_activity",
        activityIn: "out_activity",
        logBtnToastHidden: false,
        pageBackgroundPath: "assets/background_image.jpeg",
        customThirdView: customThirdView);
  }
}

/// 手机号登录对话框（用于桌面端 Windows/macOS/Linux）
class _PhoneLoginDialog extends StatefulWidget {
  const _PhoneLoginDialog();

  @override
  State<_PhoneLoginDialog> createState() => _PhoneLoginDialogState();
}

class _PhoneLoginDialogState extends State<_PhoneLoginDialog> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      Navigator.of(context).pop(_phoneController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Text('🥔', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Text(
            '登录土豆时钟',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '开发模式：直接输入手机号登录',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号',
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              validator: _validatePhone,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C42),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('登录'),
        ),
      ],
    );
  }
}

