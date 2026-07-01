// lib/viewmodels/marketplace_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/marketplace_model.dart';
import '../models/user_model.dart';
import '../services/firebase_marketplace_service.dart';

class MarketplaceViewModel extends ChangeNotifier {
  final FirebaseMarketplaceService _service = FirebaseMarketplaceService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  FirebaseMarketplaceService get service => _service;

  Future<bool> createItem({
    required UserModel organizer,
    required String title,
    required String description,
    required double price,
    required int quantity,
    String? imageUrl,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _error = 'Add an item name and description.';
      notifyListeners();
      return false;
    }
    if (price <= 0) {
      _error = 'Enter a valid price.';
      notifyListeners();
      return false;
    }
    if (quantity <= 0) {
      _error = 'Quantity must be at least 1.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createItem(
        organizer: organizer,
        title: title,
        description: description,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteItem(itemId: itemId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewItem({
    required String itemId,
    required String adminId,
    required MarketplaceItemStatus status,
    String? adminNotes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.reviewItem(
        itemId: itemId,
        adminId: adminId,
        status: status,
        adminNotes: adminNotes,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateItemAvailability(
        itemId: itemId,
        isAvailable: isAvailable,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<MarketplacePurchaseModel?> placeOrder({
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
    if ([recipientName, phone, addressLine1, city, state, postcode]
        .any((value) => value.trim().isEmpty)) {
      _error = 'Complete all required postage details.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final purchase = await _service.createPurchase(
        item: item,
        buyer: buyer,
        recipientName: recipientName,
        phone: phone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        postcode: postcode,
        deliveryInstructions: deliveryInstructions,
      );
      _isLoading = false;
      notifyListeners();
      return purchase;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateOrderStatus({
    required String purchaseId,
    required MarketplacePurchaseStatus status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updatePurchaseStatus(
        purchaseId: purchaseId,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
