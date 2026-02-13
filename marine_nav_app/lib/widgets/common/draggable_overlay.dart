/// DraggableOverlay - Draggable + resizable overlay with persistence.
///
/// Self-manages position and scale via SharedPreferences.
/// Resize handle at bottom-right corner for scaling.
library;

import 'package:flutter/material.dart';

import '../../utils/overlay_layout_store.dart';

/// Makes any widget draggable and resizable within a Stack.
///
/// Position and scale are auto-persisted to SharedPreferences using [id].
/// On init, loads saved layout; falls back to [initialPosition]/[initialScale].
class DraggableOverlay extends StatefulWidget {
  /// Unique key for persistence (prefix with screen name, e.g. 'map_topBar').
  final String id;

  /// Default position when no saved layout exists.
  final Offset initialPosition;

  /// Default scale when no saved layout exists.
  final double initialScale;

  /// The child widget to make draggable.
  final Widget child;

  /// Whether drag-to-move is enabled.
  final bool draggable;

  /// Whether the resize handle is shown.
  final bool resizable;

  /// Minimum allowed scale factor.
  final double minScale;

  /// Maximum allowed scale factor.
  final double maxScale;

  /// Creates a draggable, resizable overlay widget.
  const DraggableOverlay({
    super.key,
    required this.id,
    required this.initialPosition,
    required this.child,
    this.initialScale = 1.0,
    this.draggable = true,
    this.resizable = true,
    this.minScale = 0.45,
    this.maxScale = 1.5,
  });

  @override
  State<DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<DraggableOverlay> {
  late Offset _position;
  late double _scale;
  bool _isDragging = false;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _scale = widget.initialScale;
    _loadSavedLayout();
  }

  Future<void> _loadSavedLayout() async {
    final layout = await OverlayLayoutStore.load(widget.id);
    if (!mounted) return;
    setState(() {
      if (layout.position != null) _position = layout.position!;
      if (layout.scale != null) {
        _scale = layout.scale!.clamp(widget.minScale, widget.maxScale);
      }
    });
  }

  Future<void> _saveLayout() =>
      OverlayLayoutStore.save(widget.id, _position, _scale);

  void _clampPosition(Size screen) {
    _position = Offset(
      _position.dx.clamp(-20, screen.width - 20),
      _position.dy.clamp(-20, screen.height - 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    _clampPosition(screen);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: widget.draggable
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                if (!_isResizing) setState(() => _isDragging = true);
              },
              onPanUpdate: (d) {
                if (_isResizing) return;
                setState(() {
                  _position += d.delta;
                  _clampPosition(screen);
                });
              },
              onPanEnd: (_) {
                if (_isResizing) return;
                setState(() => _isDragging = false);
                _saveLayout();
              },
              child: _buildContent(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return AnimatedOpacity(
      opacity: _isDragging || _isResizing ? 0.85 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Transform.scale(
        scale: _scale,
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (widget.resizable) _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      right: -2,
      bottom: -2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() => _isResizing = true),
        onPanUpdate: (d) {
          setState(() {
            final delta = (d.delta.dx + d.delta.dy) / 250;
            _scale = (_scale + delta).clamp(widget.minScale, widget.maxScale);
          });
        },
        onPanEnd: (_) {
          setState(() => _isResizing = false);
          _saveLayout();
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF00D9FF).withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.open_in_full,
            size: 16,
            color: Color(0xFF00D9FF),
          ),
        ),
      ),
    );
  }
}
