import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/export_controller.dart';
import '../../../core/providers/app_providers.dart';

final exportControllerProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ExportController(db);
});
