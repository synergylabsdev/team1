import '../models/brand_model.dart';
import 'supabase_service.dart';
import 'event_service.dart';

class BrandService {
  // Get all brands
  static Future<List<BrandModel>> getAllBrands() async {
    try {
      final response = await SupabaseService.client
          .from('brands')
          .select('*')
          .order('name', ascending: true);

      return response.map((item) => BrandModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  // Get popular brands (brands with most events)
  static Future<List<BrandModel>> getPopularBrands({int limit = 10}) async {
    try {
      // Get all brands
      final brands = await getAllBrands();
      
      // Get event counts for each brand
      final brandEventCounts = <String, int>{};
      final events = await EventService.getEvents();
      
      for (var event in events) {
        brandEventCounts[event.brandId] = (brandEventCounts[event.brandId] ?? 0) + 1;
      }
      
      // Sort brands by event count
      brands.sort((a, b) {
        final countA = brandEventCounts[a.id] ?? 0;
        final countB = brandEventCounts[b.id] ?? 0;
        return countB.compareTo(countA);
      });
      
      return brands.take(limit).toList();
    } catch (e) {
      print('Error fetching popular brands: $e');
      return [];
    }
  }

  // Get brand with upcoming events count
  static Future<Map<String, dynamic>> getBrandWithStats(String brandId) async {
    try {
      final brand = await EventService.getBrand(brandId);
      if (brand == null) return {};

      final events = await EventService.getEvents();
      final brandEvents = events.where((e) => e.brandId == brandId).toList();
      final upcomingEvents = brandEvents
          .where((e) => e.dateStart.isAfter(DateTime.now()))
          .toList();

      return {
        'brand': brand,
        'totalEvents': brandEvents.length,
        'upcomingEvents': upcomingEvents.length,
        'events': upcomingEvents,
      };
    } catch (e) {
      print('Error fetching brand stats: $e');
      return {};
    }
  }
}

