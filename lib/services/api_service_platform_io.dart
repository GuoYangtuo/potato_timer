/// IO 平台（Android/iOS/Desktop）的 API 服务配置
import 'dart:io';

String getBaseUrl() {
  if (Platform.isAndroid) {
    // Android 模拟器使用 10.0.2.2 访问宿主机
    // 真机需要使用实际 IP
    return 'http://192.168.124.18:3000';
  }
  // iOS/Desktop 使用 localhost
  return 'http://localhost:3000';
}

