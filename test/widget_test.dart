// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:nosh_bistro/models/menu_item.dart';
import 'package:nosh_bistro/main.dart';
import 'package:nosh_bistro/screens/user/commerce_screens.dart';
import 'package:nosh_bistro/state/order_cart.dart';

void main() {
  test('cart totals include delivery and tax and remove empty lines', () {
    final cart = OrderCart();
    final item = MenuItem.samples.first;

    cart.add(item);

    expect(cart.itemCount, 1);
    expect(cart.subtotal, item.price);
    expect(cart.deliveryFee, 3.50);
    expect(cart.tax, closeTo(item.price * 0.08, 0.001));
    expect(cart.total, closeTo(item.price + 3.50 + item.price * 0.08, 0.001));

    cart.removeOne(item.id);

    expect(cart.isEmpty, isTrue);
    expect(cart.total, 0);
  });

  testWidgets('menu presents dishes and adds selected items to the cart', (
    WidgetTester tester,
  ) async {
    orderCart.clear();
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    await tester.pump();

    expect(find.text('Full menu'), findsOneWidget);
    expect(find.text('Wood-fired Margherita'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();

    expect(orderCart.itemCount, 1);
    expect(orderCart.lines.single.item.name, 'Wood-fired Margherita');
    orderCart.clear();
  });

  testWidgets(
    'Firebase startup errors show setup instructions, not a blank app',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const NoshBistroApp(
          startupErrorMessage: 'Firebase Web options are missing.',
        ),
      );

      expect(find.text('Nosh Bistro'), findsOneWidget);
      expect(
        find.text('One setup step before the app can open'),
        findsOneWidget,
      );
      expect(find.text('Firebase Web options are missing.'), findsOneWidget);
      expect(find.text('flutterfire configure'), findsOneWidget);
      expect(
        find.textContaining('DefaultFirebaseOptions.currentPlatform'),
        findsOneWidget,
      );
    },
  );
}
