import 'package:geolocator/geolocator.dart';
import '../models/event_model.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import 'supabase_service.dart';

class EventService {
  // Fetch events with filters
  static Future<List<EventModel>> getEvents({
    double? latitude,
    double? longitude,
    double? radiusMiles,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    EventStatus? status,
    bool showPastEvents = false, // Allow showing past events for testing
  }) async {
    try {
      print('EventService.getEvents called');
      print(
        'Filters: status=$status, startDate=$startDate, endDate=$endDate, radius=$radiusMiles',
      );

      // Start with a simple query
      var query = SupabaseService.client.from('events').select('*');

      // Filter by status
      if (status != null) {
        query = query.eq('status', status.value);
        print('Filtered by status: ${status.value}');
      }

      // Filter by date range - only show upcoming events by default
      if (!showPastEvents) {
        // Show events that haven't ended yet OR are currently live
        final now = DateTime.now().toIso8601String();
        query = query.gte('date_end', now);
        print('Filtered to show events ending after: $now');
      }

      // Additional date filters
      if (startDate != null) {
        query = query.gte('date_start', startDate.toIso8601String());
        print('Filtered by startDate: ${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        query = query.lte('date_end', endDate.toIso8601String());
        print('Filtered by endDate: ${endDate.toIso8601String()}');
      }

      print('Executing query...');
      final response = await query;
      print('Query executed. Response type: ${response.runtimeType}');
      print('Events fetched from DB: ${response.length}');

      if (response.isEmpty) {
        print('WARNING: No events returned from database');
        print('This could mean:');
        print('1. No events exist in the events table');
        print('2. All events have ended (date_end < now)');
        print('3. Status filter excluded all events');
        print('4. Date range filter excluded all events');
      }

      List<EventModel> events = [];
      for (var item in response) {
        try {
          print('Parsing event: ${item['id']} - ${item['store_name']}');
          final event = EventModel.fromJson(item);
          events.add(event);
        } catch (e, stackTrace) {
          print('Error parsing event: $e');
          print('Event data: $item');
          print('Stack trace: $stackTrace');
        }
      }

      print('Successfully parsed ${events.length} events');

      // Filter by radius if location provided
      if (latitude != null && longitude != null && radiusMiles != null) {
        events = events.where((event) {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            event.latitude,
            event.longitude,
          );
          final distanceMiles =
              distance * 0.000621371; // Convert meters to miles
          return distanceMiles <= radiusMiles;
        }).toList();
      }

      // Filter by categories if provided
      if (categoryIds != null && categoryIds.isNotEmpty) {
        // This would require joining with event_categories
        // For now, we'll filter client-side if needed
      }

      // Sort by distance if location provided
      if (latitude != null && longitude != null) {
        events.sort((a, b) {
          final distanceA = Geolocator.distanceBetween(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          );
          final distanceB = Geolocator.distanceBetween(
            latitude,
            longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      print('Final events count after all filters: ${events.length}');
      return events;
    } catch (e, stackTrace) {
      print('ERROR fetching events: $e');
      print('Stack trace: $stackTrace');
      print('This might be a database connection issue or query syntax error');
      rethrow; // Re-throw so UI can show error
    }
  }

  // Get event by ID with full details
  static Future<EventModel?> getEventById(String eventId) async {
    try {
      final response = await SupabaseService.client
          .from('events')
          .select('*')
          .eq('id', eventId)
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  // Get brand for event
  static Future<BrandModel?> getBrand(String brandId) async {
    try {
      final response = await SupabaseService.client
          .from('brands')
          .select('*')
          .eq('id', brandId)
          .single();

      return BrandModel.fromJson(response);
    } catch (e) {
      print('Error fetching brand: $e');
      return null;
    }
  }

  // Get categories for event
  static Future<List<CategoryModel>> getEventCategories(String eventId) async {
    try {
      final response = await SupabaseService.client
          .from('event_categories')
          .select('categories(*)')
          .eq('event_id', eventId);

      List<CategoryModel> categories = [];
      for (var item in response) {
        if (item['categories'] != null) {
          categories.add(CategoryModel.fromJson(item['categories']));
        }
      }
      return categories;
    } catch (e) {
      print('Error fetching event categories: $e');
      return [];
    }
  }

  // Calculate distance in miles
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distance * 0.000621371; // Convert meters to miles
  }

  // Check if event is live (current time is between start and end)
  static bool isEventLive(EventModel event) {
    final now = DateTime.now();
    return now.isAfter(event.dateStart) && now.isBefore(event.dateEnd);
  }

  // Check if event is upcoming
  static bool isEventUpcoming(EventModel event) {
    return DateTime.now().isBefore(event.dateStart);
  }
}
