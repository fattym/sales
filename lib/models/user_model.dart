import 'package:uuid/uuid.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? region;
  final int
  role; // 1 = admin, 2 = sales manager, 3 = BAS, 4 = agent, 5 = grounds person
  final bool isSynced; // For local/remote sync status

  UserModel({
    String? id,
    required this.email,
    this.fullName,
    this.phone,
    this.region,
    this.role = 5, // Default role is lowest tier
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'isSynced': isSynced,
    };

    if (region != null) {
      map['region'] = region;
    }

    return map;
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      phone: map['phone'],
      region: map['region'],
      role: _parseRole(map['role']),
      isSynced: map['isSynced'] ?? false,
    );
  }

  static int _parseRole(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final lower = value.toLowerCase();
      if (lower == 'admin' || lower == 'superadmin') return 1;
      if (lower == 'sales manager') return 2;
      if (lower == 'bas') return 3;
      if (lower == 'agent' || lower == 'field agent') return 4;
      if (lower == 'grounds person') return 5;
    }
    return 5; // Default to lowest tier
  }
}
