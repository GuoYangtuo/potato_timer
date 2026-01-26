import 'dart:async';
import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/services/notification_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/calm_page.dart';

class MotivationPage extends StatefulWidget {
  final int goalId;
  final bool fromNotification;

  const MotivationPage({
    super.key,
    required this.goalId,
    this.fromNotification = false,
  });

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  Goal? _goal;
  List<GoalMotivation> _motivations = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  // 计时器相关
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _isTimerCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getGoalMotivations(widget.goalId);
      final goalData = data['goal'] as Map<String, dynamic>;
      final motivationsData = data['motivations'] as List;

      setState(() {
        _goal = Goal(
          id: goalData['id'],
          title: goalData['title'],
          type: goalData['type'] == 'habit' ? GoalType.habit : GoalType.mainTask,
          enableTimer: _parseBool(goalData['enableTimer']),
          durationMinutes: goalData['durationMinutes'] ?? 10,
          sessionDurationMinutes: goalData['sessionDurationMinutes'] ?? 240,
          createdAt: DateTime.now(),
        );
        _motivations = motivationsData
            .map((m) => GoalMotivation.fromJson(m as Map<String, dynamic>))
            .toList();
        _isLoading = false;

        // 初始化计时器
        _initTimer();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  void _initTimer() {
    if (_goal == null) return;

    // 微习惯：根据是否启用计时器和fromNotification决定
    // 主线任务：始终启用计时器
    bool shouldStartTimer = false;

    if (_goal!.type == GoalType.mainTask) {
      _remainingSeconds = _goal!.sessionDurationMinutes * 60;
      shouldStartTimer = true;
    } else if (_goal!.enableTimer) {
      _remainingSeconds = _goal!.durationMinutes * 60;
      shouldStartTimer = true;
    }

    if (shouldStartTimer) {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isTimerCompleted = true;
    });

    // 显示完成提示
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.positiveGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.timerComplete,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.keepGoing,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeGoal();
              },
              child: Text(l10n.done),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeGoal() async {
    if (_goal == null) return;

    try {
      int durationMinutes;
      if (_goal!.type == GoalType.mainTask) {
        durationMinutes = _goal!.sessionDurationMinutes - (_remainingSeconds ~/ 60);
      } else if (_goal!.enableTimer) {
        durationMinutes = _goal!.durationMinutes - (_remainingSeconds ~/ 60);
      } else {
        durationMinutes = 0;
      }

      await ApiService().completeGoal(
        widget.goalId,
        durationMinutes: durationMinutes,
      );

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示已完成
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _postpone() async {
    final l10n = AppLocalizations.of(context);

    // 安排5分钟后的提醒
    await NotificationService().scheduleDelayedReminder(
      id: NotificationService.generateGoalNotificationId(widget.goalId, offset: 1),
      title: l10n.reminderTitle,
      body: l10n.format('postponeReminder', {'goal': _goal?.title ?? ''}),
      payload: NotificationService.createPayload('goal', widget.goalId),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已推迟，5分钟后将再次提醒')),
      );
      Navigator.pop(context);
    }
  }

  void _goToCalmPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalmPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_goal == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(),
        body: Center(child: Text(l10n.loadFailed)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 激励内容展示区
            if (_motivations.isNotEmpty)
              _buildMotivationContent()
            else
              _buildEmptyMotivation(l10n),

            // 顶部导航栏
            _buildTopBar(l10n),

            // 底部控制区
            _buildBottomControls(l10n),

            // 左右切换按钮
            if (_motivations.length > 1) ...[
              _buildNavigationButton(isLeft: true),
              _buildNavigationButton(isLeft: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationContent() {
    if (_motivations.isEmpty) return const SizedBox();

    final motivation = _motivations[_currentIndex];

    // 如果有媒体，优先显示媒体
    if (motivation.firstMediaUrl != null) {
      return Positioned.fill(
        child: motivation.firstMediaType == 'video'
            ? _buildVideoPlayer(motivation.firstMediaUrl!)
            : Image.network(
                motivation.firstMediaUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildTextContent(motivation);
                },
              ),
      );
    }

    // 否则显示文字内容
    return _buildTextContent(motivation);
  }

  Widget _buildVideoPlayer(String url) {
    // 简化处理，实际应使用video_player
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              '视频: $url',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(GoalMotivation motivation) {
    return Container(
      decoration: BoxDecoration(
        gradient: motivation.type == MotivationType.positive
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC62828), Color(0xFF8E0000)],
              ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (motivation.title != null) ...[
                Text(
                  motivation.title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (motivation.content != null)
                Text(
                  motivation.content!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMotivation(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noMotivations,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '为这个目标添加一些激励内容吧',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const Spacer(),
            // 目标标题
            Expanded(
              flex: 2,
              child: Text(
                _goal?.title ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            // 冷静模式按钮
            GestureDetector(
              onTap: _goToCalmPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.self_improvement_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.calmMode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(AppLocalizations l10n) {
    final showTimer = _goal!.type == GoalType.mainTask || _goal!.enableTimer;
    final canComplete = _goal!.type == GoalType.habit && 
        (!_goal!.enableTimer || _isTimerCompleted);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // 计时器显示
            if (showTimer) ...[
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.timeRemaining,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 页面指示器
            if (_motivations.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _motivations.length,
                  (index) => Container(
                    width: index == _currentIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 操作按钮
            Row(
              children: [
                // 推迟按钮
                Expanded(
                  child: OutlinedButton(
                    onPressed: _postpone,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Text(l10n.postpone),
                  ),
                ),
                const SizedBox(width: 12),
                // 完成按钮（微习惯不启用计时器或计时完成时显示）
                if (_goal!.type == GoalType.habit)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canComplete || !_goal!.enableTimer
                          ? _completeGoal
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.positiveColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(l10n.complete),
                    ),
                  ),
                // 暂停/继续按钮（计时时显示）
                if (showTimer && !_isTimerCompleted) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isTimerRunning ? _pauseTimer : _resumeTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Icon(
                        _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({required bool isLeft}) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isLeft) {
              _currentIndex = (_currentIndex - 1 + _motivations.length) % _motivations.length;
            } else {
              _currentIndex = (_currentIndex + 1) % _motivations.length;
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 80,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 解析 bool 值，兼容 MySQL 返回的 0/1 和 true/false
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

