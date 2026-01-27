import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/pages/home_page.dart';
import 'package:potato_timer/pages/explore_page.dart';
import 'package:potato_timer/pages/inspiration_page.dart';
import 'package:potato_timer/pages/profile_page.dart';
import 'package:potato_timer/services/offline_first_service.dart';
import 'package:potato_timer/theme/app_theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _isInitialSyncing = false;
  
  // 使用 GlobalKey 来访问页面状态
  final GlobalKey<State<HomePage>> _homePageKey = GlobalKey<State<HomePage>>();
  final GlobalKey<State<ProfilePage>> _profilePageKey = GlobalKey<State<ProfilePage>>();
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 初始化页面列表
    _pages = [
      HomePage(key: _homePageKey),
      const ExplorePage(),
      const InspirationPage(),
      ProfilePage(key: _profilePageKey),
    ];
    _performInitialSync();
  }

  /// 进入应用时同步云端数据
  Future<void> _performInitialSync() async {
    final service = OfflineFirstService();
    
    // 只有登录状态才同步
    if (!service.isLoggedIn) return;
    
    setState(() => _isInitialSyncing = true);
    
    try {
      debugPrint('🔄 开始同步云端数据...');
      final result = await service.manualSync();
      
      if (result.success) {
        debugPrint('✅ 云端数据同步完成');
      } else {
        debugPrint('⚠️ 同步完成但有警告: ${result.message}');
      }
    } catch (e) {
      debugPrint('❌ 云端数据同步失败: $e');
      // 同步失败不影响使用，继续使用本地数据
    } finally {
      if (mounted) {
        setState(() => _isInitialSyncing = false);
      }
    }
  }

  /// 切换标签时刷新页面数据
  void _refreshPageOnSwitch(int index) {
    // 切换到首页时刷新
    if (index == 0) {
      final state = _homePageKey.currentState;
      if (state != null && state.mounted) {
        (state as dynamic).refresh();
      }
    }
    // 切换到我的页面时刷新
    else if (index == 3) {
      final state = _profilePageKey.currentState;
      if (state != null && state.mounted) {
        (state as dynamic).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // 同步进度指示器
          if (_isInitialSyncing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '正在同步云端数据...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, l10n.home),
                _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, l10n.explore),
                _buildNavItem(2, Icons.lightbulb_rounded, Icons.lightbulb_outline, l10n.inspiration),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline, l10n.profile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
          // 切换到首页或我的页面时刷新数据
          _refreshPageOnSwitch(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
