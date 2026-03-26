import 'package:flutter/material.dart';

/// PolyVault 动画效果组件
/// 提供各种进入、退出和状态变化的动画效果

/// 动画容器
class AnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final double? width;
  final double? height;
  final double? borderRadius;
  final BoxBorder? border;
  final BoxShadow? shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final void Function()? onEnd;

  const AnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.color,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.shadow,
    this.padding,
    this.margin,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        border: border,
        boxShadow: shadow != null ? [shadow!] : null,
      ),
      child: child,
    );
  }
}

/// 淡入动画 Widget
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;
  final Curve curve;
  final AlignmentGeometry alignment;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = 0.0,
    this.curve = Curves.easeOut,
    this.alignment = Alignment.center,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn>
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
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
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
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * _animation.value,
            alignment: widget.alignment,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 滑入动画 Widget
class SlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;
  final Curve curve;
  final Offset from;
  final Offset to;

  const SlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = 0.0,
    this.curve = Curves.easeOut,
    this.from = const Offset(0, 1),
    this.to = Offset.zero,
  });

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<Offset>(
      begin: widget.from,
      end: widget.to,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
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
        return Transform.translate(
          offset: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 缩放动画 Widget
class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;
  final Curve curve;
  final double from;
  final double to;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = 0.0,
    this.curve = Curves.elasticOut,
    this.from = 0.8,
    this.to = 1.0,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn>
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
      begin: widget.from,
      end: widget.to,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
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
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 弹跳动画 Widget
class BounceIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;
  final Curve curve;
  final double bounceHeight;

  const BounceIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = 0.0,
    this.curve = CurvesbounceOut,
    this.bounceHeight = 1.15,
  });

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
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
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
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
          scale: 1.0 - (1.0 - widget.bounceHeight) * _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 模态界面过渡动画
class ModalPageRoute<T> extends PageRoute<T> {
  final Widget builder;
  final bool maintainState;
  final bool fullscreenDialog;

  ModalPageRoute({
    required this.builder,
    this.maintainState = true,
    this.fullscreenDialog = false,
  });

  @override
  final String label;

  @override
  Color get barrierColor => Colors.black54;

  @override
  String get barrierLabel => 'Modal route';

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// 打开模态对话框
Future<T?> showModal<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  BoxConstraints? constraints,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Modal',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackButtonListener(
        onBackButtonPressed: () {
          Navigator.pop(context);
          return Future.value(false);
        },
        child: Center(
          child: useSafeArea
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: constraints ??
                        const BoxConstraints(
                          maxWidth: 400,
                        ),
                    child: child,
                  ),
                )
              : child,
        ),
      );
    },
  );
}
