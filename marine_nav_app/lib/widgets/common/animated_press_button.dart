/// Animated press button with scale-down + brightness flash on tap.
library;

import 'package:flutter/material.dart';

/// Wraps any child widget with a press animation (scale + brightness flash).
class AnimatedPressButton extends StatefulWidget {
  /// The child widget to wrap with press animation.
  final Widget child;

  /// The callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// The scale factor applied when the button is pressed.
  final double pressScale;

  /// Creates an [AnimatedPressButton].
  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressScale = 0.93,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _brightness;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _brightness = Tween(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        await _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: _brightness.value),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
