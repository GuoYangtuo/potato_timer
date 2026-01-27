import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/services/offline_first_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/login_page.dart';
import 'package:potato_timer/pages/create_motivation_page.dart';
import 'package:potato_timer/widgets/motivation_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Motivation> _myMotivations = [];
  List<Motivation> _favorites = [];
  bool _isLoadingMotivations = true;
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadMyMotivations();
    _loadFavorites();
  }

  Future<void> _loadMyMotivations() async {
    setState(() => _isLoadingMotivations = true);
    try {
      // 使用离线优先服务
      final motivations = await OfflineFirstService().getMyMotivations();
      setState(() {
        _myMotivations = motivations;
        _isLoadingMotivations = false;
      });
    } catch (e) {
      setState(() => _isLoadingMotivations = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoadingFavorites = true);
    try {
      // 使用离线优先服务
      final favorites = await OfflineFirstService().getFavorites();
      setState(() {
        _favorites = favorites;
        _isLoadingFavorites = false;
      });
    } catch (e) {
      setState(() => _isLoadingFavorites = false);
    }
  }

  void _logout() async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ApiService().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _editMotivation(Motivation motivation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMotivationPage(editMotivation: motivation),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _deleteMotivation(Motivation motivation) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('删除激励'),
        content: const Text('确定要删除这个激励吗？此操作无法撤销。'),
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
        await OfflineFirstService().deleteMotivation(motivation.id);
        _loadData();
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

  Future<void> _toggleLike(Motivation motivation) async {
    try {
      if (motivation.isLiked) {
        await OfflineFirstService().unlikeMotivation(motivation.id);
      } else {
        await OfflineFirstService().likeMotivation(motivation.id);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Motivation motivation) async {
    try {
      if (motivation.isFavorited) {
        await OfflineFirstService().unfavoriteMotivation(motivation.id);
      } else {
        await OfflineFirstService().favoriteMotivation(motivation.id);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ApiService().currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 用户信息头部
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 头像
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nickname ?? '用户',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _maskPhone(user?.phoneNumber ?? ''),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 设置按钮
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 统计卡片
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(
                          value: _myMotivations.length.toString(),
                          label: l10n.totalMotivations,
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          value: _favorites.length.toString(),
                          label: l10n.favorites,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab 栏
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: l10n.myMotivations),
                  Tab(text: l10n.favorites),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab 内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMotivationsList(_myMotivations, _isLoadingMotivations, l10n),
                  _buildMotivationsList(_favorites, _isLoadingFavorites, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationsList(
    List<Motivation> motivations,
    bool isLoading,
    AppLocalizations l10n,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (motivations.isEmpty) {
      // 修复：空状态时也需要支持下拉刷新
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMotivations,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: motivations.length,
        itemBuilder: (context, index) {
          final motivation = motivations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MotivationCard(
              motivation: motivation,
              onTap: () {
                // TODO: 打开详情
              },
              onLike: () => _toggleLike(motivation),
              onFavorite: () => _toggleFavorite(motivation),
              onEdit: () => _editMotivation(motivation),
              onDelete: () => _deleteMotivation(motivation),
            ),
          );
        },
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}

