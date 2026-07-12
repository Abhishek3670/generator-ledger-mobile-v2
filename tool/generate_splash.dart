// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('logo.png');
  final logoBytes = logoFile.readAsBytesSync();
  final logo = img.decodeImage(logoBytes)!;

  // The original logo has rounded corners with dark artifacts.
  // Crop the inner content area (skip the rounded corner edges ~60px each side)
  // and the "Genset" text at the bottom (below ~880px)
  final cropped = img.copyCrop(logo, x: 60, y: 60, width: 960, height: 800);

  // 1. Create splash image - logo centered on navy canvas, larger size
  final splashSize = 1920;
  final splash = img.Image(width: splashSize, height: splashSize);
  img.fill(splash, color: img.ColorRgba8(15, 23, 42, 255)); // #0f172a

  // Scale cropped icon to 800px wide (bigger than before)
  final scaledLogo = img.copyResize(cropped, width: 800);
  final offsetX = (splashSize - scaledLogo.width) ~/ 2;
  final offsetY = (splashSize - scaledLogo.height) ~/ 2;
  img.compositeImage(splash, scaledLogo, dstX: offsetX, dstY: offsetY);

  File('splash_logo.png').writeAsBytesSync(img.encodePng(splash));
  print('Created splash_logo.png (1920x1920, clean icon, no text)');

  // 2. Android 12 icon (needs to be square, icon-only, no artifacts)
  final iconSize = 1152; // Android 12 recommends 1152x1152
  final iconCanvas = img.Image(width: iconSize, height: iconSize);
  img.fill(iconCanvas, color: img.ColorRgba8(15, 23, 42, 255));

  final scaledIcon = img.copyResize(cropped, width: 720);
  final iconOffsetX = (iconSize - scaledIcon.width) ~/ 2;
  final iconOffsetY = (iconSize - scaledIcon.height) ~/ 2;
  img.compositeImage(iconCanvas, scaledIcon, dstX: iconOffsetX, dstY: iconOffsetY);

  File('splash_icon_only.png').writeAsBytesSync(img.encodePng(iconCanvas));
  print('Created splash_icon_only.png (1152x1152, clean icon for Android 12)');
}
