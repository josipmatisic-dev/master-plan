# Phase 4 Social & Community - Detailed Specifications

**Phase:** 4 - Social & Community  
**Purpose:** Backend, authentication, social features, launch prep  
**References:** [Phase 4 Plan](../plans/phase-4-social-community-plan.md)

## Supabase Backend

### Database Schema

**Users Table:**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Boats Table:**
```sql
CREATE TABLE boats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT,
  length_meters REAL,
  home_port TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Trips Table:**
```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  boat_id UUID REFERENCES boats(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  distance_nm REAL,
  track_data JSONB, -- GeoJSON LineString
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- PostGIS for spatial queries
CREATE INDEX idx_trips_track ON trips USING GIST ((track_data::geometry));
```

### Row-Level Security

```sql
-- Users can only see their own trips (unless public)
CREATE POLICY trips_select ON trips
  FOR SELECT
  USING (user_id = auth.uid() OR is_public = true);

-- Users can only insert their own trips
CREATE POLICY trips_insert ON trips
  FOR INSERT
  WITH CHECK (user_id = auth.uid());
```

## Authentication Flow

```dart
class AuthService {
  final SupabaseClient _supabase;
  
  Future<User> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    return response.user!;
  }
  
  Future<User> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user!;
  }
  
  Stream<AuthState> get authStateChanges => 
    _supabase.auth.onAuthStateChange;
}
```

## Trip Logging

### Automatic Trip Detection

```dart
class TripService {
  bool _isMoving = false;
  Trip? _currentTrip;
  
  void onPositionUpdate(BoatPosition position) {
    final isMovingNow = position.speed != null && position.speed! > 1.0; // >1 knot
    
    if (isMovingNow && !_isMoving) {
      // Start trip
      _startTrip();
    } else if (!isMovingNow && _isMoving) {
      // Stop trip after 5 min stationary
      _scheduleStopTrip();
    }
    
    if (_currentTrip != null) {
      _recordPosition(position);
    }
    
    _isMoving = isMovingNow;
  }
}
```

## GPX Export

```dart
String exportToGPX(Trip trip) {
  final gpx = GpxDocument();
  final track = GpxTrack();
  track.name = trip.name;
  
  final segment = GpxTrackSegment();
  for (final point in trip.points) {
    segment.points.add(GpxPoint(
      lat: point.latitude,
      lon: point.longitude,
      time: point.timestamp,
      ele: point.depth,
    ));
  }
  
  track.segments.add(segment);
  gpx.tracks.add(track);
  
  return gpx.toXmlString();
}
```

## Collaborative Features

### Real-Time Subscriptions

```dart
class RouteService {
  Stream<Route> watchRoute(String routeId) {
    return _supabase
      .from('routes')
      .stream(primaryKey: ['id'])
      .eq('id', routeId)
      .map((data) => Route.fromJson(data.first));
  }
  
  Future<void> updateRoute(Route route) async {
    await _supabase
      .from('routes')
      .update(route.toJson())
      .eq('id', route.id);
    // All subscribers notified automatically
  }
}
```

## Launch Checklist

- [ ] App store screenshots (6+ required for iOS)
- [ ] App description (max 4000 chars iOS, 4000 chars Android)
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support email
- [ ] App category selection
- [ ] Age rating completion
- [ ] Pricing and availability
- [ ] Test on production Supabase (not dev)
- [ ] Analytics configured
- [ ] Crash reporting tested
- [ ] Beta feedback addressed
- [ ] All P0/P1 bugs fixed

---

**For complete task breakdown, see:** [Phase 4 Plan](../plans/phase-4-social-community-plan.md)
