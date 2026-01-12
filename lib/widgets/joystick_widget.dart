import 'dart:async';
import 'package:flutter/material.dart';

/// 摇杆组件
class JoystickBottomSheet extends StatefulWidget {
  /// 透明度
  final double opacity;

  /// 速度档位
  final int speedLevel;

  /// 方向回调
  final Function(Offset direction) onMove;

  /// 确认回调
  final VoidCallback onConfirm;

  /// 取消回调
  final VoidCallback onCancel;

  /// 标点名称
  final String? clusterName;

  const JoystickBottomSheet({
    super.key,
    required this.opacity,
    required this.speedLevel,
    required this.onMove,
    required this.onConfirm,
    required this.onCancel,
    this.clusterName,
  });

  @override
  State<JoystickBottomSheet> createState() => _JoystickBottomSheetState();
}

class _JoystickBottomSheetState extends State<JoystickBottomSheet> {
  Offset _knobPosition = Offset.zero;
  Timer? _moveTimer;

  // 尺寸
  static const double _baseRadius = 60.0;
  static const double _knobRadius = 25.0;

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    // 定时器
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_knobPosition == Offset.zero) return;

      final maxDistance = _baseRadius - _knobRadius;
      // 标准化向量
      final normalizedDirection = Offset(
        _knobPosition.dx / maxDistance,
        _knobPosition.dy / maxDistance,
      );

      // 触发回调
      if (normalizedDirection.distance > 0.1) {
        widget.onMove(normalizedDirection);
      }
    });
  }

  void _stopTimer() {
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2126).withValues(alpha: widget.opacity),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gamepad,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.clusterName != null
                            ? '移动: ${widget.clusterName}'
                            : '摇杆移动',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '速度: ${widget.speedLevel}档',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 摇杆区域
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 摇杆
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: _baseRadius * 2,
                      height: _baseRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 方向指示线
                          ..._buildDirectionLines(),
                          // 中心点
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[600],
                            ),
                          ),
                          // 摇杆把手
                          Transform.translate(
                            offset: _knobPosition,
                            child: Container(
                              width: _knobRadius * 2,
                              height: _knobRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[700], // 纯灰色
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.control_camera,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '按住拖动持续移动',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 20),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.grey.withValues(alpha: widget.opacity),
                        side: BorderSide(
                          color: Colors.grey[600]!
                              .withValues(alpha: widget.opacity),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: widget.opacity),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: widget.opacity),
                        foregroundColor:
                            Colors.white.withValues(alpha: widget.opacity),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '确认',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: widget.opacity),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDirectionLines() {
    return [
      // 上
      Positioned(
        top: 8,
        child: Icon(Icons.arrow_drop_up, color: Colors.grey[700], size: 20),
      ),
      // 下
      Positioned(
        bottom: 8,
        child: Icon(Icons.arrow_drop_down, color: Colors.grey[700], size: 20),
      ),
      // 左
      Positioned(
        left: 8,
        child: Icon(Icons.arrow_left, color: Colors.grey[700], size: 20),
      ),
      // 右
      Positioned(
        right: 8,
        child: Icon(Icons.arrow_right, color: Colors.grey[700], size: 20),
      ),
    ];
  }

  void _onPanStart(DragStartDetails details) {
    _startTimer(); // 开始移动
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final newPosition = _knobPosition + details.delta;
    final distance = newPosition.distance;
    final maxDistance = _baseRadius - _knobRadius;

    setState(() {
      if (distance <= maxDistance) {
        _knobPosition = newPosition;
      } else {
        // 限制在圆形范围内
        _knobPosition = Offset.fromDirection(
          newPosition.direction,
          maxDistance,
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _stopTimer(); // 停止移动
    setState(() {
      _knobPosition = Offset.zero;
    });
  }
}

/// 显示摇杆
Future<void> showJoystickBottomSheet({
  required BuildContext context,
  required double opacity,
  required int speedLevel,
  required Function(Offset direction) onMove,
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
  String? clusterName,
  Color barrierColor = Colors.black54, // 遮罩颜色
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => JoystickBottomSheet(
      opacity: opacity,
      speedLevel: speedLevel,
      onMove: onMove,
      onConfirm: () {
        Navigator.pop(ctx);
        onConfirm();
      },
      onCancel: () {
        Navigator.pop(ctx);
        onCancel();
      },
      clusterName: clusterName,
    ),
  );
}
