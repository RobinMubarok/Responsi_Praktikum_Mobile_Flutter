import 'package:flutter/material.dart';

/// Data visual untuk setiap kode kondisi cuaca WMO.
class WeatherVisualInfo {
  final String label;
  final IconData icon;
  final Color color;

  const WeatherVisualInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Helper untuk mengonversi WMO weather_code Open-Meteo menjadi label, ikon, dan warna.
class WeatherCodeHelper {
  WeatherCodeHelper._();

  static WeatherVisualInfo getInfo(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return WeatherVisualInfo(
          label: 'Cerah',
          icon: isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: isDay ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
        );
      case 1:
      case 2:
        return WeatherVisualInfo(
          label: 'Cerah Berawan',
          icon: isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
          color: const Color(0xFF38BDF8),
        );
      case 3:
        return const WeatherVisualInfo(
          label: 'Berawan',
          icon: Icons.cloud_rounded,
          color: Color(0xFF64748B),
        );
      case 45:
      case 48:
        return const WeatherVisualInfo(
          label: 'Berkabut',
          icon: Icons.foggy,
          color: Color(0xFF94A3B8),
        );
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return const WeatherVisualInfo(
          label: 'Gerimis',
          icon: Icons.grain_rounded,
          color: Color(0xFF0EA5E9),
        );
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return const WeatherVisualInfo(
          label: 'Hujan',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF2563EB),
        );
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return const WeatherVisualInfo(
          label: 'Salju',
          icon: Icons.ac_unit_rounded,
          color: Color(0xFF38BDF8),
        );
      case 80:
      case 81:
      case 82:
        return const WeatherVisualInfo(
          label: 'Hujan Deras',
          icon: Icons.beach_access_rounded,
          color: Color(0xFF1D4ED8),
        );
      case 95:
      case 96:
      case 99:
        return const WeatherVisualInfo(
          label: 'Badai Petir',
          icon: Icons.thunderstorm_rounded,
          color: Color(0xFF4F46E5),
        );
      default:
        return const WeatherVisualInfo(
          label: 'Tidak Diketahui',
          icon: Icons.cloud_queue_rounded,
          color: Color(0xFF64748B),
        );
    }
  }
}
