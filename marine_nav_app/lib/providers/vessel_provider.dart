/// Vessel Provider — Layer 2
///
/// Manages the user's vessel profile (name, dimensions, MMSI, etc.).
/// Persists via CacheProvider. Used by VesselScreen and AIS
/// own-vessel identification.
library;

import 'package:flutter/foundation.dart';

import '../models/vessel_profile.dart';
import '../providers/cache_provider.dart';
import '../providers/settings_provider.dart';

/// Provider for vessel profile management.
class VesselProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final CacheProvider _cache;

  VesselProfile _profile = VesselProfile.empty;

  static const String _cacheKey = 'vessel_profile';

  /// Creates a vessel provider.
  VesselProvider({
    required SettingsProvider settingsProvider,
    required CacheProvider cacheProvider,
  })  : _settings = settingsProvider,
        _cache = cacheProvider;

  /// Current vessel profile.
  VesselProfile get profile => _profile;

  /// Whether a vessel profile has been configured.
  bool get isConfigured => _profile.isConfigured;

  /// Vessel name (shortcut).
  String get name => _profile.name;

  /// MMSI number (shortcut).
  int? get mmsi => _profile.mmsi;

  /// Initialize — load profile from cache.
  Future<void> init() async {
    final json = _cache.getJson(_cacheKey);
    if (json != null) {
      try {
        _profile = VesselProfile.fromJson(json);
        debugPrint('VesselProvider: Loaded profile "${_profile.name}"');
      } catch (e) {
        debugPrint('VesselProvider: Failed to load profile — $e');
      }
    }
    // Reserved for settings listener
    _settings.addListener(_onSettingsChanged);
  }

  /// Update the vessel profile.
  Future<void> updateProfile(VesselProfile profile) async {
    _profile = profile;
    await _persist();
    notifyListeners();
    debugPrint('VesselProvider: Updated profile "${profile.name}"');
  }

  /// Update a single field via copyWith.
  Future<void> updateField({
    String? name,
    String? type,
    int? mmsi,
    String? callSign,
    int? imo,
    String? flag,
    String? homePort,
    double? loaMeters,
    double? beamMeters,
    double? draftMeters,
    double? displacementKg,
    double? mastHeightMeters,
    String? engineModel,
    double? engineHours,
    double? fuelCapacityLiters,
    double? waterCapacityLiters,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      type: type,
      mmsi: mmsi,
      callSign: callSign,
      imo: imo,
      flag: flag,
      homePort: homePort,
      loaMeters: loaMeters,
      beamMeters: beamMeters,
      draftMeters: draftMeters,
      displacementKg: displacementKg,
      mastHeightMeters: mastHeightMeters,
      engineModel: engineModel,
      engineHours: engineHours,
      fuelCapacityLiters: fuelCapacityLiters,
      waterCapacityLiters: waterCapacityLiters,
    );
    await _persist();
    notifyListeners();
  }

  /// Update engine hours (common operation).
  Future<void> updateEngineHours(double hours) async {
    await updateField(engineHours: hours);
  }

  /// Clear the vessel profile.
  Future<void> clearProfile() async {
    _profile = VesselProfile.empty;
    await _cache.remove(_cacheKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _cache.put(_cacheKey, '');
    await _cache.putJson(_cacheKey, _profile.toJson());
  }

  void _onSettingsChanged() {
    // Reserved for unit preference changes
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
