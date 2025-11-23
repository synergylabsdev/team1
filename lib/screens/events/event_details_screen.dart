import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../models/event_model.dart';
import '../../models/brand_model.dart';
import '../../services/event_service.dart';
import '../../services/check_in_service.dart';
import '../../services/favorite_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import 'qr_check_in_screen.dart';
import 'trivia_game_screen.dart';
import 'review_screen.dart';

class EventDetailsSheet extends StatefulWidget {
  final EventModel event;
  final Position? currentPosition;
  final VoidCallback? onCheckIn;

  const EventDetailsSheet({
    super.key,
    required this.event,
    this.currentPosition,
    this.onCheckIn,
  });

  @override
  State<EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<EventDetailsSheet> {
  BrandModel? _brand;
  bool _isFavorited = false;
  bool _hasCheckedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    try {
      final brand = await EventService.getBrand(widget.event.brandId);
      final favorited = await FavoriteService.isFavorited(widget.event.brandId);
      
      // Check if user has checked in
      final userId = await _getUserId();
      bool checkedIn = false;
      if (userId != null) {
        checkedIn = await CheckInService.hasCheckedIn(userId, widget.event.id);
      }

      setState(() {
        _brand = brand;
        _isFavorited = favorited;
        _hasCheckedIn = checkedIn;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading event details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserId() async {
    try {
      final user = SupabaseService.currentUser;
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y • h:mm a').format(dateTime);
  }

  String _getDistance() {
    if (widget.currentPosition == null) return '';
    
    final distance = EventService.calculateDistance(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
      widget.event.latitude,
      widget.event.longitude,
    );
    
    if (distance < 1) {
      return '${(distance * 5280).toStringAsFixed(0)} feet away';
    }
    return '${distance.toStringAsFixed(1)} miles away';
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorited) {
        await FavoriteService.removeFavorite(widget.event.brandId);
      } else {
        await FavoriteService.addFavorite(widget.event.brandId);
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
            duration: const Duration(seconds: 2),
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

  Future<void> _addToCalendar() async {
    try {
      final event = Event(
        title: '${_brand?.name ?? 'Event'} - ${widget.event.storeName}',
        description: widget.event.description ?? '',
        location: widget.event.location,
        startDate: widget.event.dateStart,
        endDate: widget.event.dateEnd,
      );

      await Add2Calendar.addEvent2Cal(event);
      
      // Schedule push notifications
      // await NotificationService.scheduleEventReminders(widget.event);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event added to calendar with reminders'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to calendar: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isLive = EventService.isEventLive(widget.event);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Brand and Status
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_brand != null)
                                        Text(
                                          _brand!.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.event.storeName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Date & Time
                            _buildDetailRow(
                              Icons.calendar_today,
                              _formatDateTime(widget.event.dateStart),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Location
                            _buildDetailRow(
                              Icons.location_on,
                              widget.event.location,
                            ),
                            
                            if (widget.currentPosition != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getDistance(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                            
                            if (widget.event.description != null) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.event.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _addToCalendar,
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Add to Calendar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _toggleFavorite,
                                  icon: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Action Buttons Row
                            Row(
                              children: [
                                if (isLive && !_hasCheckedIn)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const QRCheckInScreen(),
                                          ),
                                        ).then((_) {
                                          // Refresh check-in status
                                          _loadEventDetails();
                                        });
                                      },
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text('Check In'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    ),
                                  )
                                else if (_hasCheckedIn)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Already Checked In'),
                                    ),
                                  ),
                                
                                if (isLive && !_hasCheckedIn) const SizedBox(width: 8),
                                
                                if (isLive)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TriviaGameScreen(
                                              event: widget.event,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.quiz),
                                      label: const Text('Play Trivia'),
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Review Button (if checked in)
                            if (_hasCheckedIn) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReviewScreen(
                                          event: widget.event,
                                          brandId: widget.event.brandId,
                                          onReviewSubmitted: () {
                                            Navigator.pop(context);
                                            widget.onCheckIn?.call();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.rate_review),
                                  label: const Text('Leave a Review'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

