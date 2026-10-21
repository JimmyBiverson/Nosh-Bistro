import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';

class MenuCatalog extends ChangeNotifier {
  final List<MenuItem> _items = [...MenuItem.samples];

  List<MenuItem> get items => List.unmodifiable(_items);

  void setAvailability(String itemId, bool isAvailable) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1 || _items[index].isAvailable == isAvailable) return;
    _items[index] = _items[index].copyWith(isAvailable: isAvailable);
    notifyListeners();
  }

  void add({
    required String name,
    required String category,
    required double price,
  }) {
    _items.insert(
      0,
      MenuItem(
        id: 'dish-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: 'Freshly prepared by our kitchen.',
        category: category,
        price: price,
        imageUrl: MenuItem.samples.first.imageUrl,
        rating: 5,
      ),
    );
    notifyListeners();
  }
}

final menuCatalog = MenuCatalog();
