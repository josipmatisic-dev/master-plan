/// Shared weather test fixtures.
library;

/// Sample Open-Meteo Marine API response with hourly data for multi-point.
const String sampleWeatherResponse = '''
[
  {
    "latitude": 60.0,
    "longitude": 10.0,
    "current": {
      "wind_speed_10m": 12.5,
      "wind_direction_10m": 225.0,
      "wave_height": 1.8,
      "wave_direction": 180.0,
      "wave_period": 6.5
    },
    "hourly": {
      "time": [
        "2026-02-09T00:00",
        "2026-02-09T01:00",
        "2026-02-09T02:00",
        "2026-02-09T03:00",
        "2026-02-09T04:00",
        "2026-02-09T05:00"
      ],
      "wind_speed_10m": [10.0, 12.5, 14.0, 11.5, 9.0, 13.0],
      "wind_direction_10m": [220.0, 225.0, 230.0, 215.0, 210.0, 228.0],
      "wave_height": [1.5, 1.8, 2.1, 1.9, 1.6, 2.0],
      "wave_direction": [175.0, 180.0, 185.0, 178.0, 172.0, 182.0],
      "wave_period": [6.0, 6.5, 7.0, 6.8, 6.2, 6.9]
    }
  },
  {
    "latitude": 60.0,
    "longitude": 12.0,
    "current": {
      "wind_speed_10m": 11.0,
      "wind_direction_10m": 230.0,
      "wave_height": 1.7,
      "wave_direction": 185.0,
      "wave_period": 6.3
    },
    "hourly": {
      "time": [
        "2026-02-09T00:00",
        "2026-02-09T01:00",
        "2026-02-09T02:00",
        "2026-02-09T03:00",
        "2026-02-09T04:00",
        "2026-02-09T05:00"
      ],
      "wind_speed_10m": [9.5, 11.0, 13.0, 10.5, 8.5, 12.0],
      "wind_direction_10m": [225.0, 230.0, 235.0, 220.0, 215.0, 233.0],
      "wave_height": [1.4, 1.7, 2.0, 1.8, 1.5, 1.9],
      "wave_direction": [170.0, 175.0, 180.0, 173.0, 167.0, 177.0],
      "wave_period": [5.9, 6.3, 6.8, 6.6, 6.0, 6.8]
    }
  }
]
''';
