import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/glass_toast_service.dart'; // Fixed path

export '../../../core/services/glass_toast_service.dart';
export 'glass_toast.dart'; // Export types like GlassToastType

/// Global provider for Glass Toast Service
final glassToastProvider = Provider<GlassToastService>((ref) {
  return GlassToastService();
});
