/// Web/Desktop 平台的认证服务实现
/// 使用手机号直接登录（免验证，仅用于开发/测试）

import 'package:flutter/material.dart';

/// 认证服务 - Web/Desktop 平台实现
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// 是否支持一键登录
  bool get supportsOneClickLogin => false;

  /// 平台名称
  String get platformName => 'Web/Desktop';

  /// 初始化 SDK（Web/Desktop 不需要）
  Future<void> initSdk() async {
    // Web/Desktop 平台不需要初始化 SDK
  }

  /// 显示登录界面
  /// 在 Web/Desktop 上显示手机号输入对话框
  Future<String?> showLoginUI(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PhoneLoginDialog(),
    );
  }

  /// 监听登录事件（Web/Desktop 不需要）
  void listenLoginEvent({required Function(Map<dynamic, dynamic>) onEvent}) {
    // Web/Desktop 平台不需要监听登录事件
  }

  /// 关闭授权页面（Web/Desktop 不需要）
  void quitPage() {
    // Web/Desktop 平台不需要关闭授权页面
  }

  /// 释放资源
  void dispose() {
    // Web/Desktop 平台不需要释放资源
  }
}

/// 手机号登录对话框
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
    // 简单的中国手机号验证
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      // 返回手机号，由调用方处理登录逻辑
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

