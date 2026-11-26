import 'package:flutter/material.dart';

import '../../core/utils/weather_code_helper.dart';
import '../../models/weather_model.dart';

/// Baris perkiraan cuaca harian pada daftar prakiraan beberapa hari ke depan.
class DailyForecastTile extends StatelessWidget {
  final DailyForecast forecast;
  final bool isToday;

  const DailyForecastTile({
    super.key,
    required this.forecast,
    this.isToday = false,
  });

  static const List<String> _dayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatDate(DateTime date) {
    if (isToday) return 'Hari Ini';
    final day = _dayNames[date.weekday - 1];
    final month = _monthNames[date.month - 1];
    return '$day, ${date.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = WeatherCodeHelper.getInfo(forecast.weatherCode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              _formatDate(forecast.date),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade800,
              ),
            ),
          ),
          Icon(visual.icon, color: visual.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              visual.label,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 2),
              Text(
                '${forecast.precipitationProbabilityMax}%',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 82,
            child: Text(
              '${forecast.temperature2mMin.round()}° / ${forecast.temperature2mMax.round()}°',
              textAlign: TextAlign.end,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
