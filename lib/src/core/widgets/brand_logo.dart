import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 52, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/queueless_logo.png',
      height: height,
      fit: fit,
      alignment: Alignment.centerLeft,
      semanticLabel: 'QueueLess logo',
    );
  }
}
