/// Web 平台的 API 服务配置
/// 
import '../config/env_config.dart';

String getBaseUrl() {
  // 统一使用环境配置
  return EnvConfig.baseUrl;
}

