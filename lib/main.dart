import 'package:flutter/foundation.dart' show kIsWeb;

import 'main_mobile.dart' as mobile;
import 'main_web.dart' as web;

Future<void> main() async {
  if (kIsWeb) {
    await web.main();
  } else {
    await mobile.main();
  }
}
