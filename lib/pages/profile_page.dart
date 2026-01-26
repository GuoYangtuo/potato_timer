import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/login_page.dart';
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
      final motivations = await ApiService().getMyMotivations();
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
      final favorites = await ApiService().getFavorites();
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
                      color: Colors.grey.shade50,
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
                color: Colors.grey.shade100,
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
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: motivations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MotivationCard(
              motivation: motivations[index],
              onTap: () {
                // TODO: 打开详情
              },
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

