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
}

