import 'dart:io';
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
  bool _isCheckingExisting = true;
  bool _needsPermission = false;
  double _progress = 0.0;
  String? _downloadedFilePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // 监听下载进度
    _updateService.downloadProgress.addListener(_onProgressChanged);
    _updateService.isDownloading.addListener(_onDownloadingChanged);
    
    // 先检查是否已有下载的文件，再决定是否下载
    _checkExistingAndStart();
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

  /// 检查是否有已下载的文件，没有则开始下载
  Future<void> _checkExistingAndStart() async {
    final targetVersion = widget.versionInfo['version'] as int;
    
    // 检查是否已有完整下载的文件
    final existingFile = await _updateService.checkExistingDownload(targetVersion);
    
    if (mounted) {
      if (existingFile != null) {
        // 已有完整的下载文件
        setState(() {
          _isCheckingExisting = false;
          _downloadComplete = true;
          _downloadedFilePath = existingFile;
          _progress = 1.0;
        });
      } else {
        // 没有已下载的文件，开始下载
        setState(() {
          _isCheckingExisting = false;
        });
        _startDownload();
      }
    }
  }

  /// 开始下载更新包
  Future<void> _startDownload() async {
    setState(() {
      _errorMessage = null;
    });
    
    final downloadUrl = widget.versionInfo['downloadUrl'] as String;
    final targetVersion = widget.versionInfo['version'] as int;
    
    final filePath = await _updateService.downloadUpdate(
      downloadUrl, 
      targetVersion: targetVersion,
    );
    
    if (filePath != null && mounted) {
      setState(() {
        _downloadComplete = true;
        _downloadedFilePath = filePath;
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = '下载失败，请重试';
      });
    }
  }

  /// 重试下载
  Future<void> _retryDownload() async {
    setState(() {
      _errorMessage = null;
      _progress = 0.0;
    });
    _startDownload();
  }

  /// 安装更新
  Future<void> _installUpdate() async {
    if (_downloadedFilePath == null) return;
    
    // 先检查权限
    if (Platform.isAndroid) {
      final hasPermission = await _updateService.hasInstallPermission();
      
      if (!hasPermission) {
        setState(() {
          _needsPermission = true;
        });
        return;
      }
    }
    
    final success = await _updateService.installUpdate(_downloadedFilePath!);
    
    if (success) {
      // 安装成功，更新版本号
      final newVersion = widget.versionInfo['version'] as int;
      await _updateService.setCurrentVersion(newVersion);
    }
  }

  /// 请求安装权限
  Future<void> _requestPermission() async {
    final granted = await _updateService.requestInstallPermission();
    
    if (mounted) {
      setState(() {
        _needsPermission = !granted;
      });
      
      if (granted) {
        // 权限已授予，继续安装
        _installUpdate();
      }
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
              
              // 检查已有下载
              if (_isCheckingExisting) ...[
                Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在检查...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              
              // 下载进度
              if (!_isCheckingExisting && _isDownloading) ...[
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
              
              // 下载失败
              if (!_isCheckingExisting && _errorMessage != null && !_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // 需要权限提示
              if (_needsPermission) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '需要安装权限',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '请点击下方按钮，在设置页面中允许安装未知来源应用',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // 下载完成，等待安装
              if (!_isCheckingExisting && _downloadComplete && !_isDownloading && !_needsPermission && _errorMessage == null) ...[
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
                child: _buildActionButton(),
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

  Widget _buildActionButton() {
    // 检查中
    if (_isCheckingExisting) {
      return ElevatedButton(
        onPressed: null,
        style: _buttonStyle(),
        child: const Text('检查中...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    
    // 下载失败，显示重试按钮
    if (_errorMessage != null && !_isDownloading) {
      return ElevatedButton(
        onPressed: _retryDownload,
        style: _buttonStyle(backgroundColor: Colors.orange),
        child: const Text('重新下载', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    
    // 需要权限，显示授权按钮
    if (_needsPermission) {
      return ElevatedButton(
        onPressed: _requestPermission,
        style: _buttonStyle(backgroundColor: Colors.orange),
        child: const Text('去授权', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    
    // 正在下载
    if (_isDownloading) {
      return ElevatedButton(
        onPressed: null,
        style: _buttonStyle(),
        child: const Text('正在下载...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    
    // 下载完成
    if (_downloadComplete) {
      return ElevatedButton(
        onPressed: _installUpdate,
        style: _buttonStyle(),
        child: const Text('立即更新', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    
    // 默认状态
    return ElevatedButton(
      onPressed: null,
      style: _buttonStyle(),
      child: const Text('准备下载', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
  
  ButtonStyle _buttonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
    );
  }
}
