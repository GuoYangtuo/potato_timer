import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompleted = goal.isCompletedToday;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppTheme.positiveColor.withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isCompleted 
                ? AppTheme.positiveColor.withOpacity(0.3) 
                : Colors.grey.shade200,
          ),
          boxShadow: isCompleted ? null : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // 完成状态图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.positiveColor
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.flag_rounded,
                color: isCompleted ? Colors.white : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            
            // 目标信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted 
                          ? AppTheme.positiveColor 
                          : AppTheme.textPrimary,
                      decoration: isCompleted 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: goal.streakDays > 0 
                            ? Colors.orange 
                            : AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${goal.streakDays} ${l10n.days}',
                        style: TextStyle(
                          fontSize: 12,
                          color: goal.streakDays > 0 
                              ? Colors.orange 
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (goal.enableTimer) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${goal.durationMinutes} ${l10n.minutes}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 箭头
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// 用于探索页面的目标预览卡片
class GoalPreviewCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalPreviewCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: goal.type == GoalType.mainTask
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal.type == GoalType.mainTask ? l10n.mainTask : l10n.habit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: goal.type == GoalType.mainTask
                      ? AppTheme.primaryColor
                      : AppTheme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 标题
            Text(
              goal.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const Spacer(),

            // 统计信息
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: goal.streakDays > 0 ? Colors.orange : AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  '${goal.streakDays}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: goal.streakDays > 0 ? Colors.orange : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${goal.totalCompletedDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            // 主线任务显示进度条
            if (goal.type == GoalType.mainTask && goal.totalHours > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progressPercent / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 4,
                ),
              ),
            ],

            // 作者信息
            if (goal.author != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: goal.author?.avatarUrl != null
                        ? NetworkImage(goal.author!.avatarUrl!)
                        : null,
                    child: goal.author?.avatarUrl == null
                        ? const Icon(Icons.person, size: 12, color: AppTheme.primaryColor)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      goal.author?.nickname ?? '用户',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
