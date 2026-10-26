import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import 'order_cart.dart';

class MenuCatalog extends ChangeNotifier {
  MenuCatalog._();

  static final instance = MenuCatalog._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  List<MenuItem> _items = [...MenuItem.samples];
  Object? error;

  List<MenuItem> get items => List.unmodifiable(_items);
  List<MenuItem> get availableItems =>
      List.unmodifiable(_items.where((item) => item.isAvailable));

  void start() {
    _subscription ??= FirebaseFirestore.instance
        .collection('menu')
        .snapshots()
        .listen(
          (snapshot) {
            _items = _merge(snapshot.docs);
            orderCart.refreshItems(availableItems);
            error = null;
            notifyListeners();
          },
          onError: (Object value) {
            error = value;
            debugPrint('Menu subscription failed: $value');
            notifyListeners();
          },
        );
  }

  List<MenuItem> _merge(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final defaults = {for (final item in MenuItem.samples) item.id: item};
    final customItems = <MenuItem>[];
    for (final document in documents) {
      final data = document.data();
      if (data['deleted'] == true) {
        defaults.remove(document.id);
        continue;
      }
      final base = defaults[document.id];
      if (base == null) {
        customItems.add(MenuItem.fromFirestore(document.id, data));
      } else {
        defaults[document.id] = MenuItem.fromFirestore(document.id, {
          ...base.toFirestore(),
          ...data,
        });
      }
    }
    return [...defaults.values, ...customItems];
  }

  Future<void> setAvailability(String itemId, bool isAvailable) async {
    final item = _items.where((entry) => entry.id == itemId).firstOrNull;
    if (item == null) return;
    await update(item.copyWith(isAvailable: isAvailable));
  }

  Future<void> add({
    required String name,
    required String description,
    required String category,
    required double price,
    required String imageUrl,
    required bool isPopular,
  }) async {
    final reference = FirebaseFirestore.instance.collection('menu').doc();
    final item = MenuItem(
      id: reference.id,
      name: name,
      description: description,
      category: category,
      price: price,
      imageUrl: imageUrl,
      rating: 5,
      isPopular: isPopular,
    );
    await reference.set(item.toFirestore());
  }

  Future<void> update(MenuItem item) async {
    await FirebaseFirestore.instance
        .collection('menu')
        .doc(item.id)
        .set(item.toFirestore(), SetOptions(merge: true));
  }

  Future<void> delete(String itemId) async {
    await FirebaseFirestore.instance.collection('menu').doc(itemId).set({
      'deleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final menuCatalog = MenuCatalog.instance;
