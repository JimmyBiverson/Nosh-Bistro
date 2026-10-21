import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';

class CartLine {
  CartLine({required this.item, this.quantity = 1});

  final MenuItem item;
  int quantity;

  double get total => item.price * quantity;
}

class OrderCart extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => _lines.values.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => _lines.isEmpty || subtotal >= 35 ? 0 : 3.50;
  double get tax => subtotal * 0.08;
  double get total => subtotal + deliveryFee + tax;
  bool get isEmpty => _lines.isEmpty;

  void add(MenuItem item) {
    final line = _lines[item.id];
    if (line == null) {
      _lines[item.id] = CartLine(item: item);
    } else {
      line.quantity++;
    }
    notifyListeners();
  }

  void removeOne(String itemId) {
    final line = _lines[itemId];
    if (line == null) return;
    if (line.quantity <= 1) {
      _lines.remove(itemId);
    } else {
      line.quantity--;
    }
    notifyListeners();
  }

  void remove(String itemId) {
    if (_lines.remove(itemId) != null) notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

final orderCart = OrderCart();
