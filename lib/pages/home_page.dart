import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/services/offline_first_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/motivation_page.dart';
import 'package:potato_timer/pages/create_goal_page.dart';
import 'package:potato_timer/widgets/goal_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Goal> _goals = [];
  Goal? _mainTask;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    // 使用离线优先服务，即使离线也能立即显示数据
    final service = OfflineFirstService();
    debugPrint('loadGoals - isLoggedIn: ${service.isLoggedIn}');
    setState(() => _isLoading = true);
    try {
      final goals = await service.getMyGoals();
      debugPrint('✅ goals 获取成功, 数量: ${goals.length}');  
      setState(() {
        _goals = goals.where((g) => g.type == GoalType.habit).toList();
        _mainTask = goals.where((g) => g.type == GoalType.mainTask).firstOrNull;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ _loadGoals 错误: $e');
      debugPrint('堆栈: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  void _openGoal(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MotivationPage(goalId: goal.id),
      ),
    ).then((_) => _loadGoals());
  }

  void _editGoal(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGoalPage(editGoal: goal),
      ),
    ).then((result) {
      if (result == true) {
        _loadGoals();
      }
    });
  }

  void _showMainTaskOptions(Goal goal, AppLocalizations l10n) {
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
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _editGoal(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteGoal(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: Text(l10n.cancel),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(Goal goal) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('删除目标'),
        content: const Text('确定要删除这个目标吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await OfflineFirstService().deleteGoal(goal.id);
        _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadGoals,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // 主线任务卡片
              if (_mainTask != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildMainTaskCard(_mainTask!, l10n),
                  ),
                ),

              // 微习惯标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.habit,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_goals.where((g) => g.isCompletedToday).length}/${_goals.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 加载中或空状态
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (_goals.isEmpty && _mainTask == null)
                SliverFillRemaining(
                  child: _buildEmptyView(l10n),
                )
              else
                // 微习惯列表
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GoalCard(
                            goal: _goals[index],
                            onTap: () => _openGoal(_goals[index]),
                            onEdit: () => _editGoal(_goals[index]),
                            onDelete: () => _deleteGoal(_goals[index]),
                          ),
                        );
                      },
                      childCount: _goals.length,
                    ),
                  ),
                ),

              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTaskCard(Goal goal, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _openGoal(goal),
      onLongPress: () => _showMainTaskOptions(goal, l10n),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.mainTask,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              goal.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 8),
              Text(
                goal.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 进度条
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.completedHours.toStringAsFixed(1)}/${goal.totalHours} ${l10n.hours}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${goal.progressPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 统计
            Row(
              children: [
                _buildStatItem(Icons.local_fire_department_rounded, 
                    '${goal.streakDays} ${l10n.days}', l10n.streakDays),
                const SizedBox(width: 24),
                _buildStatItem(Icons.check_circle_outline_rounded,
                    '${goal.totalCompletedDays} ${l10n.days}', l10n.completedDays),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noGoals,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstGoal,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
