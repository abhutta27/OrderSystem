import 'package:flutter/material.dart';

/// Represents a tenant restaurant / business in the white-label platform.
class StoreModel {
  final String id;
  final String name;
  final String slug;
  final String storeCode;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final bool isActive;
  final bool isBusy;
  final DateTime createdAt;

  StoreModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.storeCode,
    this.logoUrl,
    this.primaryColor = '#1976D2',
    this.secondaryColor = '#FF9800',
    this.isActive = true,
    this.isBusy = false,
    required this.createdAt,
  });

  /// Factory constructor to parse StoreModel from Supabase JSON response
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      storeCode: json['store_code'] as String,
      logoUrl: json['logo_url'] as String?,
      primaryColor: (json['primary_color'] as String?)?.isNotEmpty == true
          ? json['primary_color'] as String
          : '#1976D2',
      secondaryColor: (json['secondary_color'] as String?)?.isNotEmpty == true
          ? json['secondary_color'] as String
          : '#FF9800',
      isActive: json['is_active'] as bool? ?? true,
      isBusy: json['is_busy'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts StoreModel to JSON map for Supabase operations / local cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'store_code': storeCode,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'is_active': isActive,
      'is_busy': isBusy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Immutability helper for state transitions
  StoreModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? storeCode,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    bool? isActive,
    bool? isBusy,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      storeCode: storeCode ?? this.storeCode,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isActive: isActive ?? this.isActive,
      isBusy: isBusy ?? this.isBusy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper to convert hex string (#RRGGBB) to Flutter Color
  Color get primaryColorObject => _parseColor(primaryColor, const Color(0xFF1976D2));
  Color get secondaryColorObject => _parseColor(secondaryColor, const Color(0xFFFF9800));

  static Color _parseColor(String hexString, Color fallback) {
    try {
      final buffer = StringBuffer();
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) buffer.write('ff');
      buffer.write(hex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeCode == other.storeCode &&
          isActive == other.isActive &&
          isBusy == other.isBusy;

  @override
  int get hashCode =>
      id.hashCode ^ storeCode.hashCode ^ isActive.hashCode ^ isBusy.hashCode;
}
