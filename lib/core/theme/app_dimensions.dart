import 'package:flutter/material.dart';

abstract final class AppDimensions {
  static const spacingUnit = 4.0;
  static const mobileGutter = 16.0;
  static const structuralRadius = 16.0;
  static const functionalRadius = 8.0;
  static const modalRadius = 12.0;
  static const pillRadius = 9999.0;

  static BorderRadius get structuralBorderRadius =>
      BorderRadius.circular(structuralRadius);

  static BorderRadius get functionalBorderRadius =>
      BorderRadius.circular(functionalRadius);

  static BorderRadius get modalBorderRadius =>
      BorderRadius.circular(modalRadius);
}
