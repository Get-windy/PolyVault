import 'package:flutter/material.dart';

/// 增强动画效果集合

/// 1. 淡入滑动动画组件
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;
  final Duration delay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 30),
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 2. 缩放弹跳动画
class ScaleBounce extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;
  final double endScale;

  const ScaleBounce({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.beginScale = 0.5,
    this.endScale = 1.0,
  });

  @override
  State<ScaleBounce> createState() => _ScaleBounceState();
}

class _ScaleBounceState extends State<ScaleBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 3. 列表项交错动画
class StaggeredListAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: index * baseDelay.inMilliseconds),
      duration: const Duration(milliseconds: 400),
      offset: const Offset(30, 0),
      child: child,
    );
  }
}

/// 4. 脉冲光环动画
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  final Widget child;

  const PulseRing({
    super.key,
    required this.color,
    this.size = 60,
    required this.child,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.repeat();
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
          // 外圈
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size * _scaleAnimation.value,
                height: widget.size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(_opacityAnimation.value),
                ),
              );
            },
          ),
          // 中心内容
          widget.child,
        ],
      ),
    );
  }
}

/// 5. 成功动画（打勾动画）
class SuccessAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    this.color = Colors.green,
    this.size = 80,
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 3),
            ),
            child: Center(
              child: Icon(
                Icons.check,
                color: widget.color,
                size: widget.size * 0.6 * _checkAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 6. 滑动删除背景
class SwipeActionBackground extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const SwipeActionBackground({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 7. 状态切换动画
class AnimatedStatusToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const AnimatedStatusToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.activeIcon = Icons.link,
    this.inactiveIcon = Icons.link_off,
  });

  @override
  State<AnimatedStatusToggle> createState() => _AnimatedStatusToggleState();
}

class _AnimatedStatusToggleState extends State<AnimatedStatusToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.value) _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStatusToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged?.call(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: widget.value ? widget.activeColor : widget.inactiveColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: widget.value ? 28 : 4,
              top: 4,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.value ? widget.activeIcon : widget.inactiveIcon,
                    size: 14,
                    color: widget.value ? widget.activeColor : widget.inactiveColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. 按钮点击波纹效果
class RippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? rippleColor;
  final BorderRadius? borderRadius;

  const RippleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.rippleColor,
    this.borderRadius,
  });

  @override
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.95 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            color: _isPressed
                ? (widget.rippleColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.1))
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 9. 加载动画指示器
class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingDots({
    super.key,
    this.color = Colors.blue,
    this.size = 8,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1;
            final scale = (value < 0.5)
                ? 1 + (value * 2) * 0.5
                : 1 + (1 - (value - 0.5) * 2) * 0.5;
            final opacity = 0.5 + (scale - 1);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// 10. Hero过渡动画包装器
class HeroTransitionWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback? onTap;

  const HeroTransitionWrapper({
    super.key,
    required this.tag,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: tag,
        flightShuttleBuilder: (flightContext, animation, flightDirection,
            fromHeroContext, toHeroContext) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (animation.value * 0.05),
                child: Opacity(
                  opacity: Curves.easeInOut.transform(animation.value),
                  child: toHeroContext.widget,
                ),
              );
            },
          );
        },
        child: child,
      ),
    );
  }
}

/// 11. 滑动验证动画
class SlideToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color color;

  const SlideToConfirm({
    super.key,
    this.text = '滑动以确认',
    required this.onConfirm,
    this.color = Colors.green,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dragPosition = 0;
  final double _threshold = 0.8;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 56;
          return Stack(
            children: [
              // 背景文字
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1 - (_dragPosition / maxWidth),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // 滑动把手
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxWidth);
                      if (_dragPosition >= maxWidth * _threshold) {
                        widget.onConfirm();
                        _dragPosition = 0;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition < maxWidth * _threshold) {
                      setState(() => _dragPosition = 0);
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}