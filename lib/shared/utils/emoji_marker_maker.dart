import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmojiMarkerHelper {
  static Future<BitmapDescriptor> createEmojiMarker({
    required String emoji,
    required Color backgroundColor,
    required double size,
    Color borderColor = Colors.white,
    double borderWidth = 2.0,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      final radius = size / 2;
      final center = Offset(radius, radius);

      paint.color = backgroundColor;
      canvas.drawCircle(center, radius - borderWidth, paint);

      paint.color = borderColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = borderWidth;
      canvas.drawCircle(center, radius - borderWidth, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(fontSize: size * 0.6, fontFamily: 'emoji'),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final emojiOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, emojiOffset);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(
        backgroundColor == Colors.blue
            ? BitmapDescriptor.hueBlue
            : backgroundColor == Colors.green
            ? BitmapDescriptor.hueGreen
            : backgroundColor == Colors.red
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueOrange,
      );
    }
  }

  /// Creates a delivery driver marker with motorcycle emoji
  static Future<BitmapDescriptor> createDeliveryDriverMarker() async {
    return createEmojiMarker(
      emoji: '🏍️',
      backgroundColor: Colors.blue,
      size: 48.0,
      borderColor: Colors.white,
      borderWidth: 2.0,
    );
  }

  /// Creates a pickup location marker with package emoji
  static Future<BitmapDescriptor> createPickupMarker() async {
    return createEmojiMarker(
      emoji: '📦',
      backgroundColor: Colors.green,
      size: 40.0,
      borderColor: Colors.white,
      borderWidth: 2.0,
    );
  }

  /// Creates a destination marker with house emoji
  static Future<BitmapDescriptor> createDestinationMarker() async {
    return createEmojiMarker(
      emoji: '🏠',
      backgroundColor: Colors.red,
      size: 40.0,
      borderColor: Colors.white,
      borderWidth: 2.0,
    );
  }

  /// Alternative delivery driver marker with delivery person emoji
  static Future<BitmapDescriptor> createDeliveryPersonMarker() async {
    return createEmojiMarker(
      emoji: '🚚',
      backgroundColor: Colors.blue,
      size: 48.0,
      borderColor: Colors.white,
      borderWidth: 2.0,
    );
  }

  /// Creates a multi-stop marker with flag emoji
  static Future<BitmapDescriptor> createMultiStopMarker(int stopNumber) async {
    return createEmojiMarker(
      emoji: stopNumber <= 9 ? '$stopNumber️⃣' : '🔢',
      backgroundColor: Colors.orange,
      size: 36.0,
      borderColor: Colors.white,
      borderWidth: 2.0,
    );
  }
}
