import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/motivation_page.dart';
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
    final api = ApiService();
    debugPrint('loadGoals - isLoggedIn: ${api.isLoggedIn}, token存在: ${api.isLoggedIn}');
    debugPrint('loadGoals - baseUrl: ${api.baseUrl}');
    setState(() => _isLoading = true);
    try {
      final goals = await api.getMyGoals();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ApiService().currentUser;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadGoals,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // 头部问候
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.nickname ?? l10n.welcome,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 主线任务卡片
              if (_mainTask != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好 ☀️';
    } else if (hour < 18) {
      return '下午好 🌤️';
    } else {
      return '晚上好 🌙';
    }
  }
}
