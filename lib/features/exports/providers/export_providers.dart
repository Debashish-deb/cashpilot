import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/export_service.dart' as new_export;

/// Provider for new simplified export service (CSV/PDF)
final exportServiceProvider = Provider((ref) => new_export.ExportService());
