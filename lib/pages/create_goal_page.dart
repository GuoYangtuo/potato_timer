import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/offline_first_service.dart';
import 'package:potato_timer/theme/app_theme.dart';

class CreateGoalPage extends StatefulWidget {
  final Goal? editGoal;

  const CreateGoalPage({super.key, this.editGoal});

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalHoursController = TextEditingController(text: '100');

  GoalType _goalType = GoalType.habit;
  bool _enableTimer = false;
  int _durationMinutes = 10;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _afternoonReminderTime = const TimeOfDay(hour: 14, minute: 0);
  int _sessionDurationMinutes = 240;
  bool _isPublic = false;
  
  List<Motivation> _myMotivations = [];
  List<int> _selectedMotivationIds = [];
  bool _isLoading = false;
  bool _isLoadingMotivations = true;

  @override
  void initState() {
    super.initState();
    _loadMotivations();
    
    if (widget.editGoal != null) {
      final goal = widget.editGoal!;
      _titleController.text = goal.title;
      _descriptionController.text = goal.description ?? '';
      _goalType = goal.type;
      _enableTimer = goal.enableTimer;
      _durationMinutes = goal.durationMinutes;
      _totalHoursController.text = goal.totalHours.toString();
      _sessionDurationMinutes = goal.sessionDurationMinutes;
      _isPublic = goal.isPublic;
      _selectedMotivationIds = goal.motivations.map((m) => m.id).toList();
      
      // 解析时间
      if (goal.reminderTime != null) {
        final parts = goal.reminderTime!.split(':');
        if (parts.length >= 2) {
          _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _totalHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadMotivations() async {
    try {
      // 使用离线优先服务，即使没网也能获取本地数据
      final motivations = await OfflineFirstService().getMyMotivations();
      setState(() {
        _myMotivations = motivations;
        _isLoadingMotivations = false;
      });
    } catch (e) {
      setState(() => _isLoadingMotivations = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 使用离线优先服务，即使离线也能立即保存
      final service = OfflineFirstService();
      
      if (widget.editGoal != null) {
        await service.updateGoal(widget.editGoal!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          'isPublic': _isPublic,
          'enableTimer': _enableTimer,
          'durationMinutes': _durationMinutes,
          'reminderTime': '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}:00',
          'totalHours': int.tryParse(_totalHoursController.text) ?? 100,
          'morningReminderTime': '${_morningReminderTime.hour.toString().padLeft(2, '0')}:${_morningReminderTime.minute.toString().padLeft(2, '0')}:00',
          'afternoonReminderTime': '${_afternoonReminderTime.hour.toString().padLeft(2, '0')}:${_afternoonReminderTime.minute.toString().padLeft(2, '0')}:00',
          'sessionDurationMinutes': _sessionDurationMinutes,
          'motivationIds': _selectedMotivationIds,
        });
      } else {
        await service.createGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          type: _goalType == GoalType.habit ? 'habit' : 'main_task',
          isPublic: _isPublic,
          enableTimer: _enableTimer,
          durationMinutes: _durationMinutes,
          reminderTime: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}:00',
          totalHours: int.tryParse(_totalHoursController.text) ?? 100,
          morningReminderTime: '${_morningReminderTime.hour.toString().padLeft(2, '0')}:${_morningReminderTime.minute.toString().padLeft(2, '0')}:00',
          afternoonReminderTime: '${_afternoonReminderTime.hour.toString().padLeft(2, '0')}:${_afternoonReminderTime.minute.toString().padLeft(2, '0')}:00',
          sessionDurationMinutes: _sessionDurationMinutes,
          motivationIds: _selectedMotivationIds,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(service.isLoggedIn ? '保存成功' : '已保存到本地，联网后自动同步'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
        debugPrint('保存失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.editGoal != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? l10n.editGoal : l10n.createGoal),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 目标类型选择（仅创建时显示）
            if (!isEditing) ...[
              Text(
                l10n.goalType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      type: GoalType.habit,
                      icon: Icons.repeat_rounded,
                      title: l10n.habit,
                      subtitle: '每日重复的小任务',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard(
                      type: GoalType.mainTask,
                      icon: Icons.flag_rounded,
                      title: l10n.mainTask,
                      subtitle: '长期大目标',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // 标题
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.goalTitle,
                hintText: _goalType == GoalType.habit 
                    ? '例如：每天锻炼10分钟' 
                    : '例如：学习Flutter开发',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入目标标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 描述
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.goalDescription,
                hintText: '添加一些描述...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 微习惯特有设置
            if (_goalType == GoalType.habit) ...[
              _buildSectionTitle('习惯设置'),
              const SizedBox(height: 12),
              
              // 提醒时间
              _buildTimePicker(
                label: l10n.reminderTime,
                time: _reminderTime,
                onChanged: (time) => setState(() => _reminderTime = time),
              ),
              const SizedBox(height: 16),

              // 是否启用计时器
              _buildSwitchTile(
                title: l10n.enableTimer,
                subtitle: '启用后需要完成计时才算完成',
                value: _enableTimer,
                onChanged: (v) => setState(() => _enableTimer = v),
              ),

              // 计时时长
              if (_enableTimer) ...[
                const SizedBox(height: 16),
                _buildDurationPicker(
                  label: l10n.duration,
                  minutes: _durationMinutes,
                  onChanged: (m) => setState(() => _durationMinutes = m),
                  options: const [5, 10, 15, 20, 30, 45, 60],
                ),
              ],
            ],

            // 主线任务特有设置
            if (_goalType == GoalType.mainTask) ...[
              _buildSectionTitle('任务设置'),
              const SizedBox(height: 12),

              // 预计总时长
              TextFormField(
                controller: _totalHoursController,
                decoration: InputDecoration(
                  labelText: l10n.totalHours,
                  suffixText: l10n.hours,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 上午提醒时间
              _buildTimePicker(
                label: l10n.morningReminder,
                time: _morningReminderTime,
                onChanged: (time) => setState(() => _morningReminderTime = time),
              ),
              const SizedBox(height: 16),

              // 下午提醒时间
              _buildTimePicker(
                label: l10n.afternoonReminder,
                time: _afternoonReminderTime,
                onChanged: (time) => setState(() => _afternoonReminderTime = time),
              ),
              const SizedBox(height: 16),

              // 单次计时时长
              _buildDurationPicker(
                label: l10n.sessionDuration,
                minutes: _sessionDurationMinutes,
                onChanged: (m) => setState(() => _sessionDurationMinutes = m),
                options: const [60, 90, 120, 180, 240, 300, 360],
                isHours: true,
              ),
            ],

            const SizedBox(height: 24),

            // 关联激励内容
            _buildSectionTitle(l10n.selectMotivations),
            const SizedBox(height: 12),
            _buildMotivationSelector(l10n),

            const SizedBox(height: 24),

            // 公开设置
            _buildSwitchTile(
              title: l10n.publicGoal,
              subtitle: '公开后其他用户可以看到',
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required GoalType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _goalType == type;

    return GestureDetector(
      onTap: () => setState(() => _goalType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker({
    required String label,
    required int minutes,
    required ValueChanged<int> onChanged,
    required List<int> options,
    bool isHours = false,
  }) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = minutes == option;
            final displayValue = isHours ? (option ~/ 60) : option;
            final unit = isHours ? l10n.hours : l10n.minutes;

            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$displayValue $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSelector(AppLocalizations l10n) {
    if (_isLoadingMotivations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_myMotivations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noMotivations,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '先去创建一些激励内容吧',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _myMotivations.map((m) {
        final isSelected = _selectedMotivationIds.contains(m.id);
        final color = m.type == MotivationType.positive
            ? AppTheme.positiveColor
            : AppTheme.negativeColor;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMotivationIds.remove(m.id);
              } else {
                _selectedMotivationIds.add(m.id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  m.type == MotivationType.positive
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_down_rounded,
                  size: 16,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    m.title ?? m.content ?? '激励内容',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_rounded, size: 16, color: color),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

