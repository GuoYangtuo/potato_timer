import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/theme/app_theme.dart';
import 'package:potato_timer/pages/create_goal_page.dart';
import 'package:potato_timer/pages/create_motivation_page.dart';

class InspirationPage extends StatelessWidget {
  const InspirationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inspiration,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // 创建目标卡片
              _buildCreationCard(
                context: context,
                icon: Icons.flag_rounded,
                title: l10n.createGoal,
                subtitle: '设定微习惯或主线任务，开始你的成长之旅',
                gradient: AppTheme.primaryGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGoalPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 创建激励内容卡片
              _buildCreationCard(
                context: context,
                icon: Icons.auto_awesome_rounded,
                title: l10n.createMotivation,
                subtitle: '记录那些激励你的经历和见闻',
                gradient: AppTheme.accentGradient,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateMotivationPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 提示卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.amber.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '小贴士',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '激励内容可以是让你向往的美好场景，也可以是不想重蹈覆辙的痛苦经历',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 底部装饰
              Center(
                child: Column(
                  children: [
                    Text(
                      '🥔',
                      style: TextStyle(
                        fontSize: 48,
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '成为更好的自己',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

