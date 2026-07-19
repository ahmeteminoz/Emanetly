import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final Object heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = FileImage(File(imageUrl));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Hero(
            tag: heroTag,
            child: PhotoView(
              imageProvider: imageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              initialScale: PhotoViewComputedScale.contained,
              basePosition: Alignment.center,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              onTapUp: (context, details, controllerValue) {
                Navigator.pop(context);
              },
            ),
          ),
          // Close button on top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
