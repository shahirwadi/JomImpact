// lib/models/marketplace_model.dart

import '../utils/enum_utils.dart';

enum MarketplaceItemStatus { pending, approved, rejected }

enum MarketplacePurchaseStatus {
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

enum MarketplacePaymentStatus { notCollected }

class MarketplaceItemModel {
  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
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
    this.isAvailable = true,
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
      'isAvailable': isAvailable,
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
      isAvailable: map['isAvailable'] ?? true,
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
  final String buyerEmail;
  final String recipientName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? deliveryInstructions;
  final double price;
  final MarketplacePurchaseStatus status;
  final MarketplacePaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplacePurchaseModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.organizerId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.recipientName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'Malaysia',
    this.deliveryInstructions,
    required this.price,
    this.status = MarketplacePurchaseStatus.confirmed,
    this.paymentStatus = MarketplacePaymentStatus.notCollected,
    required this.createdAt,
    required this.updatedAt,
  });

  String get orderNumber =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String get formattedAddress => [
        addressLine1,
        if ((addressLine2 ?? '').isNotEmpty) addressLine2!,
        '$postcode $city',
        state,
        country,
      ].join(', ');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'organizerId': organizerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'recipientName': recipientName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'deliveryInstructions': deliveryInstructions,
      'price': price,
      'status': enumValueName(status),
      'paymentStatus': enumValueName(paymentStatus),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MarketplacePurchaseModel.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['createdAt']);
    final rawStatus = map['status'] == 'pendingPayment'
        ? enumValueName(MarketplacePurchaseStatus.confirmed)
        : map['status'] ?? enumValueName(MarketplacePurchaseStatus.confirmed);
    return MarketplacePurchaseModel(
      id: map['id'],
      itemId: map['itemId'],
      itemTitle: map['itemTitle'],
      organizerId: map['organizerId'],
      buyerId: map['buyerId'],
      buyerName: map['buyerName'],
      buyerEmail: map['buyerEmail'] ?? '',
      recipientName: map['recipientName'] ?? map['buyerName'],
      phone: map['phone'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postcode: map['postcode'] ?? '',
      country: map['country'] ?? 'Malaysia',
      deliveryInstructions: map['deliveryInstructions'],
      price: (map['price'] as num).toDouble(),
      status: enumFromName(MarketplacePurchaseStatus.values, rawStatus),
      paymentStatus: enumFromName(
        MarketplacePaymentStatus.values,
        map['paymentStatus'] ??
            enumValueName(MarketplacePaymentStatus.notCollected),
      ),
      createdAt: createdAt,
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['createdAt']),
    );
  }
}
