import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/theme/app_theme.dart';

class CalmPage extends StatefulWidget {
  const CalmPage({super.key});

  @override
  State<CalmPage> createState() => _CalmPageState();
}

class _CalmPageState extends State<CalmPage> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _fadeController;
  late Animation<double> _breathAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _timer;
  int _remainingSeconds = 5 * 60; // 5分钟
  bool _isBreathing = true;
  String _breathPhase = 'inhale';

  final List<String> _calmQuotes = [
    '让心静下来，一切自然清晰',
    '此刻只需要存在，不需要做任何事',
    '深呼吸，感受当下',
    '放空大脑，让思绪沉淀',
    '静止是为了更好的出发',
    '专注于呼吸，其他都会过去',
    '你比你想象的更有力量',
    '平静的心灵是最强大的武器',
  ];

  late String _currentQuote;

  @override
  void initState() {
    super.initState();

    _currentQuote = _calmQuotes[Random().nextInt(_calmQuotes.length)];

    // 呼吸动画
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _breathPhase = 'exhale');
        _breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _breathPhase = 'inhale');
        _breathController.forward();
      }
    });

    // 淡入动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _breathController.forward();

    // 倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _onComplete();
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _fadeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onComplete() {
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
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                size: 48,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '冷静完成',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '现在心态平和了，去完成目标吧！',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
              child: const Text('开始'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Stack(
            children: [
              // 背景装饰
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarsPainter(),
                ),
              ),

              // 主要内容
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 提示文字
                    Text(
                      l10n.calmModeDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // 呼吸圆圈
                    AnimatedBuilder(
                      animation: _breathAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200 * _breathAnimation.value,
                          height: 200 * _breathAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.accentColor.withOpacity(0.3),
                                AppTheme.accentColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _breathPhase == 'inhale' ? '吸气' : '呼气',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // 倒计时
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontFamily: 'monospace',
                        letterSpacing: 8,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 引言
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _currentQuote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 顶部返回按钮
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // 跳过按钮
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

// 星空背景画笔
class _StarsPainter extends CustomPainter {
  final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 100; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 1.5 + 0.5;
      final opacity = _random.nextDouble() * 0.5 + 0.2;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

