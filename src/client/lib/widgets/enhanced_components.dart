import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// PolyVault 增强功能组件库
/// 包含各种高级UI组件和交互反馈

/// 带加载状态的按钮
class LoadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? elevation;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    final effectiveBorderRadius = widget.borderRadius ?? AppRadius.md;
    final effectiveElevation = widget.elevation ?? 2;

    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? AppColors.primaryLight.withOpacity(0.15)
                : AppColors.primary),
        foregroundColor: widget.foregroundColor ?? Colors.white,
        padding: effectivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        elevation: effectiveElevation,
        animationDuration: AppAnimations.medium,
      ),
      child: widget.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.foregroundColor ??
                    (theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.white)),
              ),
            )
          : widget.child,
    );
  }
}

/// 带动画的卡片切换器
class AnimatedCardSwitcher extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double? width;
  final double? height;
  final bool isFlipped;
  final void Function() onFlip;

  const AnimatedCardSwitcher({
    super.key,
    required this.front,
    required this.back,
    this.width,
    this.height,
    this.isFlipped = false,
    required this.onFlip,
  });

  @override
  State<AnimatedCardSwitcher> createState() => _AnimatedCardSwitcherState();
}

class _AnimatedCardSwitcherState extends State<AnimatedCardSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // 根据初始状态设置动画
    if (widget.isFlipped) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCardSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    widget.onFlip();
    if (widget.isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: Transform.rotate(
        angle: _animation.value * pi,
        alignment: Alignment.center,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppColors.mediumShadow,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_animation.value < 0.5) widget.front,
              if (_animation.value > 0.5) widget.back,
            ],
          ),
        ),
      ),
    );
  }
}

/// 功能提示卡片
class FeatureHighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FeatureHighlightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.color,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color ?? theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (color ?? theme.colorScheme.primary).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: color ?? theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color ?? theme.colorScheme.primary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

/// 密码强度指示器
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showStrengthText;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showStrengthText = true,
  });

  PasswordStrength _calculateStrength() {
    int score = 0;
    
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) score += 1;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculateStrength();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStrengthText) ...[
          Row(
            children: [
              Text(
                _getStrengthLabel(strength),
                style: TextStyle(
                  color: _getStrengthColor(strength, theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isStrengthMet(strength, i)
                        ? _getStrengthColor(strength, theme)
                        : AppColors.textMutedLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  PasswordStrength _calculateStrength() {
    int score = 0;
    
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) score += 1;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  String _getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中等';
      case PasswordStrength.strong:
        return '强';
    }
  }

  Color _getStrengthColor(PasswordStrength strength, dynamic theme) {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  bool _isStrengthMet(PasswordStrength strength, int index) {
   switch (strength) {
      case PasswordStrength.weak:
        return index == 0;
      case PasswordStrength.medium:
        return index < 2;
      case PasswordStrength.strong:
        return index < 3;
    }
  }
}

/// 密码强度枚举
enum PasswordStrength { weak, medium, strong }

/// 向导组件
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
}

class OnboardingView extends StatefulWidget {
  final List<OnboardingStep> steps;
  final void Function()? onComplete;

  const OnboardingView({
    super.key,
    required this.steps,
    this.onComplete,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < widget.steps.length - 1) {
      setState(() => _currentPage++);
    } else {
      widget.onComplete?.call();
    }
  }

  void _skip() {
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: widget.steps.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: (step.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          color: step.color ?? Theme.of(context).colorScheme.primary,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              top: Divider.createBorderSide(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 分页指示器
              Row(
                children: [
                  for (int i = 0; i < widget.steps.length; i++) ...[
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
              
              // 按钮
              LoadingButton(
                onPressed: _nextPage,
                child: Text(
                  _currentPage == widget.steps.length - 1 ? '完成' : '下一步',
                ),
              ),
              
              if (_currentPage > 0) ...[
                TextButton(
                  onPressed: _currentPage == widget.steps.length - 1 ? _skip : null,
                  child: Text('跳过'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 加载指示器集合
class Loaders {
  /// 圆形加载指示器
  static Widget circular({
    Color? color,
    double strokeWidth = 2,
  }) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? Theme.of(context).colorScheme.primary,
      ),
      strokeWidth: strokeWidth,
    );
  }

  /// 条形加载指示器
  static Widget linear({
    Color? color,
    double value,
  }) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: AppColors.textMutedLight.withOpacity(0.2),
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// 脉冲加载指示器
  static Widget pulse({
    Color? color,
    Size size = const Size(40, 40),
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  /// 骨架屏
  static Widget skeleton({
    double width = double.infinity,
    double height = 20,
    double? borderRadius,
  }) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.textMutedLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(borderRadius ?? 4),
        ),
      ),
    );
  }
}

/// 脉冲加载动画
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color color;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.color = AppColors.textMutedLight,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          opacity: (_animation.value < 0.5 ? _animation.value * 2 : (1 - _animation.value) * 2),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// 多状态按钮 (如 favorite button)
class MultiStateButton extends StatefulWidget {
  final List<MultiStateButtonConfig> states;
  final int initialState;
  final void Function(int)? onStateChanged;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;

  const MultiStateButton({
    super.key,
    required this.states,
    this.initialState = 0,
    this.onStateChanged,
    this.size,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<MultiStateButton> createState() => _MultiStateButtonState();
}

class MultiStateButtonConfig {
  final IconData icon;
  final String? tooltip;

  const MultiStateButtonConfig({
    required this.icon,
    this.tooltip,
  });
}

class _MultiStateButtonState extends State<MultiStateButton> {
  late int _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  void _handleTap() {
    final nextState = (_currentState + 1) % widget.states.length;
    setState(() => _currentState = nextState);
    widget.onStateChanged?.call(_currentState);
  }

  MultiStateButtonConfig get _currentConfig => widget.states[_currentState];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _currentConfig.tooltip,
      child: Container(
        width: widget.size ?? 48,
        height: widget.size ?? 48,
        decoration: BoxDecoration(
          color: (_currentState == widget.initialState 
              ? widget.inactiveColor ?? AppColors.textMutedLight
              : widget.activeColor ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            _currentConfig.icon,
            color: _currentState == widget.initialState
                ? widget.inactiveColor ?? AppColors.textMutedLight
                : widget.activeColor ?? Theme.of(context).colorScheme.primary,
          ),
          onPressed: _handleTap,
        ),
      ),
    );
  }
}
