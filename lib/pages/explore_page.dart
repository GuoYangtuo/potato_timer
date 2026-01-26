import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/goal.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/widgets/goal_card.dart';
import 'package:potato_timer/widgets/motivation_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Goal> _goals = [];
  List<Motivation> _motivations = [];
  bool _isLoadingGoals = true;
  bool _isLoadingMotivations = true;
  String? _motivationType;

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
    _loadGoals();
    _loadMotivations();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoadingGoals = true);
    try {
      final goals = await ApiService().getPublicGoals();
      setState(() {
        _goals = goals;
        _isLoadingGoals = false;
      });
    } catch (e) {
      setState(() => _isLoadingGoals = false);
    }
  }

  Future<void> _loadMotivations() async {
    setState(() => _isLoadingMotivations = true);
    try {
      final motivations = await ApiService().getPublicMotivations(
        type: _motivationType,
      );
      setState(() {
        _motivations = motivations;
        _isLoadingMotivations = false;
      });
    } catch (e) {
      setState(() => _isLoadingMotivations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Text(
                    l10n.explore,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
                  Tab(text: l10n.exploreMotivations),
                  Tab(text: l10n.exploreGoals),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMotivationsTab(l10n),
                  _buildGoalsTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationsTab(AppLocalizations l10n) {
    return Column(
      children: [
        // 筛选器
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildFilterChip(
                label: l10n.all,
                isSelected: _motivationType == null,
                onTap: () {
                  setState(() => _motivationType = null);
                  _loadMotivations();
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: l10n.positive,
                isSelected: _motivationType == 'positive',
                onTap: () {
                  setState(() => _motivationType = 'positive');
                  _loadMotivations();
                },
                color: AppTheme.positiveColor,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: l10n.negative,
                isSelected: _motivationType == 'negative',
                onTap: () {
                  setState(() => _motivationType = 'negative');
                  _loadMotivations();
                },
                color: AppTheme.negativeColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 列表
        Expanded(
          child: _isLoadingMotivations
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : _motivations.isEmpty
                  ? _buildEmptyView(l10n.noPublicContent)
                  : RefreshIndicator(
                      onRefresh: _loadMotivations,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _motivations.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MotivationCard(
                              motivation: _motivations[index],
                              onTap: () {
                                // TODO: 打开详情
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildGoalsTab(AppLocalizations l10n) {
    return _isLoadingGoals
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          )
        : _goals.isEmpty
            ? _buildEmptyView(l10n.noPublicContent)
            : RefreshIndicator(
                onRefresh: _loadGoals,
                color: AppTheme.primaryColor,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    return GoalPreviewCard(goal: _goals[index]);
                  },
                ),
              );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

