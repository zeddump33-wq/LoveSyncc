import 'package:flutter/widgets.dart';
import 'image_builder_stub.dart' if (dart.library.io) 'image_builder.dart';

Widget platformImageWidget(String path, {double? width, double? height, BoxFit? fit, ImageErrorWidgetBuilder? errorBuilder}) {
  // ignore: undefined_identifier
  return buildPlatformImage(path, width: width, height: height, fit: fit, errorBuilder: errorBuilder);
}
