// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('logo.png');
  final logoBytes = logoFile.readAsBytesSync();
  final logo = img.decodeImage(logoBytes)!;

  final navyColor = img.ColorRgba8(15, 23, 42, 255); // #0f172a

  // 1. Splash image: icon centered at 500px on 1920 navy canvas
  final splashSize = 1920;
  final splash = img.Image(width: splashSize, height: splashSize);
  img.fill(splash, color: navyColor);

  final scaledLogo = img.copyResize(logo, width: 500);
  final offsetX = (splashSize - scaledLogo.width) ~/ 2;
  final offsetY = (splashSize - scaledLogo.height) ~/ 2 - 40; // nudge up for optical center
  img.compositeImage(splash, scaledLogo, dstX: offsetX, dstY: offsetY);

  File('splash_logo.png').writeAsBytesSync(img.encodePng(splash));
  print('Created splash_logo.png (1920x1920, icon 500px on navy)');

  // 2. Android 12 icon: icon at 650px on 1152 navy canvas
  final iconSize = 1152;
  final iconCanvas = img.Image(width: iconSize, height: iconSize);
  img.fill(iconCanvas, color: navyColor);

  final scaledIcon = img.copyResize(logo, width: 650);
  final iconOffsetX = (iconSize - scaledIcon.width) ~/ 2;
  final iconOffsetY = (iconSize - scaledIcon.height) ~/ 2 - 30; // nudge up for optical center
  img.compositeImage(iconCanvas, scaledIcon, dstX: iconOffsetX, dstY: iconOffsetY);

  File('splash_icon_only.png').writeAsBytesSync(img.encodePng(iconCanvas));
  print('Created splash_icon_only.png (1152x1152, icon 650px on navy)');
}
