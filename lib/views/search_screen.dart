import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';

/// Layar pencarian lokasi (Search / Location Screen) untuk mencari kota melalui
/// Open-Meteo Geocoding API, memilih lokasi, serta mengelola favorit & riwayat.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVm = context.read<SearchViewModel>();
      searchVm.clearSearch();
      searchVm.loadHistory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    context.read<SearchViewModel>().searchLocations(value);
  }

  Future<void> _selectLocation(LocationModel location) async {
    final searchVm = context.read<SearchViewModel>();
    final weatherVm = context.read<WeatherViewModel>();

    await searchVm.addToHistory(location);
    if (!mounted) return;
    weatherVm.selectLocation(location);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final searchVm = context.watch<SearchViewModel>();
    final weatherVm = context.watch<WeatherViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama kota (mis. Jakarta, Bandung)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Hapus',
                                onPressed: () {
                                  _controller.clear();
                                  searchVm.clearSearch();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => _onSearchSubmitted(_controller.text),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cari'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildContent(context, searchVm, weatherVm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SearchViewModel searchVm,
    WeatherViewModel weatherVm,
  ) {
    switch (searchVm.status) {
      case SearchStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Mencari lokasi...'),
            ],
          ),
        );

      case SearchStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 52, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                searchVm.errorMessage ?? 'Terjadi kesalahan saat mencari kota.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _onSearchSubmitted(_controller.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        );

      case SearchStatus.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 52, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(
                'Kota "${searchVm.query}" tidak ditemukan.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Coba periksa ejaan atau gunakan nama kota lain.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case SearchStatus.loaded:
        return ListView.separated(
          itemCount: searchVm.results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final location = searchVm.results[index];
            return _LocationCard(
              location: location,
              isFavorite: weatherVm.isFavorite(location),
              onTap: () => _selectLocation(location),
              onToggleFavorite: () => weatherVm.toggleFavorite(location),
            );
          },
        );

      case SearchStatus.idle:
        return _buildSavedLists(context, searchVm, weatherVm);
    }
  }

  Widget _buildSavedLists(
    BuildContext context,
    SearchViewModel searchVm,
    WeatherViewModel weatherVm,
  ) {
    final favorites = weatherVm.favorites;
    final history = searchVm.searchHistory;

    if (favorites.isEmpty && history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Cari kota untuk melihat prakiraan cuaca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Lokasi favorit dan riwayat pencarian Anda akan muncul di sini.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (favorites.isNotEmpty) ...[
          Text(
            'Lokasi Favorit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...favorites.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationCard(
                location: loc,
                isFavorite: true,
                onTap: () => _selectLocation(loc),
                onToggleFavorite: () => weatherVm.toggleFavorite(loc),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pencarian',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: searchVm.clearHistory,
                child: const Text('Hapus Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationCard(
                location: loc,
                isFavorite: weatherVm.isFavorite(loc),
                leadingIcon: Icons.history_rounded,
                onTap: () => _selectLocation(loc),
                onToggleFavorite: () => weatherVm.toggleFavorite(loc),
                onRemoveHistory: () => searchVm.removeHistoryItem(loc),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool isFavorite;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onRemoveHistory;

  const _LocationCard({
    required this.location,
    required this.isFavorite,
    this.leadingIcon = Icons.location_on_outlined,
    required this.onTap,
    required this.onToggleFavorite,
    this.onRemoveHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(
          leadingIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          location.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          location.subtitle.isNotEmpty
              ? '${location.subtitle} (${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})'
              : '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isFavorite ? 'Hapus dari Favorit' : 'Simpan Favorit',
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red.shade500 : Colors.grey.shade600,
              ),
            ),
            if (onRemoveHistory != null)
              IconButton(
                tooltip: 'Hapus dari Riwayat',
                onPressed: onRemoveHistory,
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }
}
