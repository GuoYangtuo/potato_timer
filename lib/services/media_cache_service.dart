import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 媒体缓存服务 - 负责下载和管理媒体文件的本地缓存
class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  Directory? _cacheDir;

  /// 初始化缓存目录
  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'media_cache'));
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      debugPrint('媒体缓存目录初始化成功: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('初始化缓存目录失败: $e');
    }
  }

  /// 获取缓存目录
  Future<Directory> get cacheDirectory async {
    if (_cacheDir == null) {
      await init();
    }
    return _cacheDir!;
  }

  /// 根据 URL 生成本地文件名（使用 MD5 hash）
  String _getFileNameFromUrl(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    final extension = path.extension(url).split('?').first; // 移除查询参数
    return '${digest.toString()}$extension';
  }

  /// 下载媒体文件到本地
  Future<String?> downloadMedia(String url) async {
    try {
      // 检查是否已经缓存
      final localPath = await getLocalPath(url);
      if (localPath != null) {
        debugPrint('媒体文件已缓存: $localPath');
        return localPath;
      }

      // 下载文件
      debugPrint('开始下载媒体: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        debugPrint('下载失败: HTTP ${response.statusCode}');
        return null;
      }

      // 保存到本地
      final dir = await cacheDirectory;
      final fileName = _getFileNameFromUrl(url);
      final file = File(path.join(dir.path, fileName));
      
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('媒体下载成功: ${file.path}');
      
      return file.path;
    } catch (e) {
      debugPrint('下载媒体失败: $e');
      return null;
    }
  }

  /// 批量下载媒体文件
  Future<Map<String, String>> downloadMediaBatch(List<String> urls) async {
    final results = <String, String>{};
    
    for (final url in urls) {
      final localPath = await downloadMedia(url);
      if (localPath != null) {
        results[url] = localPath;
      }
    }
    
    return results;
  }

  /// 获取媒体的本地路径（如果已缓存）
  Future<String?> getLocalPath(String url) async {
    try {
      final dir = await cacheDirectory;
      final fileName = _getFileNameFromUrl(url);
      final file = File(path.join(dir.path, fileName));
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('获取本地路径失败: $e');
      return null;
    }
  }

  /// 检查媒体是否已缓存
  Future<bool> isCached(String url) async {
    final localPath = await getLocalPath(url);
    return localPath != null;
  }

  /// 删除指定 URL 的缓存
  Future<void> deleteCache(String url) async {
    try {
      final dir = await cacheDirectory;
      final fileName = _getFileNameFromUrl(url);
      final file = File(path.join(dir.path, fileName));
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('已删除缓存: ${file.path}');
      }
    } catch (e) {
      debugPrint('删除缓存失败: $e');
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      final dir = await cacheDirectory;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        debugPrint('已清空所有媒体缓存');
      }
    } catch (e) {
      debugPrint('清空缓存失败: $e');
    }
  }

  /// 获取缓存大小（字节）
  Future<int> getCacheSize() async {
    try {
      final dir = await cacheDirectory;
      int totalSize = 0;
      
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('获取缓存大小失败: $e');
      return 0;
    }
  }

  /// 获取缓存大小（格式化字符串）
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 获取缓存文件数量
  Future<int> getCacheCount() async {
    try {
      final dir = await cacheDirectory;
      int count = 0;
      
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            count++;
          }
        }
      }
      
      return count;
    } catch (e) {
      debugPrint('获取缓存数量失败: $e');
      return 0;
    }
  }

  /// 从本地文件路径或 URL 获取显示路径
  /// 优先返回本地路径，如果本地不存在则返回 URL
  Future<String> getDisplayPath(String urlOrPath) async {
    // 如果已经是本地路径，直接返回
    if (urlOrPath.startsWith('/') || urlOrPath.startsWith('file://')) {
      return urlOrPath;
    }

    // 检查是否有本地缓存
    final localPath = await getLocalPath(urlOrPath);
    if (localPath != null) {
      return localPath;
    }

    // 返回原始 URL
    return urlOrPath;
  }

  /// 预缓存媒体列表（在后台下载）
  Future<void> precacheMedia(List<String> urls) async {
    // 在后台下载，不阻塞 UI
    for (final url in urls) {
      if (!await isCached(url)) {
        downloadMedia(url).catchError((e) {
          debugPrint('预缓存失败 $url: $e');
          return null;
        });
      }
    }
  }
}

