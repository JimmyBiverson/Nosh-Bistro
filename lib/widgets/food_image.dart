import 'package:flutter/material.dart';

import '../theme/nosh_theme.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({
    required this.url,
    this.height,
    this.width,
    this.borderRadius = 18,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double? height;
  final double? width;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: width,
          color: NoshTheme.surfaceHigh,
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_rounded,
            color: NoshTheme.primarySoft,
            size: 34,
          ),
        ),
      ),
    );
  }
}
