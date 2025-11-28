import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class TicketGenerator {
  Future<List<int>> generateImageTicket({
    required Uint8List imageBytes,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    try {
      img.Image? originalImage = img.decodeImage(imageBytes);

      originalImage ??= img.decodePng(imageBytes);
      originalImage ??= img.decodeJpg(imageBytes);

      if (originalImage == null) {
        debugPrint('TicketGenerator: failed to decode image bytes');
        return bytes;
      }

      final int maxWidth = paperSize == PaperSize.mm58 ? 384 : 576;
      final int targetWidth = maxWidth - 8;

      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        interpolation: img.Interpolation.linear,
      );

      final img.Image solidImage = img.Image(
        resizedImage.width,
        resizedImage.height,
      );
      img.fill(solidImage, img.getColor(255, 255, 255));

      img.drawImage(solidImage, resizedImage);

      // ---- تحسين جودة وضوح الصورة ----
      // 6. تحويل إلى تدرج رمادي فقط
      final img.Image gray = img.grayscale(solidImage);

      // 7. threshold بسيط بدون أي enhancements
      // جرّب قيمة 220 أولاً، ولو احتجت وضوح أكثـر جرّب 210
      const int thresholdValue = 200;

      final img.Image bwImage = img.Image(gray.width, gray.height);

      for (int y = 0; y < gray.height; y++) {
        for (int x = 0; x < gray.width; x++) {
          final int p = gray.getPixel(x, y);
          final int lum = img.getRed(p); // قيم الإضاءة

          final int v = lum < thresholdValue ? 0 : 255;
          bwImage.setPixel(x, y, img.getColor(v, v, v));
        }
      }

      // ---- طباعة ----
      bytes += generator.imageRaster(bwImage, align: PosAlign.center);

      bytes += generator.feed(2);
      bytes += generator.cut();
    } catch (e) {
      debugPrint("Error generating image commands: $e");
    }

    return bytes;
  }
}
