/// 环境配置
/// 
/// 通过编译时参数指定环境：
/// - 开发环境（默认）：flutter run
/// - 生产环境：flutter build apk --dart-define=ENVIRONMENT=production

class EnvConfig {
  /// 当前环境
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// 是否为生产环境
  static bool get isProduction => environment == 'production';

  /// 服务器基础URL
  static String get baseUrl {
    if (isProduction) {
      return const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'http://8.141.116.178:3000',
      );
    } else {
      // 开发环境使用本地IP
      return const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'http://192.168.124.18:3000',
      );
    }
  }

  /// 阿里云号码认证 Android Secret Key
  /// 
  /// 注意：开发环境和生产环境使用不同的签名，需要在阿里云后台分别创建应用并获取对应的 Secret
  /// - 开发环境：使用 debug.keystore 签名，对应开发环境的 Secret
  /// - 生产环境：使用 release.keystore 签名，对应生产环境的 Secret
  static String get aliAuthAndroidSecret {
    if (isProduction) {
      // 生产环境 Secret (需要在阿里云后台使用 release 签名创建)
      return const String.fromEnvironment(
        'ALI_AUTH_ANDROID_SECRET_PROD',
        defaultValue: 'Jbnn5POy0KiwkuFbAtgAWGHkVTXfiGt8akcEXZ2DfOTlNXPHM74r3jyQ5h9wJynhKPHqatZohIojS9W7G8ttNYAhZfjOETW5CXivIHy7pnkIfZjth6EggzpR9Ob5JHu5Fc04i9HTqakJQpP88Vdsbmruy0mtZLOVPGj2kAqbxm9rAVBcMsbVUPFTtjZtY0/UI3seB0jAIa+VyYxIYD1FPmZOak97h9Frz3DSH0mphLwyeAN+PfgAq4NoWRtpJiaZnmoVwqpp4bXIjMlRX/1aVECzjszMLHfN7TWKHCxHcYrA1yHe5Gm3NXjuIvDW4ZJe',
      );
    } else {
      // 开发环境 Secret (使用 debug 签名)
      return const String.fromEnvironment(
        'ALI_AUTH_ANDROID_SECRET_DEV',
        defaultValue: 'dg9TjULHCZ3kh6jOCKNtyeh/ibVufWB8YoaxTSRYz0vRZ4J8AM4Ne2U2SFQxb8W3Ue7fpWaQXznFFBsDPM7ZwlAz6aoxxaiyr7dlidOAjEgzfTHOStqiSWzR4dMyA0BpqnYRRTnmFstSUVwB3X7YMRWpj1S9Aj4VqcMegBczb2KEp5uxUy25RBLWN+2v6yIlPxOR/gfPDGX6oVSOhG+lVrS9S/rUBas9W4wlDhgtKgncUfDYMBSBSIYlVFWrzt8+87lGAnBTu36cCtWOw2JdOufyufGXAtlzosZqgOEcN/X+BAer3xMNYOxexJLDixHL',
      );
    }
  }

  /// 阿里云号码认证 iOS Secret Key
  /// 
  /// iOS 同样需要区分开发和生产环境的证书
  static String get aliAuthIosSecret {
    if (isProduction) {
      // 生产环境 Secret
      return const String.fromEnvironment(
        'ALI_AUTH_IOS_SECRET_PROD',
        defaultValue: '', // TODO: 配置生产环境的 iOS Secret
      );
    } else {
      // 开发环境 Secret
      return const String.fromEnvironment(
        'ALI_AUTH_IOS_SECRET_DEV',
        defaultValue: '', // TODO: 配置开发环境的 iOS Secret
      );
    }
  }
}

