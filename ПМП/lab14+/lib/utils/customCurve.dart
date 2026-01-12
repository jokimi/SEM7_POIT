import 'package:flutter/material.dart';

class CustomCurve extends Curve {
  @override
  double transformInternal(double t) {
    final tMinusOne = t - 1.0;
    final power = tMinusOne * tMinusOne * tMinusOne * tMinusOne * tMinusOne;
    return 1.0 + power;
  }
}