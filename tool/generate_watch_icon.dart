// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates the watchOS app icon.
///
/// Deliberately different from `generate_icon.dart`:
///  - **Full-bleed square, no rounded corners.** watchOS applies its own
///    circular mask; baking in a rounded rect would just get clipped.
///  - **No alpha channel.** App Store validation rejects icons containing
///    transparency, and a masked corner would otherwise stay transparent.
/// The artwork itself (amber gradient + clock) matches the phone icon.
void main() {
  const size = 1024;
  // numChannels: 3 -> RGB, so the encoded PNG carries no alpha channel.
  final image = img.Image(width: size, height: size, numChannels: 3);

  final white = img.ColorRgb8(0xFF, 0xFF, 0xFF);

  // Vertical gradient: AppTheme.primary -> AppTheme.primaryLight.
  for (int y = 0; y < size; y++) {
    final t = y / size;
    final color = img.ColorRgb8(
      _lerp(0xE8, 0xF2, t),
      _lerp(0x98, 0xB8, t),
      _lerp(0x5A, 0x82, t),
    );
    for (int x = 0; x < size; x++) {
      image.setPixel(x, y, color);
    }
  }

  const cx = size ~/ 2;
  const cy = size ~/ 2;
  const clockRadius = 280;
  const lineWidth = 44;
  const halfLine = lineWidth ~/ 2;

  // Clock ring
  for (int y = cy - clockRadius - halfLine; y <= cy + clockRadius + halfLine; y++) {
    for (int x = cx - clockRadius - halfLine; x <= cx + clockRadius + halfLine; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist >= clockRadius - halfLine && dist <= clockRadius + halfLine) {
        image.setPixel(x, y, white);
      }
    }
  }

  // Center dot
  const dotRadius = 30;
  for (int y = cy - dotRadius; y <= cy + dotRadius; y++) {
    for (int x = cx - dotRadius; x <= cx + dotRadius; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist <= dotRadius) image.setPixel(x, y, white);
    }
  }

  // Hour hand (10 o'clock) and minute hand (12 o'clock)
  const hourAngle = -60.0 * pi / 180;
  _drawLine(image, cx, cy, cx + (160 * cos(hourAngle)).round(),
      cy + (160 * sin(hourAngle)).round(), halfLine, white);

  const minuteAngle = -90.0 * pi / 180;
  _drawLine(image, cx, cy, cx + (220 * cos(minuteAngle)).round(),
      cy + (220 * sin(minuteAngle)).round(), halfLine ~/ 2 + 6, white);

  const outputPath =
      'ios/ChangeWatch/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png';
  Directory(File(outputPath).parent.path).createSync(recursive: true);
  final png = img.encodePng(image);
  File(outputPath).writeAsBytesSync(png);
  print('Watch icon generated: $outputPath (${png.length} bytes)');
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

void _drawLine(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int thickness,
  img.Color color,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final steps = max(dx.abs(), dy.abs());
  if (steps == 0) return;

  for (int i = 0; i <= steps; i++) {
    final x = x1 + (dx * i / steps).round();
    final y = y1 + (dy * i / steps).round();
    for (int oy = -thickness; oy <= thickness; oy++) {
      for (int ox = -thickness; ox <= thickness; ox++) {
        if (sqrt(ox * ox + oy * oy) <= thickness) {
          final px = x + ox;
          final py = y + oy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }
}
