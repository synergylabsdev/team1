import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/brand_model.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/favorite_service.dart';
import '../../utils/app_theme.dart';
import '../events/event_details_screen.dart';

class BrandDetailScreen extends StatefulWidget {
  final BrandModel brand;
  final Position? currentPosition;

  const BrandDetailScreen({
    super.key,
    required this.brand,
    this.currentPosition,
  });

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  List<EventModel> _upcomingEvents = [];
  bool _isFavorited = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorited = await FavoriteService.isFavorited(widget.brand.id);
      
      List<EventModel> events = [];
      if (widget.currentPosition != null) {
        events = await EventService.getEvents(
          latitude: widget.currentPosition!.latitude,
          longitude: widget.currentPosition!.longitude,
          radiusMiles: 50,
        );
        events = events
            .where((e) => e.brandId == widget.brand.id)
            .where((e) => e.dateStart.isAfter(DateTime.now()))
            .toList();
        events.sort((a, b) => a.dateStart.compareTo(b.dateStart));
      }

      setState(() {
        _isFavorited = favorited;
        _upcomingEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorited) {
        await FavoriteService.removeFavorite(widget.brand.id);
      } else {
        await FavoriteService.addFavorite(widget.brand.id);
      }
      setState(() {
        _isFavorited = !_isFavorited;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
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
        title: Text(widget.brand.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? AppTheme.errorColor : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (widget.brand.logoUrl != null)
                            Image.network(
                              widget.brand.logoUrl!,
                              height: 120,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.business, size: 120),
                            )
                          else
                            const Icon(Icons.business, size: 120),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            widget.brand.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          
                          if (widget.brand.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.brand.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Upcoming Events
                  Text(
                    'Upcoming Events',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (_upcomingEvents.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No upcoming events',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._upcomingEvents.map((event) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.event, color: AppTheme.primaryColor),
                            title: Text(event.storeName),
                            subtitle: Text(
                              '${event.dateStart.month}/${event.dateStart.day}/${event.dateStart.year} • ${event.location}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => EventDetailsSheet(
                                  event: event,
                                  currentPosition: widget.currentPosition,
                                ),
                              );
                            },
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

