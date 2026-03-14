import 'package:flutter/material.dart';

/// 带动画的连接状态指示器
class AnimatedConnectionIndicator extends StatefulWidget {
  final bool isConnected;
  final String? statusText;
  final VoidCallback? onTap;

  const AnimatedConnectionIndicator({
    super.key,
    required this.isConnected,
    this.statusText,
    this.onTap,
  });

  @override
  State<AnimatedConnectionIndicator> createState() => _AnimatedConnectionIndicatorState();
}

class _AnimatedConnectionIndicatorState extends State<AnimatedConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = widget.isConnected ? Colors.green : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 带动画的状态指示灯
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(
                            widget.isConnected ? 0.6 * _pulseAnimation.value : 0.3,
                          ),
                          blurRadius: widget.isConnected ? 8 * _pulseAnimation.value : 4,
                          spreadRadius: widget.isConnected ? 2 * _pulseAnimation.value : 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // 状态文字
              Text(
                widget.statusText ?? (widget.isConnected ? '已连接' : '未连接'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (widget.onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: statusColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 连接状态脉冲动画组件
class ConnectionPulse extends StatefulWidget {
  final bool isActive;
  final double size;
  final Color color;

  const ConnectionPulse({
    super.key,
    required this.isActive,
    this.size = 60,
    this.color = Colors.green,
  });

  @override
  State<ConnectionPulse> createState() => _ConnectionPulseState();
}

class _ConnectionPulseState extends State<ConnectionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外圈脉冲
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: widget.size * _scaleAnimation.value,
                  height: widget.size * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(_opacityAnimation.value * 0.3),
                  ),
                );
              },
            ),
          // 中心圆点
          Container(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备连接动画卡片
class AnimatedDeviceCard extends StatefulWidget {
  final String deviceName;
  final bool isConnected;
  final String? deviceType;
  final VoidCallback? onTap;

  const AnimatedDeviceCard({
    super.key,
    required this.deviceName,
    required this.isConnected,
    this.deviceType,
    this.onTap,
  });

  @override
  State<AnimatedDeviceCard> createState() => _AnimatedDeviceCardState();
}

class _AnimatedDeviceCardState extends State<AnimatedDeviceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 4).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Card(
            elevation: _elevationAnimation.value,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isConnected
                    ? Colors.green.withOpacity(0.3)
                    : colorScheme.outlineVariant.withOpacity(0.5),
                width: widget.isConnected ? 2 : 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 脉冲动画
                  ConnectionPulse(
                    isActive: widget.isConnected,
                    size: 50,
                    color: widget.isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  // 设备信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deviceName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.deviceType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.deviceType!,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 状态指示器
                  AnimatedConnectionIndicator(
                    isConnected: widget.isConnected,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
