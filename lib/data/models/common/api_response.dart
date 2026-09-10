/// Generic API wrapper: { success, message, data, count, ... }
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? count;
  final Map<String, dynamic>? raw;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.count,
    this.raw,
  });

  /// Parse single Object / Primitive Data
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromData,
  ) {
    T? parsed;
    final rawData = json['data'];

    if (rawData != null) {
      if (fromData != null) {
        parsed = fromData(rawData);
      } else if (rawData is T) {
        parsed = rawData;
      }
    }

    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: parsed,
      count: _parseCount(json['count']),
      raw: json,
    );
  }

  /// Parse List Data — static helper karena factory tidak boleh ubah `T` menjadi `List<T>`
  static ApiResponse<List<E>> listFromJson<E>(
    Map<String, dynamic> json,
    E Function(Map<String, dynamic> json) fromItem,
  ) {
    final rawList = json['data'];
    List<E>? list;

    if (rawList is List) {
      list = rawList.map((e) {
        if (e is Map<String, dynamic>) {
          return fromItem(e);
        } else if (e is Map) {
          return fromItem(Map<String, dynamic>.from(e));
        }
        // Skip elemen invalid (null/String/int) — jangan abort seluruh list
        return null;
      }).whereType<E>().toList();
    }

    final parsedCount = _parseCount(json['count']);

    return ApiResponse<List<E>>(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: list,
      count: parsedCount ?? list?.length,
      raw: json,
    );
  }

  /// Factory helper untuk menangani error response / catch block
  factory ApiResponse.failure(String message, {Map<String, dynamic>? raw}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      count: null,
      raw: raw,
    );
  }

  /// Helper internal untuk parse field 'count' secara aman
  static int? _parseCount(dynamic countRaw) {
    if (countRaw is int) return countRaw;
    if (countRaw != null) return int.tryParse('$countRaw');
    return null;
  }
}

/// Pagination / summary helper for list endpoints
class PaginatedResult<T> {
  final List<T> items;
  final int count;
  final String? message;

  const PaginatedResult({
    required this.items,
    required this.count,
    this.message,
  });

  factory PaginatedResult.fromResponse(
    ApiResponse<List<T>> response, {
    List<T> defaultItems = const [],
  }) {
    final items = response.data ?? defaultItems;
    return PaginatedResult<T>(
      items: items,
      count: response.count ?? items.length,
      message: response.message,
    );
  }
}