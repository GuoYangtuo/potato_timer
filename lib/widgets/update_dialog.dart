import 'package:flutter/material.dart';
import 'package:potato_timer/services/version_update_service.dart';

/// 版本更新弹窗
/// 强制更新，不可关闭
class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> versionInfo;
  
  const UpdateDialog({
    super.key,
    required this.versionInfo,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final VersionUpdateService _updateService = VersionUpdateService();
  bool _isDownloading = false;
  bool _downloadComplete = false;
  double _progress = 0.0;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    
    // 监听下载进度
    _updateService.downloadProgress.addListener(_onProgressChanged);
    _updateService.isDownloading.addListener(_onDownloadingChanged);
    
    // 自动开始下载
    _startDownload();
  }

  @override
  void dispose() {
    _updateService.downloadProgress.removeListener(_onProgressChanged);
    _updateService.isDownloading.removeListener(_onDownloadingChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {
        _progress = _updateService.downloadProgress.value;
      });
    }
  }

  void _onDownloadingChanged() {
    if (mounted) {
      setState(() {
        _isDownloading = _updateService.isDownloading.value;
      });
    }
  }

  /// 开始下载更新包
  Future<void> _startDownload() async {
    final downloadUrl = widget.versionInfo['downloadUrl'] as String;
    
    final filePath = await _updateService.downloadUpdate(downloadUrl);
    
    if (filePath != null && mounted) {
      setState(() {
        _downloadComplete = true;
        _downloadedFilePath = filePath;
      });
    }
  }

  /// 安装更新
  Future<void> _installUpdate() async {
    if (_downloadedFilePath == null) return;
    
    final success = await _updateService.installUpdate(_downloadedFilePath!);
    
    if (success) {
      // 安装成功，更新版本号
      final newVersion = widget.versionInfo['version'] as int;
      await _updateService.setCurrentVersion(newVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.versionInfo['version'];
    final updateLog = widget.versionInfo['updateLog'] ?? '新版本更新';

    return PopScope(
      canPop: false, // 禁止返回
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(
                    Icons.system_update,
                    size: 32,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '发现新版本',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 版本信息
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '版本 $version',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      updateLog,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 下载进度
              if (_isDownloading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '下载中... ${(_progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              
              // 下载完成，等待安装
              if (_downloadComplete && !_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '下载完成',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // 操作按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _downloadComplete ? _installUpdate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isDownloading 
                        ? '正在下载...' 
                        : _downloadComplete 
                            ? '立即更新' 
                            : '准备下载',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 提示文本
              Text(
                '为了更好的体验，请及时更新',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

