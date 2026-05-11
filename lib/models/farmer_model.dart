import 'package:uuid/uuid.dart';

class SchoolModel {
  final String id;
  final String name;
  final String phone;
  final String county;
  final List<String> focusAreas;
  final String? bookCategory;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? photoPath;
  final String? capturedBy;
  final DateTime? capturedAt;
  final String? captureStatus;
  final bool isSynced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolModel({
    String? id,
    required this.name,
    required this.phone,
    required this.county,
    required this.focusAreas,
    this.bookCategory,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.photoPath,
    this.capturedBy,
    this.capturedAt,
    this.captureStatus,
    this.isSynced = false,
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'county': county,
      'focusAreas': focusAreas,
      'book_category': bookCategory,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'photo_path': photoPath,
      'captured_by': capturedBy,
      'captured_at': capturedAt?.toIso8601String(),
      'capture_status': captureStatus,
      'isSynced': isSynced,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SchoolModel.fromMap(Map<dynamic, dynamic> map) {
    return SchoolModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      county: map['county'],
      focusAreas: List<String>.from(map['focusAreas'] ?? const []),
      bookCategory: map['book_category'] ?? map['bookCategory'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photoUrl: map['photo_url'] ?? map['photoUrl'],
      photoPath: map['photo_path'] ?? map['photoPath'],
      capturedBy: map['captured_by'] ?? map['capturedBy'],
      capturedAt: _parseDate(map['captured_at'] ?? map['capturedAt']),
      captureStatus: map['capture_status'] ?? map['captureStatus'],
      isSynced: map['isSynced'] ?? false,
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDate(map['updated_at'] ?? map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  SchoolModel copyWithSynced(bool value) {
    return SchoolModel(
      id: id,
      name: name,
      phone: phone,
      county: county,
      focusAreas: focusAreas,
      bookCategory: bookCategory,
      latitude: latitude,
      longitude: longitude,
      photoUrl: photoUrl,
      photoPath: photoPath,
      capturedBy: capturedBy,
      capturedAt: capturedAt,
      captureStatus: captureStatus,
      isSynced: value,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
