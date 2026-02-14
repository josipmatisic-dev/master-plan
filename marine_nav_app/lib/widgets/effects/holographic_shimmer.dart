library;

/// A holographic shimmer overlay that sweeps an iridescent rainbow gradient
/// diagonally across its child widget on a smooth 4-second loop.
///
/// Designed for dark/cyberpunk themes — the effect is intentionally very subtle
/// (default 0.08 alpha) so it augments content without overwhelming it.
import 'package:flutter/material.dart';

/// Wraps [child] with an animated iridescent gradient overlay.
class HolographicShimmer extends StatefulWidget {
  /// The widget to apply the shimmer effect on top of.
  final Widget child;

  /// Whether the shimmer animation is active.
  final bool enabled;

  /// Opacity of the gradient overlay, clamped to 0.0–1.0.
  final double intensity;

  /// Creates a holographic shimmer effect around [child].
  const HolographicShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.intensity = 0.08,
  });

  @override
  State<HolographicShimmer> createState() => _HolographicShimmerState();
}

class _HolographicShimmerState extends State<HolographicShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(HolographicShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shift = _controller.value * 2.0;
          return Stack(
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.intensity.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + shift, -1.0 + shift),
                          end: Alignment(0.0 + shift, 1.0),
                          colors: const [
                            Color(0xFF00FFFF), // cyan
                            Color(0xFFFF00FF), // magenta
                            Color(0xFFFFFF00), // yellow
                            Color(0xFF00FFFF), // cyan
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                          tileMode: TileMode.mirror,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
