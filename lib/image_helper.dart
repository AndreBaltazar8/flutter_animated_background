import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' as widget;

/// Helper to convert a widget image into a dart:ui image
///
/// The resulting image will be sent in [callback].
///
/// The returned function allows to unregister the listener in case it is not
/// needed before the callback is called.
Function() convertImage(widget.Image image, Function(ui.Image) callback) {
  final ImageStream newStream = image.image.resolve(ImageConfiguration.empty);
  late ImageStreamListener imageListener;
  imageListener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    callback(info.image);
    newStream.removeListener(imageListener);
  });
  newStream.addListener(imageListener);
  return () => newStream.removeListener(imageListener);
}
