// ignore_for_file: avoid_classes_with_only_static_members

/// Persistence for draggable overlay positions and scales.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves and loads overlay widget layout (position + scale) via SharedPrefs.
class OverlayLayoutStore {
  static const _prefix = 'overlay_';

  /// Save position and scale for a widget.
  static Future<void> save(String id, Offset position, double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble('$_prefix${id}_x', position.dx),
      prefs.setDouble('$_prefix${id}_y', position.dy),
      prefs.setDouble('$_prefix${id}_scale', scale),
    ]);
  }

  /// Load saved position and scale. Returns nulls if nothing saved.
  static Future<({Offset? position, double? scale})> load(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('$_prefix${id}_x');
    final y = prefs.getDouble('$_prefix${id}_y');
    final scale = prefs.getDouble('$_prefix${id}_scale');
    return (
      position: (x != null && y != null) ? Offset(x, y) : null,
      scale: scale,
    );
  }

  /// Reset a single widget's layout.
  static Future<void> clear(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('$_prefix${id}_x'),
      prefs.remove('$_prefix${id}_y'),
      prefs.remove('$_prefix${id}_scale'),
    ]);
  }

  /// Reset all saved overlay layouts.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    await Future.wait(keys.map(prefs.remove));
  }
}
