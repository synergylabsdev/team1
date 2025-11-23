import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../utils/permissions_service.dart';
import '../events/event_filters.dart';
import '../events/event_details_screen.dart';
import '../events/event_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMapView = true;
  Position? _currentPosition;
  List<EventModel> _events = [];
  bool _isLoading = true;
  EventFilters _filters = EventFilters();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await PermissionsService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _loadEvents();
      } else {
        // Location denied, still load events
        _loadEvents();
      }
    } catch (e) {
      print('Error getting location: $e');
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final radius = _filters.radius?.miles;
      final dateRange = _filters.dateFilter?.dateRange;
      
      final events = await EventService.getEvents(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        radiusMiles: radius?.toDouble(),
        startDate: dateRange?.start,
        endDate: dateRange?.end,
        categoryIds: _filters.categoryIds,
      );

      setState(() {
        _events = events;
        _isLoading = false;
      });

      _updateMapMarkers();
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    
    for (var event in _events) {
      final isLive = EventService.isEventLive(event);
      final marker = Marker(
        markerId: MarkerId(event.id),
        position: LatLng(event.latitude, event.longitude),
        infoWindow: InfoWindow(
          title: event.storeName,
          snippet: 'Tap for details',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isLive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
        ),
        onTap: () {
          _showEventDetails(event);
        },
      );
      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailsSheet(
        event: event,
        currentPosition: _currentPosition,
        onCheckIn: () {
          Navigator.pop(context);
          _loadEvents(); // Reload to update check-in status
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SampleFinder'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? 'List View' : 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // User Points Card
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${user.points} Points',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(user.tierStatus.value),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Map or List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMapView
                    ? _buildMapView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64),
            const SizedBox(height: 16),
            const Text('Location access required for map view'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildListView() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return EventListItem(
            event: event,
            currentPosition: _currentPosition,
            onTap: () => _showEventDetails(event),
          );
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FiltersSheet(
        filters: _filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          _loadEvents();
        },
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final EventFilters filters;
  final ValueChanged<EventFilters> onFiltersChanged;

  const _FiltersSheet({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late EventFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentFilters = EventFilters();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          
          // Radius Filter
          Text(
            'Radius',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: RadiusFilter.values.map((radius) {
              final isSelected = _currentFilters.radius == radius;
              return FilterChip(
                label: Text('≤${radius.miles} miles'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      radius: selected ? radius : null,
                    );
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Date Filter
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: DateFilter.values.map((dateFilter) {
              final isSelected = _currentFilters.dateFilter == dateFilter;
              return FilterChip(
                label: Text(dateFilter.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      dateFilter: selected ? dateFilter : null,
                    );
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 21+ Only
          CheckboxListTile(
            title: const Text('21+ Restricted Only'),
            value: _currentFilters.show21PlusOnly,
            onChanged: (value) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  show21PlusOnly: value ?? false,
                );
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(_currentFilters);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
