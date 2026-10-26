import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'web_favicon.dart';

class StoreSettings extends ChangeNotifier {
  StoreSettings._();

  static final instance = StoreSettings._();

  static const collection = 'store_settings';
  static const document = 'public';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  Object? error;

  String appName = 'Nosh Bistro';
  String restaurantName = 'The Flame Bistro';
  String tagline = 'A little fire. A lot of flavor.';
  String description =
      'A neighborhood kitchen bringing a little fire and a lot of heart to every plate. Made fresh, sourced thoughtfully, delivered warm.';
  String heroImageUrl =
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=90';
  String logoUrl = '';
  String phone = '';
  String address = 'Downtown, 10001';
  String businessHours = 'Every day, 11:00 AM – 10:00 PM';
  String estimatedDeliveryTime = '25–35 min';
  bool orderingEnabled = true;
  double deliveryFee = 3.50;
  double freeDeliveryThreshold = 35;
  double taxRate = 0.08;
  int primaryColor = 0xFFFF6D00;
  int backgroundColor = 0xFF1C110A;

  DocumentReference<Map<String, dynamic>> get _document =>
      FirebaseFirestore.instance.collection(collection).doc(document);

  void start() {
    _subscription ??= _document.snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null) _read(data);
        error = null;
        notifyListeners();
      },
      onError: (Object value) {
        error = value;
        debugPrint('Store settings subscription failed: $value');
        notifyListeners();
      },
    );
  }

  void _read(Map<String, dynamic> data) {
    appName = _string(data, 'appName', appName);
    restaurantName = _string(data, 'restaurantName', restaurantName);
    tagline = _string(data, 'tagline', tagline);
    description = _string(data, 'description', description);
    heroImageUrl = _string(data, 'heroImageUrl', heroImageUrl);
    logoUrl = _string(data, 'logoUrl', logoUrl);
    updateWebFavicon(logoUrl);
    phone = _string(data, 'phone', phone);
    address = _string(data, 'address', address);
    businessHours = _string(data, 'businessHours', businessHours);
    estimatedDeliveryTime = _string(
      data,
      'estimatedDeliveryTime',
      estimatedDeliveryTime,
    );
    orderingEnabled = data['orderingEnabled'] is bool
        ? data['orderingEnabled'] as bool
        : orderingEnabled;
    deliveryFee = _number(data, 'deliveryFee', deliveryFee);
    freeDeliveryThreshold = _number(
      data,
      'freeDeliveryThreshold',
      freeDeliveryThreshold,
    );
    taxRate = _number(data, 'taxRate', taxRate).clamp(0, 1);
    primaryColor = _integer(data, 'primaryColor', primaryColor);
    backgroundColor = _integer(data, 'backgroundColor', backgroundColor);
  }

  Future<void> save(Map<String, Object?> values) async {
    await _document.set(values, SetOptions(merge: true));
  }

  static String _string(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    return value is String ? value : fallback;
  }

  static double _number(
    Map<String, dynamic> data,
    String key,
    double fallback,
  ) {
    final value = data[key];
    return value is num ? value.toDouble() : fallback;
  }

  static int _integer(Map<String, dynamic> data, String key, int fallback) {
    final value = data[key];
    return value is num ? value.toInt() : fallback;
  }
}

class StoreBrandName extends StatelessWidget {
  const StoreBrandName({
    this.style,
    this.uppercase = false,
    this.prefix = '',
    this.suffix = '',
    super.key,
  });

  final TextStyle? style;
  final bool uppercase;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StoreSettings.instance,
    builder: (context, _) {
      final name = StoreSettings.instance.appName;
      final value = uppercase ? name.toUpperCase() : name;
      return Text('$prefix$value$suffix', style: style);
    },
  );
}

class StoreBrandLogo extends StatelessWidget {
  const StoreBrandLogo({
    required this.size,
    this.color = const Color(0xFFFF6D00),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StoreSettings.instance,
    builder: (context, _) {
      final url = StoreSettings.instance.logoUrl;
      if (url.isEmpty) {
        return Icon(
          Icons.local_fire_department_rounded,
          color: color,
          size: size,
        );
      }
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.local_fire_department_rounded, color: color, size: size),
      );
    },
  );
}
