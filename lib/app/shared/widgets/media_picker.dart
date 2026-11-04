import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class PickedMedia {
  const PickedMedia({required this.path, required this.isVideo});

  final String path;
  final bool isVideo;
}

/// Asks for the camera or the gallery, then returns the picked file.
/// Images are downscaled to stay under the 10 MB upload limit.
Future<PickedMedia?> pickMedia(
  BuildContext context, {
  bool allowVideo = false,
}) async {
  final choice = await showModalBottomSheet<(ImageSource, bool)>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(context, Iconsax.camera_copy, 'Take a photo'.tr, (
              ImageSource.camera,
              false,
            )),
            if (allowVideo)
              _option(context, Iconsax.video_copy, 'Record a video'.tr, (
                ImageSource.camera,
                true,
              )),
            _option(context, Iconsax.gallery_copy, 'Choose a photo'.tr, (
              ImageSource.gallery,
              false,
            )),
            if (allowVideo)
              _option(context, Iconsax.video_play_copy, 'Choose a video'.tr, (
                ImageSource.gallery,
                true,
              )),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return null;
  final picker = ImagePicker();
  final (source, video) = choice;
  final file = video
      ? await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        )
      : await picker.pickImage(
          source: source,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );
  return file == null ? null : PickedMedia(path: file.path, isVideo: video);
}

Widget _option(
  BuildContext context,
  IconData icon,
  String label,
  (ImageSource, bool) value,
) => ListTile(
  leading: Icon(icon, color: AppColors.brand),
  title: Text(label),
  onTap: () => Navigator.of(context).pop(value),
);

/// A picked local file, bundled asset or HTTPS image, covering its box.
class LocalOrNetworkImage extends StatelessWidget {
  const LocalOrNetworkImage(this.source, {super.key, this.isVideo = false});

  final String source;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.surfaceSubtle,
      child: Center(
        child: Icon(Iconsax.gallery_copy, color: AppColors.textTertiary),
      ),
    );
    if (isVideo && !source.startsWith('http')) {
      return const ColoredBox(
        color: Color(0xFF1F2933),
        child: Center(
          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white),
        ),
      );
    }
    final Widget image = switch (source) {
      final url when url.startsWith('http') => Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
      final asset when asset.startsWith('assets/') => Image.asset(
        asset,
        fit: BoxFit.cover,
      ),
      final path => Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    };
    if (!isVideo) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const Center(
          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
