import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_cache_service.dart';

/// 支持缓存的媒体显示组件
/// 会优先使用本地缓存，如果没有则显示网络图片并下载到本地
class CachedMediaWidget extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedMediaWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedMediaWidget> createState() => _CachedMediaWidgetState();
}

class _CachedMediaWidgetState extends State<CachedMediaWidget> {
  final _mediaCache = MediaCacheService();
  String? _localPath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void didUpdateWidget(CachedMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 如果已经是本地路径，直接使用
      if (widget.url.startsWith('/') || widget.url.startsWith('file://')) {
        setState(() {
          _localPath = widget.url;
          _isLoading = false;
        });
        return;
      }

      // 检查本地缓存
      final cachedPath = await _mediaCache.getLocalPath(widget.url);
      if (cachedPath != null) {
        setState(() {
          _localPath = cachedPath;
          _isLoading = false;
        });
        return;
      }

      // 下载到本地
      final downloadedPath = await _mediaCache.downloadMedia(widget.url);
      if (downloadedPath != null) {
        setState(() {
          _localPath = downloadedPath;
          _isLoading = false;
        });
      } else {
        // 下载失败，使用网络 URL
        setState(() {
          _localPath = null;
          _isLoading = false;
          _hasError = false; // 不算错误，只是没有本地缓存
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Center(
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline),
          );
    }

    // 如果有本地路径，使用本地文件
    if (_localPath != null && _localPath!.isNotEmpty) {
      return Image.file(
        File(_localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              );
        },
      );
    }

    // 使用网络图片（作为降级方案）
    return Image.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
      },
    );
  }
}

/// 缓存视频缩略图组件
class CachedVideoThumbnail extends StatelessWidget {
  final String thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedVideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CachedMediaWidget(
          url: thumbnailUrl,
          width: width,
          height: height,
          fit: fit,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }
}

