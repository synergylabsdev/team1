import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/brand_service.dart';
import '../../models/event_model.dart';
import '../../models/brand_model.dart';
import '../../utils/permissions_service.dart';
import '../events/event_filters.dart';
import '../events/event_details_screen.dart';
import '../events/event_list_item.dart';
import '../favorites/brand_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isMapView = true;
  Position? _currentPosition;
  List<EventModel> _events = [];
  List<BrandModel> _brands = [];
  bool _isLoading = true;
  bool _isLoadingBrands = true;
  String? _errorMessage;
  EventFilters _filters = EventFilters();
  Set<Marker> _markers = {};
  int _selectedTab = 0; // 0 = Events, 1 = Brands
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _getCurrentLocation();
    _loadBrands();
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
      _errorMessage = null;
    });

    try {
      // final radius = _filters.radius?.miles;
      // final dateRange = _filters.dateFilter?.dateRange;

      // print(
      //   'Loading events with filters: radius=$radius, dateRange=$dateRange',
      // );

      final events = await EventService.getEvents(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        // radiusMiles: radius?.toDouble(),
        // startDate: dateRange?.start,
        // endDate: dateRange?.end,
        categoryIds: _filters.categoryIds,
        showPastEvents: false, // Set to true for testing to see all events
      );

      print('Loaded ${events.length} events');

      // if (events.isEmpty && _currentPosition == null && radius == null) {
      //   print('No events found. Possible reasons:');
      //   print('1. No events in database');
      //   print('2. All events have ended');
      //   print('3. Database connection issue');
      // }

      setState(() {
        _events = events;
        _isLoading = false;
        _errorMessage = null;
      });

      _updateMapMarkers();
    } catch (e, stackTrace) {
      print('Error loading events: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Error loading events: ${e.toString()}\n\nCheck console for details.';
      });
    }
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoadingBrands = true;
    });

    try {
      final brands = await BrandService.getPopularBrands(limit: 20);
      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
      });
    } catch (e) {
      print('Error loading brands: $e');
      setState(() {
        _isLoadingBrands = false;
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.business), text: 'Brands'),
          ],
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
        ),
        actions: [
          if (_selectedTab == 0) ...[
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0 ? _buildEventsTab() : _buildBrandsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // Empty state is handled in _buildEventsTab, but we need a fallback for map
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No events to display on map',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isMapView = false;
                });
              },
              child: const Text('Switch to List View'),
            ),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64),
            const SizedBox(height: 16),
            const Text('Location access required for map view'),
            const SizedBox(height: 8),
            const Text(
              'Events will still load without location',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Enable Location'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isMapView = false;
                });
              },
              child: const Text('Switch to List View'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: _markers.isEmpty ? 10 : 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        if (_markers.isNotEmpty && _currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(_getBounds(), 100),
          );
        }
      },
    );
  }

  LatLngBounds _getBounds() {
    if (_events.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude - 0.1,
          _currentPosition!.longitude - 0.1,
        ),
        northeast: LatLng(
          _currentPosition!.latitude + 0.1,
          _currentPosition!.longitude + 0.1,
        ),
      );
    }

    double minLat = _events.first.latitude;
    double maxLat = _events.first.latitude;
    double minLng = _events.first.longitude;
    double maxLng = _events.first.longitude;

    for (var event in _events) {
      minLat = minLat < event.latitude ? minLat : event.latitude;
      maxLat = maxLat > event.latitude ? maxLat : event.latitude;
      minLng = minLng < event.longitude ? minLng : event.longitude;
      maxLng = maxLng > event.longitude ? maxLng : event.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEvents,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Show debug info
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Debug Info'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Events loaded: ${_events.length}'),
                            Text(
                              'Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
                            ),
                            Text(
                              'Filters: ${_filters.radius?.miles} miles, ${_filters.dateFilter?.label}',
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Check console logs for detailed error information.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Debug Info'),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_busy,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This could mean:\n• No events in database\n• All events have ended\n• Filters are too restrictive',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _showFilters,
                    child: const Text('Adjust Filters'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      // Test: Load all events including past ones
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final events = await EventService.getEvents(
                          showPastEvents: true,
                        );
                        setState(() {
                          _events = events;
                          _isLoading = false;
                        });
                        _updateMapMarkers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Loaded ${events.length} events (including past)',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text('Show All Events'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _isMapView ? _buildMapView() : _buildListView();
  }

  Widget _buildBrandsTab() {
    if (_isLoadingBrands) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_brands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No brands found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Brands will appear here once they are added to the database.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBrands,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBrands,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          final brand = _brands[index];
          return _BrandCard(
            brand: brand,
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
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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

  const _FiltersSheet({required this.filters, required this.onFiltersChanged});

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
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
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
          Text('Radius', style: Theme.of(context).textTheme.titleMedium),
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
          Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
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

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;

  const _BrandCard({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (brand.logoUrl != null)
                Image.network(
                  brand.logoUrl!,
                  height: 80,
                  width: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.business,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                )
              else
                const Icon(
                  Icons.business,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              const SizedBox(height: 12),
              Text(
                brand.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (brand.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  brand.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
