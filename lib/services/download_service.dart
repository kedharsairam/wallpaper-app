// Conditional export: uses dart:html on web, dart:io + path_provider on mobile/desktop
// Web: triggers browser download via anchor element
// Android: downloads to app documents directory
export 'download_impl_stub.dart'
  if (dart.library.html) 'download_impl_web.dart'
  if (dart.library.io) 'download_impl_io.dart';
