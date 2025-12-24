import 'dart:math';
import 'package:flutter/material.dart';

/// 雪花飘落动画效果
///
/// 轻量级实现，使用少量雪花粒子避免性能问题
class SnowfallEffect extends StatefulWidget {
  final Widget child;
  final int snowflakeCount;
  final bool enabled;

  const SnowfallEffect({
    super.key,
    required this.child,
    this.snowflakeCount = 30,
    this.enabled = true,
  });

  @override
  State<SnowfallEffect> createState() => _SnowfallEffectState();
}

class _SnowfallEffectState extends State<SnowfallEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Snowflake> _snowflakes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _snowflakes = List.generate(
      widget.snowflakeCount,
      (_) => _createSnowflake(),
    );
  }

  Snowflake _createSnowflake([double? startY]) {
    return Snowflake(
      x: _random.nextDouble(),
      y: startY ?? _random.nextDouble(),
      size: _random.nextDouble() * 3 + 2,
      speed: _random.nextDouble() * 0.3 + 0.1,
      wobble: _random.nextDouble() * 0.02,
      wobbleSpeed: _random.nextDouble() * 2 + 1,
      opacity: _random.nextDouble() * 0.5 + 0.3,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: SnowfallPainter(
                    snowflakes: _snowflakes,
                    time: DateTime.now().millisecondsSinceEpoch / 1000.0,
                    onUpdate: (index) {
                      // 雪花落到底部后重置到顶部
                      if (_snowflakes[index].y > 1.0) {
                        _snowflakes[index] = _createSnowflake(-0.05);
                      } else {
                        _snowflakes[index].y +=
                            _snowflakes[index].speed * 0.016;
                      }
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
}

/// 单个雪花的数据
class Snowflake {
  double x;
  double y;
  final double size;
  final double speed;
  final double wobble;
  final double wobbleSpeed;
  final double opacity;

  Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobble,
    required this.wobbleSpeed,
    required this.opacity,
  });
}

/// 雪花绘制器
class SnowfallPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final double time;
  final void Function(int index)? onUpdate;

  SnowfallPainter({
    required this.snowflakes,
    required this.time,
    this.onUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < snowflakes.length; i++) {
      final flake = snowflakes[i];

      // 计算水平摇摆
      final wobbleOffset = sin(time * flake.wobbleSpeed + i) * flake.wobble;
      final x = (flake.x + wobbleOffset) * size.width;
      final y = flake.y * size.height;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: flake.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), flake.size, paint);

      // 触发位置更新
      onUpdate?.call(i);
    }
  }

  @override
  bool shouldRepaint(SnowfallPainter oldDelegate) => true;
}

/// 圣诞徽章组件
class ChristmasBadge extends StatelessWidget {
  final double size;

  const ChristmasBadge({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC41E3A),
            const Color(0xFF8B0000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC41E3A).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '🎄',
        style: TextStyle(fontSize: size * 0.6),
      ),
    );
  }
}
