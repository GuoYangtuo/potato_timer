import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

/// 版本更新服务
/// 负责检查版本、下载更新包、安装更新
class VersionUpdateService {
  static final VersionUpdateService _instance = VersionUpdateService._internal();
  factory VersionUpdateService() => _instance;
  VersionUpdateService._internal();

  /// SharedPreferences keys
  static const String _keyDownloadedApkPath = 'downloaded_apk_path';
  static const String _keyDownloadedApkVersion = 'downloaded_apk_version';
  static const String _keyDownloadedApkSize = 'downloaded_apk_size';

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
      debugPrint(response.body);
      
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
  
  /// 检查是否已有下载完成的APK（断点续传支持）
  /// 返回：下载完成的文件路径，没有则返回 null
  Future<String?> checkExistingDownload(int targetVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_keyDownloadedApkPath);
      final savedVersion = prefs.getInt(_keyDownloadedApkVersion);
      final savedSize = prefs.getInt(_keyDownloadedApkSize);
      
      if (savedPath == null || savedVersion == null || savedSize == null) {
        return null;
      }
      
      // 检查版本是否匹配
      if (savedVersion != targetVersion) {
        debugPrint('已下载版本($savedVersion)与目标版本($targetVersion)不匹配，需重新下载');
        await _clearDownloadInfo();
        return null;
      }
      
      // 检查文件是否存在
      final file = File(savedPath);
      if (!await file.exists()) {
        debugPrint('已下载文件不存在，需重新下载');
        await _clearDownloadInfo();
        return null;
      }
      
      // 检查文件大小是否完整
      final fileSize = await file.length();
      if (fileSize != savedSize) {
        debugPrint('文件大小不匹配 (本地: $fileSize, 期望: $savedSize)，需重新下载');
        await file.delete();
        await _clearDownloadInfo();
        return null;
      }
      
      debugPrint('找到已下载的APK: $savedPath');
      _downloadedFilePath = savedPath;
      downloadProgress.value = 1.0;
      return savedPath;
    } catch (e) {
      debugPrint('检查已下载文件失败: $e');
      return null;
    }
  }
  
  /// 保存下载信息到持久化存储
  Future<void> _saveDownloadInfo(String filePath, int version, int fileSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDownloadedApkPath, filePath);
    await prefs.setInt(_keyDownloadedApkVersion, version);
    await prefs.setInt(_keyDownloadedApkSize, fileSize);
  }
  
  /// 清除下载信息
  Future<void> _clearDownloadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDownloadedApkPath);
    await prefs.remove(_keyDownloadedApkVersion);
    await prefs.remove(_keyDownloadedApkSize);
  }
  
  /// 下载更新包（支持断点续传）
  /// 返回：下载的文件路径，失败返回 null
  Future<String?> downloadUpdate(String downloadUrl, {int? targetVersion}) async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      
      // 使用应用文档目录（持久化存储），而非临时目录
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = _getFileNameFromUrl(downloadUrl);
      final filePath = '${appDir.path}/updates/$fileName';
      
      // 确保目录存在
      final updateDir = Directory('${appDir.path}/updates');
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }
      
      final file = File(filePath);
      int downloadedBytes = 0;
      
      // 检查是否有部分下载的文件（断点续传）
      if (await file.exists()) {
        downloadedBytes = await file.length();
        debugPrint('发现部分下载的文件，已下载: $downloadedBytes 字节');
      }
      
      // 先获取文件总大小
      final headResponse = await http.head(Uri.parse(downloadUrl));
      final contentLength = int.tryParse(
        headResponse.headers['content-length'] ?? '0'
      ) ?? 0;
      
      debugPrint('文件总大小: $contentLength 字节');
      
      // 如果已下载完成
      if (downloadedBytes > 0 && downloadedBytes >= contentLength && contentLength > 0) {
        debugPrint('文件已完整下载');
        _downloadedFilePath = filePath;
        isDownloading.value = false;
        downloadProgress.value = 1.0;
        
        if (targetVersion != null) {
          await _saveDownloadInfo(filePath, targetVersion, contentLength);
        }
        return filePath;
      }
      
      // 创建下载请求（支持断点续传）
      final request = http.Request('GET', Uri.parse(downloadUrl));
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
        debugPrint('断点续传，从 $downloadedBytes 字节开始');
      }
      
      final response = await http.Client().send(request);
      
      // 检查响应状态码
      // 200 = 完整下载, 206 = 部分内容（断点续传）
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('下载失败: ${response.statusCode}');
      }
      
      // 如果服务器不支持断点续传，重新下载
      if (downloadedBytes > 0 && response.statusCode == 200) {
        debugPrint('服务器不支持断点续传，重新下载');
        downloadedBytes = 0;
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      final totalBytes = contentLength > 0 ? contentLength : (response.contentLength ?? 0);
      
      // 打开文件写入（追加模式用于断点续传）
      final sink = file.openWrite(mode: downloadedBytes > 0 ? FileMode.append : FileMode.write);
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (totalBytes > 0) {
          downloadProgress.value = downloadedBytes / totalBytes;
        }
      }
      
      await sink.close();
      
      _downloadedFilePath = filePath;
      isDownloading.value = false;
      downloadProgress.value = 1.0;
      
      // 保存下载信息
      if (targetVersion != null) {
        final finalSize = await file.length();
        await _saveDownloadInfo(filePath, targetVersion, finalSize);
      }
      
      debugPrint('下载完成: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('下载更新包失败: $e');
      isDownloading.value = false;
      // 不重置进度，保留部分下载的状态
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
  
  /// 检查是否有安装APK的权限
  Future<bool> hasInstallPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    final status = await Permission.requestInstallPackages.status;
    return status.isGranted;
  }
  
  /// 请求安装APK的权限
  /// 返回：true - 已授权，false - 用户拒绝
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    // 检查当前权限状态
    var status = await Permission.requestInstallPackages.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // 请求权限（会跳转到系统设置页面）
    status = await Permission.requestInstallPackages.request();
    
    return status.isGranted;
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
      
      // 检查安装权限
      final hasPermission = await hasInstallPermission();
      if (!hasPermission) {
        Fluttertoast.showToast(
          msg: '请先授予安装权限',
          toastLength: Toast.LENGTH_LONG,
        );
        
        // 尝试请求权限
        final granted = await requestInstallPermission();
        if (!granted) {
          throw Exception('未授予安装权限，请在设置中允许安装未知来源应用');
        }
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
    
    await _clearDownloadInfo();
    downloadProgress.value = 0.0;
    isDownloading.value = false;
  }
}
