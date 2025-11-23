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
  }) async {
    try {
      var query = SupabaseService.client
          .from('events')
          .select('*, brands(*), event_categories(categories(*))');

      // Filter by status
      if (status != null) {
        query = query.eq('status', status.value);
      } else {
        // Only show active and live events by default
        // Using OR fallback instead of in_ for compatibility
        query = query.or('status.eq.Active,status.eq.Live');
      }

      // Filter by date range
      if (startDate != null) {
        query = query.gte('date_start', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date_end', endDate.toIso8601String());
      }

      final response = await query;

      List<EventModel> events = [];
      if (response != null) {
        for (var item in response) {
          try {
            events.add(EventModel.fromJson(item));
          } catch (e) {
            print('Error parsing event: $e');
          }
        }
      }

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

      return events;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
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
