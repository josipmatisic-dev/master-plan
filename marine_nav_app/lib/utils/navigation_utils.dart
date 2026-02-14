/// Navigation utility helpers shared across screens.
library;

/// Converts a compass bearing in degrees to a 16-point cardinal direction string.
///
/// Returns '--' if [degrees] is null.
String cardinalDirection(double? degrees) {
  if (degrees == null) return '--';
  const dirs = [
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW'
  ];
  return dirs[((degrees % 360) / 22.5).round() % 16];
}
