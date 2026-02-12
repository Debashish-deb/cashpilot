/// Unsupported Database Implementation
/// Throws UnsupportedError if used
library;

import 'package:drift/drift.dart';

DatabaseConnection connect() {
  throw UnsupportedError('Database not supported on this platform');
}

void initializeDatabaseSync() {
  throw UnsupportedError('Database not supported on this platform');
}
