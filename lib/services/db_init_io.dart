import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the desktop database backend using FFI.
///
/// sqflite uses platform channels on mobile; on desktop we need FFI.
/// This file is only compiled on platforms that have `dart:io`.
void initDesktopDatabase() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
