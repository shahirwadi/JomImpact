// lib/services/firebase_marketplace_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/marketplace_model.dart';
import '../models/user_model.dart';
import '../utils/enum_utils.dart';

class FirebaseMarketplaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('marketplaceItems');
  CollectionReference<Map<String, dynamic>> get _purchases =>
      _db.collection('marketplacePurchases');

  Stream<List<MarketplaceItemModel>> approvedItemsStream() {
    return _items
        .where('status',
            isEqualTo: enumValueName(MarketplaceItemStatus.approved))
        .snapshots()
        .map((snap) => _sortNewestFirst(snap.docs
            .map((doc) => MarketplaceItemModel.fromMap(doc.data()))
            .toList()));
  }

  Stream<List<MarketplaceItemModel>> organizerItemsStream(String organizerId) {
    return _items.where('organizerId', isEqualTo: organizerId).snapshots().map(
        (snap) => _sortNewestFirst(snap.docs
            .map((doc) => MarketplaceItemModel.fromMap(doc.data()))
            .toList()));
  }

  Stream<List<MarketplaceItemModel>> pendingItemsStream() {
    return _items
        .where('status',
            isEqualTo: enumValueName(MarketplaceItemStatus.pending))
        .snapshots()
        .map((snap) => _sortNewestFirst(snap.docs
            .map((doc) => MarketplaceItemModel.fromMap(doc.data()))
            .toList()));
  }

  Stream<List<MarketplacePurchaseModel>> buyerPurchasesStream(String buyerId) {
    return _purchases.where('buyerId', isEqualTo: buyerId).snapshots().map(
        (snap) => _sortPurchasesNewestFirst(snap.docs
            .map((doc) => MarketplacePurchaseModel.fromMap(doc.data()))
            .toList()));
  }

  Stream<List<MarketplacePurchaseModel>> organizerPurchasesStream(
      String organizerId) {
    return _purchases
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) => _sortPurchasesNewestFirst(snap.docs
            .map((doc) => MarketplacePurchaseModel.fromMap(doc.data()))
            .toList()));
  }

  List<MarketplacePurchaseModel> _sortPurchasesNewestFirst(
      List<MarketplacePurchaseModel> purchases) {
    return purchases..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<MarketplaceItemModel> _sortNewestFirst(
      List<MarketplaceItemModel> items) {
    return items..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> createItem({
    required UserModel organizer,
    required String title,
    required String description,
    required double price,
    String? imageUrl,
  }) async {
    final item = MarketplaceItemModel(
      id: _uuid.v4(),
      organizerId: organizer.id,
      organizerName: organizer.name,
      title: title.trim(),
      description: description.trim(),
      price: price,
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      createdAt: DateTime.now(),
    );

    await _items.doc(item.id).set(item.toMap());
  }

  Future<void> reviewItem({
    required String itemId,
    required String adminId,
    required MarketplaceItemStatus status,
    String? adminNotes,
  }) async {
    await _items.doc(itemId).update({
      'status': enumValueName(status),
      'adminNotes':
          adminNotes?.trim().isEmpty == true ? null : adminNotes?.trim(),
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    await _items.doc(itemId).update({'isAvailable': isAvailable});
  }

  Future<MarketplacePurchaseModel> createPurchase({
    required MarketplaceItemModel item,
    required UserModel buyer,
    required String recipientName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postcode,
    String? deliveryInstructions,
  }) async {
    final now = DateTime.now();
    final purchase = MarketplacePurchaseModel(
      id: _uuid.v4(),
      itemId: item.id,
      itemTitle: item.title,
      organizerId: item.organizerId,
      buyerId: buyer.id,
      buyerName: buyer.name,
      buyerEmail: buyer.email,
      recipientName: recipientName.trim(),
      phone: phone.trim(),
      addressLine1: addressLine1.trim(),
      addressLine2:
          addressLine2?.trim().isEmpty == true ? null : addressLine2?.trim(),
      city: city.trim(),
      state: state.trim(),
      postcode: postcode.trim(),
      deliveryInstructions: deliveryInstructions?.trim().isEmpty == true
          ? null
          : deliveryInstructions?.trim(),
      price: item.price,
      createdAt: now,
      updatedAt: now,
    );

    await _purchases.doc(purchase.id).set(purchase.toMap());
    return purchase;
  }

  Future<void> updatePurchaseStatus({
    required String purchaseId,
    required MarketplacePurchaseStatus status,
  }) async {
    await _purchases.doc(purchaseId).update({
      'status': enumValueName(status),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
