import 'package:flutter/material.dart';

enum RadiusFilter {
  five(5),
  ten(10),
  twentyFive(25),
  fifty(50);

  final int miles;
  const RadiusFilter(this.miles);
}

enum DateFilter {
  today,
  next3Days,
  next5Days,
  nextWeek;

  String get label {
    switch (this) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.next3Days:
        return 'Next 3 Days';
      case DateFilter.next5Days:
        return 'Next 5 Days';
      case DateFilter.nextWeek:
        return 'Next Week';
    }
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case DateFilter.today:
        return DateTimeRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 1)),
        );
      case DateFilter.next3Days:
        return DateTimeRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 3)),
        );
      case DateFilter.next5Days:
        return DateTimeRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 5)),
        );
      case DateFilter.nextWeek:
        return DateTimeRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 7)),
        );
    }
  }
}

class EventFilters {
  RadiusFilter? radius;
  DateFilter? dateFilter;
  List<String> categoryIds;
  bool show21PlusOnly;

  EventFilters({
    this.radius,
    this.dateFilter,
    this.categoryIds = const [],
    this.show21PlusOnly = false,
  });

  EventFilters copyWith({
    RadiusFilter? radius,
    DateFilter? dateFilter,
    List<String>? categoryIds,
    bool? show21PlusOnly,
  }) {
    return EventFilters(
      radius: radius ?? this.radius,
      dateFilter: dateFilter ?? this.dateFilter,
      categoryIds: categoryIds ?? this.categoryIds,
      show21PlusOnly: show21PlusOnly ?? this.show21PlusOnly,
    );
  }
}

