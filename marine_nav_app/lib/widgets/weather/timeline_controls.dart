/// Timeline Controls widget - alias for TimelineScrubber
///
/// This file provides a convenient re-export of TimelineScrubber
/// under the name TimelineControls for clarity about what the widget does.
///
/// Usage:
/// ```dart
/// // Option 1: Using TimelineControls (semantically clear)
/// import 'package:marine_nav_app/widgets/weather/timeline_controls.dart';
/// TimelineControls()
///
/// // Option 2: Using TimelineScrubber (original name)
/// import 'package:marine_nav_app/widgets/weather/timeline_scrubber.dart';
/// TimelineScrubber()
///
/// // Both refer to the same widget class
/// ```
library;

// Re-export TimelineScrubber as TimelineControls
export 'timeline_scrubber.dart' show TimelineScrubber;
