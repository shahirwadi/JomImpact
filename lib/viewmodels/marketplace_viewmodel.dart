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

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createItem(
        organizer: organizer,
        title: title,
        description: description,
        price: price,
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

  Future<bool> buyItem({
    required MarketplaceItemModel item,
    required UserModel buyer,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createPurchase(item: item, buyer: buyer);
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
