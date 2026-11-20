/// Browser-only tweaks. On Android/iOS these do nothing.
library;

export 'web_tweaks_stub.dart'
    if (dart.library.js_interop) 'web_tweaks_web.dart';
