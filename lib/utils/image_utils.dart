import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageUtils {
  static Future<File?> cropImage({
    required File imageFile,
    bool isCircle = false,
  }) async {
    // İlksel dosya boyutu kontrolü (Gereksiz kırpmayı önlemek için)
    final initialBytes = await imageFile.length();
    final double initialMb = initialBytes / (1024 * 1024);
    if (initialMb > 5.0) {
      throw Exception('Seçilen görsel çok büyük (Maksimum 5 MB olabilir. Mevcut boyut: ${initialMb.toStringAsFixed(1)} MB).');
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Görseli Kırp',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Görseli Kırp',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    
    if (croppedFile != null) {
      final file = File(croppedFile.path);
      final bytes = await file.length();
      final double mb = bytes / (1024 * 1024);
      if (mb > 5.0) {
        throw Exception('Kırpılan görsel çok büyük (Maksimum 5 MB olabilir. Mevcut boyut: ${mb.toStringAsFixed(1)} MB).');
      }
      return file;
    }
    return null;
  }

  static Future<bool> showImagePreviewDialog({
    required BuildContext context,
    required File imageFile,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Görsel Önizleme',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kullan'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
