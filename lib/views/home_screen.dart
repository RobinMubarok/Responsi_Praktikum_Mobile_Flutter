import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/weather_code_helper.dart';
import '../models/weather_model.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'search_screen.dart';
import 'widgets/daily_forecast_tile.dart';
import 'widgets/weather_metric_card.dart';

/// Layar utama aplikasi (Home / Weather Screen) yang menampilkan informasi cuaca
/// terkini, detail metrik tambahan, lokasi favorit, dan prakiraan beberapa hari ke depan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewModel>().init();
    });
  }

  Future<void> _openSearchScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherViewModel>();
    final selected = vm.selectedLocation;
    final isFav = vm.isFavorite(selected);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    selected.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (selected.subtitle.isNotEmpty)
              Text(
                selected.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isFav ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
            onPressed: () async {
              final added = await vm.toggleFavorite(selected);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    added
                        ? '${selected.name} ditambahkan ke favorit'
                        : '${selected.name} dihapus dari favorit',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.red.shade500 : null,
            ),
          ),
          IconButton(
            tooltip: 'Cari Kota',
            onPressed: _openSearchScreen,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.fetchWeather,
          child: _buildBody(context, vm),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WeatherViewModel vm) {
    switch (vm.status) {
      case WeatherStatus.initial:
      case WeatherStatus.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data cuaca terkini...'),
                ],
              ),
            ),
          ],
        );

      case WeatherStatus.error:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Cuaca',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Terjadi kesalahan saat menghubungi server.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: vm.fetchWeather,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        );

      case WeatherStatus.empty:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Data cuaca tidak tersedia untuk lokasi ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        );

      case WeatherStatus.loaded:
        final weather = vm.weather!;
        return _WeatherContent(
          vm: vm,
          weather: weather,
          onOpenSearch: _openSearchScreen,
        );
    }
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherViewModel vm;
  final WeatherModel weather;
  final VoidCallback onOpenSearch;

  const _WeatherContent({
    required this.vm,
    required this.weather,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final visual = WeatherCodeHelper.getInfo(
      current.weatherCode,
      isDay: current.isDay,
    );
    final todayForecast = weather.daily.isNotEmpty ? weather.daily.first : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final horizontalPadding = isWide ? 28.0 : 16.0;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          children: [
            if (vm.favorites.isNotEmpty) ...[
              _FavoritesQuickBar(vm: vm),
              const SizedBox(height: 12),
            ],
            _HeroWeatherCard(
              cityName: vm.selectedLocation.name,
              weather: weather,
              visual: visual,
              todayForecast: todayForecast,
            ),
            const SizedBox(height: 16),
            Text(
              'Detail Cuaca Saat Ini',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.45 : 1.35,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                WeatherMetricCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Kelembapan',
                  value: '${current.relativeHumidity2m}%',
                ),
                WeatherMetricCard(
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF0D9488),
                  label: 'Kecepatan Angin',
                  value: '${current.windSpeed10m.toStringAsFixed(1)} km/j',
                ),
                WeatherMetricCard(
                  icon: Icons.grain_rounded,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Curah Hujan',
                  value: '${current.precipitation.toStringAsFixed(1)} mm',
                ),
                WeatherMetricCard(
                  icon: Icons.umbrella_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  label: 'Peluang Hujan',
                  value: todayForecast != null
                      ? '${todayForecast.precipitationProbabilityMax}%'
                      : '-',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prakiraan ${weather.daily.length} Hari Ke Depan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: onOpenSearch,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Ganti Kota'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weather.daily.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  return DailyForecastTile(
                    forecast: weather.daily[index],
                    isToday: index == 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FavoritesQuickBar extends StatelessWidget {
  final WeatherViewModel vm;

  const _FavoritesQuickBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vm.favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fav = vm.favorites[index];
          final isSelected = fav == vm.selectedLocation;
          return ChoiceChip(
            label: Text(fav.name),
            selected: isSelected,
            avatar: Icon(
              Icons.favorite_rounded,
              size: 16,
              color: isSelected ? Colors.white : Colors.red.shade400,
            ),
            onSelected: (_) {
              if (!isSelected) {
                vm.selectLocation(fav);
              }
            },
          );
        },
      ),
    );
  }
}

class _HeroWeatherCard extends StatelessWidget {
  final String cityName;
  final WeatherModel weather;
  final WeatherVisualInfo visual;
  final DailyForecast? todayForecast;

  const _HeroWeatherCard({
    required this.cityName,
    required this.weather,
    required this.visual,
    required this.todayForecast,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final textTheme = Theme.of(context).textTheme;
    final gradientColors = current.isDay
        ? [const Color(0xFF1D4ED8), const Color(0xFF38BDF8)]
        : [const Color(0xFF1E1B4B), const Color(0xFF312E81)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visual.label,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terasa seperti ${current.apparentTemperature.round()}°C',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                visual.icon,
                color: Colors.white,
                size: 56,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${current.temperature2m.round()}°C',
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              if (todayForecast != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Min ${todayForecast!.temperature2mMin.round()}° • Maks ${todayForecast!.temperature2mMax.round()}°',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
