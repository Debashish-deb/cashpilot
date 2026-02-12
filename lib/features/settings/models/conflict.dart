/// Conflict model for sync conflict resolution
library;

import 'dart:convert';

enum ConflictStatus { open, resolved }
enum ConflictResolution { pending, keepLocal, keepRemote, merged, duplicated }
enum ConflictEntityType { expense, budget, account, category, recurring }

class Conflict {
  final String id;
  final ConflictEntityType entityType;
  final String entityId;
  final DateTime createdAt;
  ConflictStatus status;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final List<String> fieldsChanged;
  ConflictResolution resolution;
  DateTime? resolvedAt;

  Conflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.status = ConflictStatus.open,
    required this.localPayload,
    required this.remotePayload,
    this.fieldsChanged = const [],
    this.resolution = ConflictResolution.pending,
    this.resolvedAt,
  });

  /// Get entity title for display
  String get entityTitle {
    return localPayload['title'] as String? ??
        remotePayload['title'] as String? ??
        entityId.substring(0, 8);
  }

  /// Get human-readable field differences
  List<FieldDiff> get diffs {
    final diffs = <FieldDiff>[];
    final keysToCheck = ['title', 'amount', 'date', 'category_id', 'notes', 'currency'];
    
    for (final key in keysToCheck) {
      final localVal = localPayload[key];
      final remoteVal = remotePayload[key];
      if (localVal != remoteVal) {
        diffs.add(FieldDiff(
          field: key,
          localValue: localVal?.toString() ?? 'null',
          remoteValue: remoteVal?.toString() ?? 'null',
        ));
      }
    }
    return diffs;
  }
 
  /// Create from Drift data class
  factory Conflict.fromData(dynamic data) {
    // We use dynamic to avoid direct dependency on app_database.dart if not needed,
    // but here we are in the same package.
    final row = data; // Assuming it's ConflictData or similar
    return Conflict(
      id: row.id,
      entityType: ConflictEntityType.values.firstWhere(
        (e) => e.name == row.entityType,
        orElse: () => ConflictEntityType.expense,
      ),
      entityId: row.entityId,
      createdAt: row.createdAt,
      status: row.status == 'resolved' ? ConflictStatus.resolved : ConflictStatus.open,
      localPayload: jsonDecode(row.localJson) as Map<String, dynamic>,
      remotePayload: jsonDecode(row.remoteJson) as Map<String, dynamic>,
      fieldsChanged: (jsonDecode(row.diffJson ?? '[]') as List)
          .map((d) => (d as Map)['field'] as String)
          .toList(),
      resolution: ConflictResolution.values.firstWhere(
        (e) => e.name == row.resolutionType,
        orElse: () => ConflictResolution.pending,
      ),
      resolvedAt: row.resolvedAt,
    );
  }

  /// Create from Drift row
  factory Conflict.fromDrift(Map<String, dynamic> row) {
    return Conflict(
      id: row['id'] as String,
      entityType: ConflictEntityType.values.firstWhere(
        (e) => e.name == row['entity_type'],
        orElse: () => ConflictEntityType.expense,
      ),
      entityId: row['entity_id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: row['status'] == 'resolved' ? ConflictStatus.resolved : ConflictStatus.open,
      localPayload: jsonDecode(row['local_payload_json'] as String) as Map<String, dynamic>,
      remotePayload: jsonDecode(row['remote_payload_json'] as String) as Map<String, dynamic>,
      fieldsChanged: (jsonDecode(row['fields_changed_json'] as String? ?? '[]') as List).cast<String>(),
      resolution: ConflictResolution.values.firstWhere(
        (e) => e.name == row['resolution'],
        orElse: () => ConflictResolution.pending,
      ),
      resolvedAt: row['resolved_at'] != null ? DateTime.parse(row['resolved_at'] as String) : null,
    );
  }

  Map<String, dynamic> toDrift() => {
        'id': id,
        'entity_type': entityType.name,
        'entity_id': entityId,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'local_payload_json': jsonEncode(localPayload),
        'remote_payload_json': jsonEncode(remotePayload),
        'fields_changed_json': jsonEncode(fieldsChanged),
        'resolution': resolution.name,
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}

class FieldDiff {
  final String field;
  final String localValue;
  final String remoteValue;

  FieldDiff({
    required this.field,
    required this.localValue,
    required this.remoteValue,
  });

  String get fieldLabel {
    switch (field) {
      case 'title': return 'Title';
      case 'amount': return 'Amount';
      case 'date': return 'Date';
      case 'category_id': return 'Category';
      case 'notes': return 'Notes';
      case 'currency': return 'Currency';
      default: return field;
    }
  }
}
