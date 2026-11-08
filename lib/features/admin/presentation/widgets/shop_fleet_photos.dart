import 'package:flutter/material.dart';

/// The fleet photos on a shop application: thumbnails that open a
/// full-screen view on tap. A photo that cannot load shows a broken
/// image icon instead of crashing the sheet.
class ShopFleetPhotos extends StatelessWidget {
  const ShopFleetPhotos({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photoUrls
          .map((url) => Semantics(
              button: true,
              label: 'View photo full screen',
              // E3: the thumbnail is a labelled button for screen
              // readers; the tap behaviour is unchanged.
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Image.network(url,
                        errorBuilder: (_, __, ___) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Photo could not be loaded.'))),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(Icons.broken_image_rounded))),
                ),
              )))
          .toList(),
    );
  }
}
