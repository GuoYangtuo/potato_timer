// 离线优先服务使用示例
// 本文件展示如何在页面中使用 OfflineFirstService

import 'package:flutter/material.dart';
import '../models/motivation.dart';
import '../models/goal.dart';
import '../services/offline_first_service.dart';
import '../services/sync_service.dart';

/// 示例页面：展示如何使用离线优先服务
class OfflineUsageExamplePage extends StatefulWidget {
  const OfflineUsageExamplePage({super.key});

  @override
  State<OfflineUsageExamplePage> createState() => _OfflineUsageExamplePageState();
}

class _OfflineUsageExamplePageState extends State<OfflineUsageExamplePage> {
  final _offlineService = OfflineFirstService();
  
  List<Motivation> _motivations = [];
  List<Goal> _goals = [];
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToSync();
  }

  /// 监听同步状态
  void _listenToSync() {
    _offlineService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() => _syncStatus = status);
      }
    });
  }

  /// 加载数据（离线优先）
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 并行加载激励和目标
    final results = await Future.wait([
      _offlineService.getMyMotivations(),
      _offlineService.getMyGoals(),
    ]);
    
    setState(() {
      _motivations = results[0] as List<Motivation>;
      _goals = results[1] as List<Goal>;
      _isLoading = false;
    });
  }

  /// 创建新激励（离线支持）
  Future<void> _createMotivation() async {
    try {
      final id = await _offlineService.createMotivation(
        title: '新的激励 - ${DateTime.now().toIso8601String()}',
        content: '这是一个测试激励，即使离线也能创建',
        type: 'positive',
        isPublic: false,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建成功！本地ID: $id')),
        );
      }
      
      // 刷新列表
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  /// 创建新目标（离线支持）
  Future<void> _createGoal() async {
    try {
      final id = await _offlineService.createGoal(
        title: '新目标 - ${DateTime.now().hour}:${DateTime.now().minute}',
        description: '这是一个离线创建的目标',
        type: 'habit',
        enableTimer: true,
        durationMinutes: 10,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('目标创建成功！本地ID: $id')),
        );
      }
      
      // 刷新列表
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  /// 更新激励（离线支持）
  Future<void> _updateMotivation(int id) async {
    try {
      await _offlineService.updateMotivation(id, {
        'title': '已更新 - ${DateTime.now().toIso8601String()}',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新成功！')),
        );
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  /// 删除激励（离线支持）
  Future<void> _deleteMotivation(int id) async {
    try {
      await _offlineService.deleteMotivation(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功！')),
        );
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 完成目标（离线支持）
  Future<void> _completeGoal(int id) async {
    try {
      await _offlineService.completeGoal(
        id,
        durationMinutes: 10,
        notes: '离线完成',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标已完成！')),
        );
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成失败: $e')),
        );
      }
    }
  }

  /// 手动触发同步
  Future<void> _manualSync() async {
    final result = await _offlineService.manualSync();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      
      if (result.success) {
        await _loadData();
      }
    }
  }

  /// 获取同步状态图标
  Widget _getSyncStatusIcon() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case SyncStatus.idle:
        return const Icon(Icons.cloud_done, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线功能示例'),
        actions: [
          // 同步状态指示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _getSyncStatusIcon(),
          ),
          // 手动同步按钮
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncStatus == SyncStatus.syncing ? null : _manualSync,
            tooltip: '手动同步',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 提示信息
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '离线功能说明',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 所有数据都存储在本地，离线也能使用\n'
                            '• 联网时会自动同步到服务器\n'
                            '• 可以手动点击同步按钮立即同步\n'
                            '• 网络状态：${_offlineService.isLoggedIn ? "在线" : "离线"}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 激励列表
                  _buildSection(
                    title: '我的激励 (${_motivations.length})',
                    onAdd: _createMotivation,
                    children: _motivations.map((m) {
                      return ListTile(
                        title: Text(m.title ?? '无标题'),
                        subtitle: Text(
                          '创建于: ${m.createdAt.toLocal().toString().split('.')[0]}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _updateMotivation(m.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteMotivation(m.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 目标列表
                  _buildSection(
                    title: '我的目标 (${_goals.length})',
                    onAdd: _createGoal,
                    children: _goals.map((g) {
                      return ListTile(
                        title: Text(g.title),
                        subtitle: Text(
                          '${g.type == GoalType.habit ? "微习惯" : "主线任务"} • '
                          '完成 ${g.totalCompletedDays} 天',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => _completeGoal(g.id),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加'),
                ),
              ],
            ),
          ),
          if (children.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// ==================== 在现有页面中的集成示例 ====================

/// 示例1：在激励页面中获取数据
class MotivationListExample extends StatefulWidget {
  const MotivationListExample({super.key});

  @override
  State<MotivationListExample> createState() => _MotivationListExampleState();
}

class _MotivationListExampleState extends State<MotivationListExample> {
  final _service = OfflineFirstService();
  List<Motivation> _motivations = [];

  @override
  void initState() {
    super.initState();
    _loadMotivations();
  }

  Future<void> _loadMotivations() async {
    // 离线优先：立即返回本地数据，后台自动更新
    final motivations = await _service.getMyMotivations(type: 'positive');
    setState(() => _motivations = motivations);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _motivations.length,
      itemBuilder: (context, index) {
        final motivation = _motivations[index];
        return ListTile(
          title: Text(motivation.title ?? ''),
          subtitle: Text(motivation.content ?? ''),
        );
      },
    );
  }
}

/// 示例2：在目标页面中创建目标
class CreateGoalExample extends StatelessWidget {
  const CreateGoalExample({super.key});

  Future<void> _handleCreate(BuildContext context) async {
    final service = OfflineFirstService();
    
    try {
      // 即使离线也能创建，会标记为待同步
      final id = await service.createGoal(
        title: '每天锻炼10分钟',
        type: 'habit',
        enableTimer: true,
        durationMinutes: 10,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('目标创建成功，ID: $id')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleCreate(context),
      child: const Text('创建目标'),
    );
  }
}

