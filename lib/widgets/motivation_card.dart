import 'package:flutter/material.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/widgets/cached_media_widget.dart';

class MotivationCard extends StatelessWidget {
  final Motivation motivation;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const MotivationCard({
    super.key,
    required this.motivation,
    this.onTap,
    this.onLike,
    this.onFavorite,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = motivation.type == MotivationType.positive
        ? AppTheme.positiveColor
        : AppTheme.negativeColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: (onEdit != null || onDelete != null) 
          ? () => _showOptionsMenu(context) 
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 媒体预览
            if (motivation.media.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMedium),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 使用缓存的媒体组件，支持离线显示
                      CachedMediaWidget(
                        url: motivation.media.first.displayUrl,
                        fit: BoxFit.cover,
                      ),
                      // 视频标识
                      if (motivation.media.first.type == 'video')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      // 多图标识
                      if (motivation.media.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${motivation.media.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类型标签
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              motivation.type == MotivationType.positive
                                  ? Icons.emoji_events_rounded
                                  : Icons.warning_amber_rounded,
                              size: 12,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              motivation.type == MotivationType.positive
                                  ? '正向'
                                  : '反向',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (motivation.author != null) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: motivation.author?.avatarUrl != null
                              ? NetworkImage(motivation.author!.avatarUrl!)
                              : null,
                          child: motivation.author?.avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          motivation.author?.nickname ?? '用户',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 标题
                  if (motivation.title != null && motivation.title!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      motivation.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],

                  // 内容
                  if (motivation.content != null && motivation.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      motivation.content!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],

                  // 标签
                  if (motivation.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: motivation.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 底部操作栏
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // 点赞
                        GestureDetector(
                          onTap: onLike,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Icon(
                                motivation.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: motivation.isLiked
                                    ? Colors.red
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${motivation.likeCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: motivation.isLiked
                                      ? Colors.red
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 收藏
                        GestureDetector(
                          onTap: onFavorite,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            motivation.isFavorited
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: motivation.isFavorited
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        // 更多选项按钮（仅当有编辑/删除回调时显示）
                        if (onEdit != null || onDelete != null)
                          GestureDetector(
                            onTap: () => _showOptionsMenu(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          // 浏览量
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${motivation.viewCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 简化版激励内容卡片，用于选择器等场景
class MotivationChip extends StatelessWidget {
  final Motivation motivation;
  final bool isSelected;
  final VoidCallback? onTap;

  const MotivationChip({
    super.key,
    required this.motivation,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = motivation.type == MotivationType.positive
        ? AppTheme.positiveColor
        : AppTheme.negativeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkCardColor
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? color 
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              motivation.type == MotivationType.positive
                  ? Icons.emoji_events_rounded
                  : Icons.warning_amber_rounded,
              size: 14,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                motivation.title ?? motivation.content ?? '激励内容',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected 
                      ? color 
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary),
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

