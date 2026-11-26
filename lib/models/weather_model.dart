/// Model data cuaca terkini dari objek `current` Open-Meteo Forecast API.
class CurrentWeather {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;
  final bool isDay;

  const CurrentWeather({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: (json['time'] as String?) ?? '',
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}

/// Model data perkiraan cuaca harian dari objek `daily` Open-Meteo Forecast API.
class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
  });
}

/// Model utama respons cuaca Open-Meteo Forecast API.
class WeatherModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  const WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.daily,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>?;
    if (currentJson == null) {
      throw const FormatException('Data cuaca terkini (current) tidak tersedia.');
    }

    final dailyJson = json['daily'] as Map<String, dynamic>?;
    final List<DailyForecast> dailyList = [];

    if (dailyJson != null) {
      final times = (dailyJson['time'] as List<dynamic>?) ?? const [];
      final weatherCodes =
          (dailyJson['weather_code'] as List<dynamic>?) ?? const [];
      final maxTemps =
          (dailyJson['temperature_2m_max'] as List<dynamic>?) ?? const [];
      final minTemps =
          (dailyJson['temperature_2m_min'] as List<dynamic>?) ?? const [];
      final precipProbs =
          (dailyJson['precipitation_probability_max'] as List<dynamic>?) ??
              const [];

      final count = times.length;
      for (var i = 0; i < count; i++) {
        final dateStr = times[i] as String?;
        if (dateStr == null) continue;

        dailyList.add(
          DailyForecast(
            date: DateTime.tryParse(dateStr) ?? DateTime.now(),
            weatherCode: i < weatherCodes.length && weatherCodes[i] != null
                ? (weatherCodes[i] as num).toInt()
                : 0,
            temperature2mMax: i < maxTemps.length && maxTemps[i] != null
                ? (maxTemps[i] as num).toDouble()
                : 0.0,
            temperature2mMin: i < minTemps.length && minTemps[i] != null
                ? (minTemps[i] as num).toDouble()
                : 0.0,
            precipitationProbabilityMax:
                i < precipProbs.length && precipProbs[i] != null
                    ? (precipProbs[i] as num).toInt()
                    : 0,
          ),
        );
      }
    }

    return WeatherModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? 'auto',
      current: CurrentWeather.fromJson(currentJson),
      daily: dailyList,
    );
  }
}
