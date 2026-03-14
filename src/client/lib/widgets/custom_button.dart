import 'package:flutter/material.dart';

/// 自定义渐变按钮
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃拟态按钮
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 浮动操作按钮扩展
class ExpandableFab extends StatefulWidget {
  final List<Widget> children;
  final Widget icon;

  const ExpandableFab({
    super.key,
    required this.children,
    required this.icon,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // 展开的子按钮
          ..._buildExpandableButtons(),
          // 主按钮
          FloatingActionButton(
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: widget.icon,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandableButtons() {
    final children = <Widget>[];
    final count = widget.children.length;

    for (var i = 0; i < count; i++) {
      children.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final offset = _expandAnimation.value * (i + 1) * 70;
            return Positioned(
              right: 0,
              bottom: offset,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: widget.children[count - 1 - i],
              ),
            );
          },
        ),
      );
    }

    return children;
  }
}
