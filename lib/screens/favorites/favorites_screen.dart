import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/brand_model.dart';
import '../../models/event_model.dart';
import '../../services/favorite_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/permissions_service.dart';
import '../events/event_details_screen.dart';
import 'brand_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<BrandModel> _favoriteBrands = [];
  Map<String, List<EventModel>> _eventsByBrand = {};
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await PermissionsService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      _loadFavorites();
    } catch (e) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteIds = await FavoriteService.getUserFavorites();
      
      // Load brand details
      final brands = <BrandModel>[];
      for (var brandId in favoriteIds) {
        try {
          final brand = await EventService.getBrand(brandId);
          if (brand != null) {
            brands.add(brand);
          }
        } catch (e) {
          print('Error loading brand $brandId: $e');
        }
      }

      // Load events for each brand
      final eventsByBrand = <String, List<EventModel>>{};
      if (_currentPosition != null) {
        for (var brand in brands) {
          try {
            final events = await EventService.getEvents(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              radiusMiles: 50,
            );
            // Filter events for this brand
            final brandEvents = events
                .where((e) => e.brandId == brand.id)
                .where((e) => e.dateStart.isAfter(DateTime.now()))
                .toList();
            eventsByBrand[brand.id] = brandEvents;
          } catch (e) {
            print('Error loading events for brand ${brand.id}: $e');
          }
        }
      }

      setState(() {
        _favoriteBrands = brands;
        _eventsByBrand = eventsByBrand;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unfavorite(String brandId) async {
    try {
      await FavoriteService.removeFavorite(brandId);
      await _loadFavorites();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBrands.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favoriteBrands.length,
                    itemBuilder: (context, index) {
                      final brand = _favoriteBrands[index];
                      final events = _eventsByBrand[brand.id] ?? [];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandDetailScreen(
                                  brand: brand,
                                  currentPosition: _currentPosition,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Brand Logo
                                    if (brand.logoUrl != null)
                                      Image.network(
                                        brand.logoUrl!,
                                        width: 60,
                                        height: 60,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.business, size: 60),
                                      )
                                    else
                                      const Icon(Icons.business, size: 60),
                                    
                                    const SizedBox(width: 16),
                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            brand.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (brand.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              brand.description!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.favorite, color: AppTheme.errorColor),
                                      onPressed: () => _unfavorite(brand.id),
                                    ),
                                  ],
                                ),
                                
                                if (events.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  Text(
                                    'Upcoming Events (${events.length})',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  ...events.take(3).map((event) => ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.event,
                                          size: 20,
                                        ),
                                        title: Text(event.storeName),
                                        subtitle: Text(
                                          '${event.dateStart.month}/${event.dateStart.day}/${event.dateStart.year}',
                                        ),
                                        trailing: const Icon(Icons.chevron_right, size: 20),
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => EventDetailsSheet(
                                              event: event,
                                              currentPosition: _currentPosition,
                                            ),
                                          );
                                        },
                                      )),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No upcoming events',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start favoriting brands to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

