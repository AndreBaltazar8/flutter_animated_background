import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' as widget;

Function() convertImage(widget.Image image, Function(ui.Image) callback) {
  final ImageStream newStream = image.image.resolve(ImageConfiguration.empty);
  Function(ImageInfo, bool) listener;
  listener = (ImageInfo info, bool synchronousCall) {
    callback(info?.image);
    newStream.removeListener(listener);
  };

  newStream.addListener(listener);
  return () => newStream.removeListener(listener);
}