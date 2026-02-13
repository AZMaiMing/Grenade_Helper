import 'dart:math';
import 'package:flutter/material.dart';

/// 烟花粒子特效
class FireworksEffect extends StatefulWidget {
  final Widget child;
  final int maxFireworks;
  final bool enabled;

  const FireworksEffect({
    super.key,
    required this.child,
    this.maxFireworks = 4,
    this.enabled = true,
  });

  @override
  State<FireworksEffect> createState() => _FireworksEffectState();
}

class _FireworksEffectState extends State<FireworksEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firework> _fireworks = [];
  final Random _random = Random();
  double _lastTime = 0;
  double _nextSpawnTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _lastTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _nextSpawnTime = _lastTime + _random.nextDouble() * 1.5 + 0.5;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(double now) {
    final dt = (now - _lastTime).clamp(0.0, 0.05);
    _lastTime = now;

    // 生成新烟花
    if (now >= _nextSpawnTime && _fireworks.length < widget.maxFireworks) {
      _fireworks.add(_createFirework());
      _nextSpawnTime = now + _random.nextDouble() * 2.0 + 1.0;
    }

    // 更新所有烟花
    for (final fw in _fireworks) {
      _updateFirework(fw, dt);
    }

    // 移除已完成的烟花
    _fireworks.removeWhere((fw) => fw.phase == FireworkPhase.done);
  }

  Firework _createFirework() {
    final x = _random.nextDouble() * 0.6 + 0.2;
    final targetY = _random.nextDouble() * 0.25 + 0.1;
    final color = _festiveColors[_random.nextInt(_festiveColors.length)];

    return Firework(
      x: x,
      y: 1.0,
      targetY: targetY,
      speed: _random.nextDouble() * 0.4 + 0.6,
      color: color,
      phase: FireworkPhase.rising,
      particles: [],
      trailOpacity: 1.0,
    );
  }

  void _updateFirework(Firework fw, double dt) {
    switch (fw.phase) {
      case FireworkPhase.rising:
        fw.y -= fw.speed * dt;
        fw.trailOpacity = (fw.trailOpacity - dt * 0.5).clamp(0.5, 1.0);
        if (fw.y <= fw.targetY) {
          fw.phase = FireworkPhase.exploding;
          _spawnParticles(fw);
        }
        break;
      case FireworkPhase.exploding:
        for (final p in fw.particles) {
          p.x += p.vx * dt;
          p.y += p.vy * dt;
          p.vy += 0.8 * dt; // 重力
          p.life -= dt * 0.6;
        }
        fw.particles.removeWhere((p) => p.life <= 0);
        if (fw.particles.isEmpty) {
          fw.phase = FireworkPhase.done;
        }
        break;
      case FireworkPhase.done:
        break;
    }
  }

  void _spawnParticles(Firework fw) {
    final count = _random.nextInt(15) + 20;
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 0.4 + 0.15;
      final color = _random.nextDouble() > 0.3
          ? fw.color
          : _festiveColors[_random.nextInt(_festiveColors.length)];

      fw.particles.add(FireworkParticle(
        x: fw.x,
        y: fw.y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 0.1,
        color: color,
        size: _random.nextDouble() * 2.5 + 1.0,
        life: _random.nextDouble() * 0.5 + 0.8,
      ));
    }
  }

  static const _festiveColors = [
    Color(0xFFFF2D2D), // 红
    Color(0xFFFFD700), // 金
    Color(0xFFFF6B6B), // 浅红
    Color(0xFFFF8C00), // 橙金
    Color(0xFFFFE44D), // 亮金
    Color(0xFFFF4500), // 橘红
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
                _update(now);
                return CustomPaint(
                  painter: _FireworksPainter(fireworks: _fireworks),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

enum FireworkPhase { rising, exploding, done }

class Firework {
  double x, y;
  final double targetY;
  final double speed;
  final Color color;
  FireworkPhase phase;
  final List<FireworkParticle> particles;
  double trailOpacity;

  Firework({
    required this.x,
    required this.y,
    required this.targetY,
    required this.speed,
    required this.color,
    required this.phase,
    required this.particles,
    required this.trailOpacity,
  });
}

class FireworkParticle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double life;

  FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });
}

class _FireworksPainter extends CustomPainter {
  final List<Firework> fireworks;

  _FireworksPainter({required this.fireworks});

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      if (fw.phase == FireworkPhase.rising) {
        _drawRisingTrail(canvas, size, fw);
      } else if (fw.phase == FireworkPhase.exploding) {
        _drawParticles(canvas, size, fw);
      }
    }
  }

  void _drawRisingTrail(Canvas canvas, Size size, Firework fw) {
    final x = fw.x * size.width;
    final y = fw.y * size.height;

    // 发光尾迹
    final glowPaint = Paint()
      ..color = fw.color.withValues(alpha: fw.trailOpacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(x, y), 3, glowPaint);

    // 核心亮点
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: fw.trailOpacity * 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 1.5, corePaint);
  }

  void _drawParticles(Canvas canvas, Size size, Firework fw) {
    for (final p in fw.particles) {
      final x = p.x * size.width;
      final y = p.y * size.height;
      final alpha = p.life.clamp(0.0, 1.0);

      // 发光
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), p.size * 1.5, glowPaint);

      // 粒子本体
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) => true;
}

/// 春节徽章
class SpringFestivalBadge extends StatelessWidget {
  final double size;
  const SpringFestivalBadge({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD72B2B), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD72B2B).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text('🧨', style: TextStyle(fontSize: size * 0.6)),
    );
  }
}
