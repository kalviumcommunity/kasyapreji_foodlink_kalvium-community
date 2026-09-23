import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Loads a bundled photo as a [ui.Image] so custom painters can draw it
/// (clipped to shapes, faded and slowly zoomed).
///
/// Call [resolve] from `didChangeDependencies` and [dispose] with the state.
class AssetPhoto {
  AssetPhoto(this.assetPath);

  final String assetPath;

  /// The decoded photo, or null until it has loaded.
  ui.Image? image;

  ImageStream? _stream;
  ImageStreamListener? _listener;

  void resolve(BuildContext context, VoidCallback onLoaded) {
    final stream = AssetImage(assetPath)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stopListening();
    _listener = ImageStreamListener((info, _) {
      image?.dispose();
      image = info.image.clone();
      info.dispose();
      onLoaded();
    });
    _stream = stream..addListener(_listener!);
  }

  void dispose() {
    _stopListening();
    image?.dispose();
    image = null;
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _listener = null;
  }
}

/// Draws [image] to cover [rect] (cropping as needed), centred on
/// [alignment], and zoomed by [zoom] around the rect's centre.
///
/// [fadeTop] (0–1, as a fraction of the rect's height) fades the photo's top
/// edge to transparent so it melts into whatever is behind it.
void paintPhotoCover(
  Canvas canvas,
  ui.Image image,
  Rect rect, {
  Alignment alignment = Alignment.center,
  double zoom = 1,
  double opacity = 1,
  double fadeTop = 0,
}) {
  if (opacity <= 0) return;
  canvas.saveLayer(
    rect.inflate(2),
    Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
  );
  canvas.save();
  canvas.clipRect(rect);
  canvas.translate(rect.center.dx, rect.center.dy);
  canvas.scale(zoom);
  canvas.translate(-rect.center.dx, -rect.center.dy);
  paintImage(
    canvas: canvas,
    rect: rect,
    image: image,
    fit: BoxFit.cover,
    alignment: alignment,
    filterQuality: FilterQuality.medium,
  );
  canvas.restore();
  if (fadeTop > 0) {
    // Inflated so the mask fully covers edge pixels that fall between whole
    // pixels (dstIn leaves uncovered pixels untouched, which shows a hairline).
    canvas.drawRect(
      rect.inflate(2),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          Offset(rect.center.dx, rect.top + rect.height * fadeTop),
          const [Color(0x00000000), Color(0xFF000000)],
        ),
    );
  }
  canvas.restore();
}
