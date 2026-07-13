// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('logo.png');
  final logoBytes = logoFile.readAsBytesSync();
  final logo = img.decodeImage(logoBytes)!;

  // The logo has transparent corners. Fill ALL pixels with low alpha
  // with the splash background color so it blends seamlessly.
  final navyR = 15;
  final navyG = 23;
  final navyB = 42;
  final navyColor = img.ColorRgba8(navyR, navyG, navyB, 255);

  // Create a navy background and composite the logo on top
  final flatLogo = img.Image(width: logo.width, height: logo.height);
  img.fill(flatLogo, color: navyColor);
  img.compositeImage(flatLogo, logo);

  // 1. Splash image: flattened logo centered at 480px on 1920 navy canvas
  final splashSize = 1920;
  final splash = img.Image(width: splashSize, height: splashSize);
  img.fill(splash, color: navyColor);

  final scaledLogo = img.copyResize(flatLogo, width: 480, height: 480);
  final offsetX = (splashSize - 480) ~/ 2;
  final offsetY = (splashSize - 480) ~/ 2;
  img.compositeImage(splash, scaledLogo, dstX: offsetX, dstY: offsetY);

  File('splash_logo.png').writeAsBytesSync(img.encodePng(splash));
  print('Created splash_logo.png (1920x1920, flattened logo, no artifacts)');

  // 2. Android 12 icon: flattened logo at 600px on 1152 navy canvas
  final iconSize = 1152;
  final iconCanvas = img.Image(width: iconSize, height: iconSize);
  img.fill(iconCanvas, color: navyColor);

  final scaledIcon = img.copyResize(flatLogo, width: 600, height: 600);
  final iconOffsetX = (iconSize - 600) ~/ 2;
  final iconOffsetY = (iconSize - 600) ~/ 2;
  img.compositeImage(iconCanvas, scaledIcon, dstX: iconOffsetX, dstY: iconOffsetY);

  File('splash_icon_only.png').writeAsBytesSync(img.encodePng(iconCanvas));
  print('Created splash_icon_only.png (1152x1152, flattened logo, no artifacts)');
}
