import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';

/// 版本更新服务
/// 负责检查版本、下载更新包、安装更新
class VersionUpdateService {
  static final VersionUpdateService _instance = VersionUpdateService._internal();
  factory VersionUpdateService() => _instance;
  VersionUpdateService._internal();

  /// 下载进度回调
  ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  
  /// 是否正在下载
  ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);
  
  /// 下载的文件路径
  String? _downloadedFilePath;
  
  /// 获取当前应用版本号
  Future<int> getCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('app_version') ?? 1;
  }
  
  /// 设置当前应用版本号
  Future<void> setCurrentVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_version', version);
  }
  
  /// 检查是否有新版本
  /// 返回：null - 无新版本，Map - 新版本信息
  Future<Map<String, dynamic>?> checkForUpdate(String baseUrl) async {
    try {
      final currentVersion = await getCurrentVersion();
      
      // 调用服务器API检查版本
      final response = await http.get(
        Uri.parse('$baseUrl/api/version/check'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = response.body;
        // 假设服务器返回格式: {"version": 2, "downloadUrl": "xxx", "updateLog": "xxx"}
        final versionInfo = _parseVersionInfo(data);
        
        if (versionInfo != null && versionInfo['version'] > currentVersion) {
          return versionInfo;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('检查版本更新失败: $e');
      return null;
    }
  }
  
  /// 解析版本信息
  Map<String, dynamic>? _parseVersionInfo(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      
      if (json is Map<String, dynamic>) {
        // 支持两种格式：
        // 1. {"version": 2, "downloadUrl": "xxx", "updateLog": "xxx"}
        // 2. {"data": {"version": 2, "downloadUrl": "xxx", "updateLog": "xxx"}}
        
        Map<String, dynamic> data;
        if (json.containsKey('data')) {
          data = json['data'];
        } else {
          data = json;
        }
        
        if (data.containsKey('version') && data.containsKey('downloadUrl')) {
          return {
            'version': data['version'] is int 
                ? data['version'] 
                : int.parse(data['version'].toString()),
            'downloadUrl': data['downloadUrl'].toString(),
            'updateLog': data['updateLog']?.toString() ?? '新版本更新',
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('解析版本信息失败: $e');
      return null;
    }
  }
  
  /// 下载更新包
  /// 返回：下载的文件路径，失败返回 null
  Future<String?> downloadUpdate(String downloadUrl) async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      
      // 获取应用缓存目录
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileNameFromUrl(downloadUrl);
      final filePath = '${tempDir.path}/$fileName';
      
      // 删除旧的下载文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // 开始下载
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        throw Exception('下载失败: ${response.statusCode}');
      }
      
      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (contentLength > 0) {
          downloadProgress.value = downloadedBytes / contentLength;
        }
      }
      
      await sink.close();
      
      _downloadedFilePath = filePath;
      isDownloading.value = false;
      downloadProgress.value = 1.0;
      
      return filePath;
    } catch (e) {
      debugPrint('下载更新包失败: $e');
      isDownloading.value = false;
      downloadProgress.value = 0.0;
      Fluttertoast.showToast(msg: '下载失败: $e');
      return null;
    }
  }
  
  /// 从URL中提取文件名
  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }
    
    // 根据平台返回默认文件名
    if (Platform.isAndroid) {
      return 'update.apk';
    } else if (Platform.isIOS) {
      return 'update.ipa';
    }
    
    return 'update_package';
  }
  
  /// 安装更新包
  /// Android: 调用系统安装器安装APK
  /// iOS: 提示用户通过TestFlight或App Store更新
  Future<bool> installUpdate(String filePath) async {
    try {
      if (Platform.isAndroid) {
        return await _installAndroidApk(filePath);
      } else if (Platform.isIOS) {
        return await _installIosUpdate(filePath);
      }
      
      return false;
    } catch (e) {
      debugPrint('安装更新失败: $e');
      Fluttertoast.showToast(msg: '安装失败: $e');
      return false;
    }
  }
  
  /// 安装Android APK
  Future<bool> _installAndroidApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('安装包文件不存在');
      }
      
      debugPrint('准备安装APK: $filePath');
      
      // 使用 open_file 安装APK
      final openResult = await OpenFile.open(filePath);
      
      if (openResult.type == ResultType.done) {
        Fluttertoast.showToast(msg: '开始安装更新...');
        return true;
      } else {
        throw Exception('打开安装包失败: ${openResult.message}');
      }
    } catch (e) {
      debugPrint('安装Android APK失败: $e');
      Fluttertoast.showToast(msg: '安装失败: $e');
      return false;
    }
  }
  
  /// iOS更新处理
  Future<bool> _installIosUpdate(String filePath) async {
    // iOS应用更新需要通过App Store或TestFlight
    // 这里只能提示用户手动更新
    Fluttertoast.showToast(
      msg: '请前往App Store更新应用',
      toastLength: Toast.LENGTH_LONG,
    );
    
    // 可以打开App Store链接
    // final appStoreUrl = 'https://apps.apple.com/app/idXXXXXXXXXX';
    // if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
    //   await launchUrl(Uri.parse(appStoreUrl));
    // }
    
    return false;
  }
  
  /// 获取已下载的更新包路径
  String? get downloadedFilePath => _downloadedFilePath;
  
  /// 清理下载的更新包
  Future<void> cleanupDownload() async {
    if (_downloadedFilePath != null) {
      final file = File(_downloadedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _downloadedFilePath = null;
    }
    
    downloadProgress.value = 0.0;
    isDownloading.value = false;
  }
}

