/// Database Connection Factory
/// Selects the appropriate Drift executor based on the platform.
library;

export 'unsupported_database.dart'
    if (dart.library.io) 'native_database.dart'
    if (dart.library.html) 'web_database.dart';
