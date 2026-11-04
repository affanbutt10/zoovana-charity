import 'package:dio/dio.dart';

/// `meta` of a paginated list response.
class PageMeta {
  const PageMeta({
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.hasNext = false,
    this.totals = const {},
  });

  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;

  /// Per-status sums some lists return, e.g. payouts' `meta.totals`.
  final Map<String, dynamic> totals;

  factory PageMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PageMeta();
    return PageMeta(
      page: (json['page'] as num? ?? 1).toInt(),
      pageSize: (json['page_size'] as num? ?? 20).toInt(),
      total: (json['total'] as num? ?? 0).toInt(),
      hasNext: json['has_next'] as bool? ?? false,
      totals: json['totals'] is Map
          ? Map<String, dynamic>.from(json['totals'] as Map)
          : const {},
    );
  }
}

class PagedList<T> {
  const PagedList(this.items, [this.meta = const PageMeta()]);

  final List<T> items;
  final PageMeta meta;
}

/// Reads the `{success, message, data, meta}` envelope.
extension ApiEnvelope on Response<dynamic> {
  Map<String, dynamic> get body =>
      data is Map ? Map<String, dynamic>.from(data as Map) : const {};

  Map<String, dynamic> get dataMap {
    final value = body['data'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  List<Map<String, dynamic>> get dataList {
    final value = body['data'];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  PageMeta get meta => PageMeta.fromJson(
    body['meta'] is Map ? Map<String, dynamic>.from(body['meta'] as Map) : null,
  );

  PagedList<T> paged<T>(T Function(Map<String, dynamic> json) parse) =>
      PagedList([for (final item in dataList) parse(item)], meta);
}

/// Typed readers for loosely shaped JSON maps.
extension JsonRead on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    return value == null ? fallback : '$value';
  }

  String? strOrNull(String key) {
    final value = this[key];
    return value == null ? null : '$value';
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  double? decimalOrNull(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse('$value');
  }

  bool flag(String key, [bool fallback = false]) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  DateTime? time(String key) {
    final value = this[key];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }

  Map<String, dynamic>? object(String key) {
    final value = this[key];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  List<Map<String, dynamic>> objects(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  List<String> strings(String key) {
    final value = this[key];
    return value is List ? [for (final item in value) '$item'] : const [];
  }
}
