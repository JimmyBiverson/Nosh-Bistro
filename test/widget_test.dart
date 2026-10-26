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
import 'package:nosh_bistro/screens/auth/login_screen.dart';
import 'package:nosh_bistro/screens/auth/signup_screen.dart';
import 'package:nosh_bistro/screens/user/commerce_screens.dart';
import 'package:nosh_bistro/state/order_cart.dart';
import 'package:nosh_bistro/services/store_settings.dart';

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

  test('cart pricing uses the current store delivery and tax settings', () {
    final settings = StoreSettings.instance;
    final originalFee = settings.deliveryFee;
    final originalThreshold = settings.freeDeliveryThreshold;
    final originalTaxRate = settings.taxRate;
    final cart = OrderCart();
    final item = MenuItem.samples.first;

    try {
      settings.deliveryFee = 6;
      settings.freeDeliveryThreshold = 100;
      settings.taxRate = 0.1;
      cart.add(item);

      expect(cart.deliveryFee, 6);
      expect(cart.tax, closeTo(item.price * 0.1, 0.001));

      settings.freeDeliveryThreshold = 10;
      expect(cart.deliveryFee, 0);
    } finally {
      cart.clear();
      settings.deliveryFee = originalFee;
      settings.freeDeliveryThreshold = originalThreshold;
      settings.taxRate = originalTaxRate;
    }
  });

  test('menu items preserve editable product fields', () {
    final original = MenuItem.samples.first;
    final edited = original.copyWith(
      name: 'Updated pizza',
      description: 'Updated ingredients',
      category: 'Specials',
      price: 24,
      imageUrl: 'https://example.com/pizza.jpg',
      isPopular: false,
      isAvailable: false,
    );
    final restored = MenuItem.fromFirestore(original.id, edited.toFirestore());

    expect(restored.name, 'Updated pizza');
    expect(restored.description, 'Updated ingredients');
    expect(restored.category, 'Specials');
    expect(restored.price, 24);
    expect(restored.imageUrl, 'https://example.com/pizza.jpg');
    expect(restored.isPopular, isFalse);
    expect(restored.isAvailable, isFalse);
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
        find.textContaining('generated options in main.dart'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sign-in screen offers email and Google authentication', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('sign-up screen offers email and Google account creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2));
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
