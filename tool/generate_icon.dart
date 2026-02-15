// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Colors matching AppTheme
  final white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

  // Draw rounded rectangle background with gradient
  const radius = 220;
  for (int y = 0; y < size; y++) {
    // Gradient interpolation (top-left to bottom-right)
    final t = (y / size);
    final r = _lerp(0xE8, 0xF2, t);
    final g = _lerp(0x98, 0xB8, t);
    final b = _lerp(0x5A, 0x82, t);
    final gradColor = img.ColorRgba8(r, g, b, 0xFF);

    for (int x = 0; x < size; x++) {
      if (_isInsideRoundedRect(x, y, 0, 0, size, size, radius)) {
        image.setPixel(x, y, gradColor);
      }
    }
  }

  // Draw clock icon (white)
  const cx = size ~/ 2; // center x
  const cy = size ~/ 2; // center y
  const clockRadius = 280;
  const lineWidth = 44;
  const halfLine = lineWidth ~/ 2;

  // Clock circle (ring)
  for (int y = cy - clockRadius - halfLine; y <= cy + clockRadius + halfLine; y++) {
    for (int x = cx - clockRadius - halfLine; x <= cx + clockRadius + halfLine; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist >= clockRadius - halfLine && dist <= clockRadius + halfLine) {
        image.setPixel(x, y, white);
      }
    }
  }

  // Clock center dot
  const dotRadius = 30;
  for (int y = cy - dotRadius; y <= cy + dotRadius; y++) {
    for (int x = cx - dotRadius; x <= cx + dotRadius; x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (dist <= dotRadius) {
        image.setPixel(x, y, white);
      }
    }
  }

  // Hour hand (pointing to 10 o'clock position, ~300 degrees or -60 degrees)
  const hourLen = 160;
  const hourAngle = -60.0 * pi / 180; // 10 o'clock
  _drawLine(image, cx, cy,
      cx + (hourLen * cos(hourAngle)).round(),
      cy + (hourLen * sin(hourAngle)).round(),
      halfLine, white);

  // Minute hand (pointing to 12 o'clock, straight up)
  const minuteLen = 220;
  const minuteAngle = -90.0 * pi / 180; // 12 o'clock
  _drawLine(image, cx, cy,
      cx + (minuteLen * cos(minuteAngle)).round(),
      cy + (minuteLen * sin(minuteAngle)).round(),
      halfLine ~/ 2 + 6, white);

  // Small hour markers
  for (int i = 0; i < 12; i++) {
    final angle = (i * 30 - 90) * pi / 180;
    final innerR = clockRadius - halfLine - 20;
    final outerR = clockRadius - halfLine + 4;
    final markerWidth = (i % 3 == 0) ? 14 : 8;
    // Draw small tick marks
    for (double r = innerR.toDouble(); r <= outerR; r += 0.5) {
      final px = cx + (r * cos(angle)).round();
      final py = cy + (r * sin(angle)).round();
      for (int dy = -markerWidth; dy <= markerWidth; dy++) {
        for (int dx = -markerWidth; dx <= markerWidth; dx++) {
          final dist = sqrt(dx * dx + dy * dy);
          if (dist <= markerWidth / 2) {
            final fx = px + (dx * sin(angle)).round() + (dy * cos(angle)).round();
            final fy = py - (dx * cos(angle)).round() + (dy * sin(angle)).round();
            if (fx >= 0 && fx < size && fy >= 0 && fy < size) {
              // Only draw if already inside rounded rect
              if (_isInsideRoundedRect(fx, fy, 0, 0, size, size, radius)) {
                // skip - hour markers make it too busy at small size
              }
            }
          }
        }
      }
    }
  }

  // Encode as PNG
  final png = img.encodePng(image);
  final outputPath = 'assets/icon/app_icon.png';
  File(outputPath).writeAsBytesSync(png);
  print('Icon generated: $outputPath (${png.length} bytes)');
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

bool _isInsideRoundedRect(int x, int y, int left, int top, int right, int bottom, int radius) {
  if (x < left || x >= right || y < top || y >= bottom) return false;

  // Check corners
  if (x < left + radius && y < top + radius) {
    return _dist(x, y, left + radius, top + radius) <= radius;
  }
  if (x >= right - radius && y < top + radius) {
    return _dist(x, y, right - radius, top + radius) <= radius;
  }
  if (x < left + radius && y >= bottom - radius) {
    return _dist(x, y, left + radius, bottom - radius) <= radius;
  }
  if (x >= right - radius && y >= bottom - radius) {
    return _dist(x, y, right - radius, bottom - radius) <= radius;
  }
  return true;
}

double _dist(int x1, int y1, int x2, int y2) {
  return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}

void _drawLine(img.Image image, int x1, int y1, int x2, int y2, int thickness, img.Color color) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = sqrt(dx * dx + dy * dy);
  if (len == 0) return;

  final steps = (len * 2).ceil();
  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final px = x1 + (dx * t);
    final py = y1 + (dy * t);
    // Draw circle at each point for thickness
    for (int oy = -thickness; oy <= thickness; oy++) {
      for (int ox = -thickness; ox <= thickness; ox++) {
        if (ox * ox + oy * oy <= thickness * thickness) {
          final fx = (px + ox).round();
          final fy = (py + oy).round();
          if (fx >= 0 && fx < image.width && fy >= 0 && fy < image.height) {
            image.setPixel(fx, fy, color);
          }
        }
      }
    }
  }
}
