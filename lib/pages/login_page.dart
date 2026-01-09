import 'dart:io';
import 'dart:ui';

import 'package:ali_auth/ali_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  String status = "初始化中...";
  String? userInfo;

  late CustomThirdView customThirdView;

  /// Android 密钥 - 请替换为您的实际密钥
  late String androidSk;

  /// iOS 密钥 - 请替换为您的实际密钥
  late String iosSk;

  /// 弹窗宽度
  late int screenWidth;

  /// 弹窗高度
  late int screenHeight;

  /// 比例
  late int unit;

  /// 按钮高度
  late int logBtnHeight;

  @override
  void initState() {
    super.initState();

    _ambiguate(WidgetsBinding.instance)?.addObserver(this);

    /// 初始化第三方按钮数据
    setState(() {
      // TODO: 请替换为您的实际密钥
      androidSk =
          "atAA1Exx/88Z/VpXx61uZbYQzQ+vOWqRydjjfLRU01B9EbvnwvBa6ONkpqvKyUbMO2Kn8UAgBBg6Q5ARzxUzuqpvHG/HwiBUZQellcxz3laYAFtUN8VfavkhcldFCJS6HF4/zKlhpjUAl41lEReIs00z/Msm7qSwrokul08OqgnYMbI9wP9duUI72vQfAl0xWF9zzJjhcdY7yXi4qxKsm2Xrg8rDSGvuCDk1ybMHLXF5k50yqb27TcDX1GDu8uyraisqS8IkX+G9zb7/Af3eTdpCSq02f5G1V1wjbqxL7T3DHATCLgBHF1YfRXnZKLdU";
      iosSk =
          "mjWr9sTsoXwmMx7qf0T2KQOQBpqkxeNW9I1ZNZ96ZCeBbeD9xYOUaC2mE9mcqog041VCot2sLcy9UArf+re517e5R9yowKCjf15VglZSP/HweRhOT8Cvci43zagyRqo40l85LTnZ5uJPaVauDLJB7hOTIkNPGm3fb621k6A6ZDh6aDGAKWyy0tPUPV/9RFrfeig9SURNe9Vl/Aok6SKg+SftM30uk2W8wdbV8gMVbU51Odnoapm2ZlAJYmCrdoXvROW5qc8pbQ8=";

      screenWidth =
          (PlatformDispatcher.instance.views.first.physicalSize.width /
                  PlatformDispatcher.instance.views.first.devicePixelRatio)
              .floor();
      screenHeight =
          (PlatformDispatcher.instance.views.first.physicalSize.height /
                  PlatformDispatcher.instance.views.first.devicePixelRatio)
              .floor();
      unit = screenHeight ~/ 10;
      logBtnHeight = (unit * 1.1).floor();

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
      customThirdView = CustomThirdView.fromJson(configMap);
    });

    // 监听登录事件
    AliAuth.loginListen(onEvent: (onEvent) {
      if (kDebugMode) {
        print("----------------> $onEvent <----------------");
      }

      // 自己关闭授权页面
      if (onEvent["code"] == "700005") {
        AliAuth.quitPage();
      }
      
      // 登录成功，获取token
      if (onEvent["code"] == "600000" && onEvent["data"] != null) {
        _handleLoginSuccess(onEvent["data"]);
      }

      Fluttertoast.showToast(
          msg: "${onEvent['msg']}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      setState(() {
        status = onEvent.toString();
      });
    });
  }

  /// 获取后端 API 地址
  String getApiBaseUrl() {
    if (Platform.isAndroid) {
      // Android 模拟器使用 10.0.2.2 访问宿主机
      return 'http://192.168.124.18:3000';
    } else if (Platform.isIOS) {
      // iOS 模拟器使用 localhost
      return 'http://localhost:3000';
    } else {
      // 其他平台使用 localhost
      return 'http://localhost:3000';
    }
  }

  /// 处理登录成功
  Future<void> _handleLoginSuccess(String token) async {
    try {
      // 只发送token到后端，后端通过阿里云GetMobile接口获取手机号
      final apiUrl = '${getApiBaseUrl()}/api/auth/login';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          userInfo = jsonEncode(result);
          status = "登录成功！";
        });

        Fluttertoast.showToast(
            msg: "登录成功！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);

        // 关闭登录页面
        AliAuth.quitPage();
      } else {
        setState(() {
          status = "登录失败：${response.statusCode}";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("登录请求失败: $e");
      }
      setState(() {
        status = "登录请求失败: $e";
      });
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
    AliAuth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('一键登录'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '欢迎使用一键登录',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await AliAuth.initSdk(getCustomLoginConfig());
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "开始一键登录",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                status,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (userInfo != null) ...[
                const SizedBox(height: 20),
                const Text(
                  '用户信息:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      userInfo!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 自定义界面登录配置
  AliAuthModel getCustomLoginConfig({bool isDelay = false}) {
    return AliAuthModel(androidSk, iosSk,
        isDebug: true,
        isDelay: isDelay,
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

  /// This allows a value of type T or T? to be treated as a value of type T?.
  T? _ambiguate<T>(T? value) => value;
}

