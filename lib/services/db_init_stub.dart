/// Stub for platforms where sqflite_common_ffi is not available (web).
///
/// On web, SQLite is not supported, so this is a no-op.
void initDesktopDatabase() {
  // No-op on web.
}
