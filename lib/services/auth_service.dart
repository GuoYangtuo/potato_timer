/// 认证服务抽象层
/// 通过条件导入，在移动端使用阿里云一键登录，在 Web/Desktop 使用手机号登录

export 'auth_service_stub.dart'
    if (dart.library.io) 'auth_service_mobile.dart';

