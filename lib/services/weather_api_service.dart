import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/weather_model.dart';

/// Exception khusus untuk kesalahan jaringan atau respons API.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Service untuk berkomunikasi dengan Open-Meteo Weather Forecast API dan Geocoding API.
class WeatherApiService {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil data cuaca terkini dan prakiraan harian dari Open-Meteo Forecast API.
  Future<WeatherModel> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastBaseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'precipitation',
          'weather_code',
          'wind_speed_10m',
          'is_day',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_probability_max',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final jsonMap = await _getJson(uri);
    return WeatherModel.fromJson(jsonMap);
  }

  /// Mencari lokasi/kota berdasarkan nama kota menggunakan Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(_geocodingBaseUrl).replace(
      queryParameters: {
        'name': trimmed,
        'count': '10',
        'language': 'id',
        'format': 'json',
      },
    );

    final jsonMap = await _getJson(uri);
    final results = jsonMap['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Gagal memuat data dari server (Kode: ${response.statusCode}).',
        );
      }

      if (response.body.trim().isEmpty) {
        throw const ApiException('Respons server kosong.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Format respons API tidak valid.');
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'Koneksi timeout. Periksa jaringan internet Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet. Pastikan perangkat terhubung ke jaringan.',
      );
    } on FormatException catch (e) {
      throw ApiException('Gagal memproses data JSON: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan tak terduga: $e');
    }
  }
}
