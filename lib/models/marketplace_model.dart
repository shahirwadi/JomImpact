// lib/models/marketplace_model.dart

import '../utils/enum_utils.dart';

enum MarketplaceItemStatus { pending, approved, rejected }

enum MarketplacePurchaseStatus { pendingPayment }

class MarketplaceItemModel {
  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final MarketplaceItemStatus status;
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  MarketplaceItemModel({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    this.status = MarketplaceItemStatus.pending,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'status': enumValueName(status),
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MarketplaceItemModel.fromMap(Map<String, dynamic> map) {
    return MarketplaceItemModel(
      id: map['id'],
      organizerId: map['organizerId'],
      organizerName: map['organizerName'],
      title: map['title'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      status: enumFromName(MarketplaceItemStatus.values, map['status']),
      adminNotes: map['adminNotes'],
      reviewedBy: map['reviewedBy'],
      reviewedAt:
          map['reviewedAt'] == null ? null : DateTime.parse(map['reviewedAt']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class MarketplacePurchaseModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String organizerId;
  final String buyerId;
  final String buyerName;
  final double price;
  final MarketplacePurchaseStatus status;
  final DateTime createdAt;

  MarketplacePurchaseModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.organizerId,
    required this.buyerId,
    required this.buyerName,
    required this.price,
    this.status = MarketplacePurchaseStatus.pendingPayment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'organizerId': organizerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'price': price,
      'status': enumValueName(status),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
