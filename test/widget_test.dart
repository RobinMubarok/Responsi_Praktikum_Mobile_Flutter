import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:responsi_weather/main.dart';
import 'package:responsi_weather/models/location_model.dart';
import 'package:responsi_weather/models/weather_model.dart';
import 'package:responsi_weather/services/local_storage_service.dart';
import 'package:responsi_weather/services/weather_api_service.dart';

void main() {
  final sampleForecastJson = {
    'latitude': -7.75,
    'longitude': 110.375,
    'timezone': 'Asia/Jakarta',
    'current': {
      'time': '2026-11-26T09:00',
      'temperature_2m': 29.4,
      'relative_humidity_2m': 74,
      'apparent_temperature': 33.1,
      'precipitation': 0.2,
      'weather_code': 2,
      'wind_speed_10m': 11.5,
      'is_day': 1,
    },
    'daily': {
      'time': ['2026-11-26', '2026-11-27'],
      'weather_code': [2, 61],
      'temperature_2m_max': [32.0, 30.5],
      'temperature_2m_min': [23.5, 23.0],
      'precipitation_probability_max': [40, 80],
    },
  };

  final sampleGeocodingJson = {
    'results': [
      {
        'id': 1642911,
        'name': 'Jakarta',
        'latitude': -6.21462,
        'longitude': 106.84513,
        'country': 'Indonesia',
        'admin1': 'Jakarta',
        'timezone': 'Asia/Jakarta',
      }
    ],
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('WeatherModel.fromJson parses current and daily data accurately', () {
    final model = WeatherModel.fromJson(sampleForecastJson);

    expect(model.current.temperature2m, 29.4);
    expect(model.current.relativeHumidity2m, 74);
    expect(model.current.apparentTemperature, 33.1);
    expect(model.current.precipitation, 0.2);
    expect(model.current.weatherCode, 2);
    expect(model.current.windSpeed10m, 11.5);
    expect(model.daily.length, 2);
    expect(model.daily.first.temperature2mMax, 32.0);
    expect(model.daily.first.temperature2mMin, 23.5);
    expect(model.daily.first.precipitationProbabilityMax, 40);
  });

  test('WeatherApiService fetches weather and searches locations via GET',
      () async {
    final mockClient = MockClient((request) async {
      if (request.url.host == 'api.open-meteo.com') {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['timezone'], 'auto');
        return http.Response(jsonEncode(sampleForecastJson), 200);
      }
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['name'], 'Jakarta');
        return http.Response(jsonEncode(sampleGeocodingJson), 200);
      }
      return http.Response('Not Found', 404);
    });

    final apiService = WeatherApiService(client: mockClient);
    final weather = await apiService.fetchWeather(
      latitude: -7.7956,
      longitude: 110.3695,
    );
    expect(weather.current.temperature2m, 29.4);

    final locations = await apiService.searchLocations('Jakarta');
    expect(locations.length, 1);
    expect(locations.first.name, 'Jakarta');
  });

  test('LocalStorageService persists favorites and search history', () async {
    final storage = LocalStorageService();
    const loc = LocationModel(
      id: 1642911,
      name: 'Jakarta',
      country: 'Indonesia',
      admin1: 'Jakarta',
      latitude: -6.21462,
      longitude: 106.84513,
    );

    await storage.saveFavorites([loc]);
    await storage.addSearchHistory(loc);

    final loadedFavs = await storage.getFavorites();
    final loadedHistory = await storage.getSearchHistory();

    expect(loadedFavs, [loc]);
    expect(loadedHistory, [loc]);
  });

  testWidgets('HomeScreen renders weather data and navigates to SearchScreen',
      (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.host == 'api.open-meteo.com') {
        return http.Response(jsonEncode(sampleForecastJson), 200);
      }
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        return http.Response(jsonEncode(sampleGeocodingJson), 200);
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      ResponsiWeatherApp(
        apiService: WeatherApiService(client: mockClient),
        storageService: LocalStorageService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Yogyakarta'), findsOneWidget);
    expect(find.text('29°C'), findsOneWidget);
    expect(find.text('74%'), findsOneWidget);
    expect(find.text('11.5 km/j'), findsOneWidget);

    await tester.tap(find.byTooltip('Cari Kota'));
    await tester.pumpAndSettle();

    expect(find.text('Cari Lokasi'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Jakarta');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Jakarta'),
      ),
      findsOneWidget,
    );
  });
}
