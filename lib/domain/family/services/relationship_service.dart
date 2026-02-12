import '../models/relationship_model.dart';

/// Service to handle family relationship graph logic
class RelationshipService {
  /// Builds a graph representation from a list of relationships
  Map<String, List<RelationshipModel>> _buildGraph(List<RelationshipModel> relations) {
    final graph = <String, List<RelationshipModel>>{};
    for (final rel in relations) {
      graph.putIfAbsent(rel.fromContactId, () => []).add(rel);
      
      // Add reverse relationship if needed for bidirectional traversal
      // In a real database, we might store both or handle it in the query
      // Here we assume directed edges but might need bidirectional for tree distance
      graph.putIfAbsent(rel.toContactId, () => []).add(rel.copyWith(
        fromContactId: rel.toContactId,
        toContactId: rel.fromContactId,
        // Reverse type logic would go here (e.g., child -> parent)
      ));
    }
    return graph;
  }

  /// Calculates the shortest distance between two contacts in the family tree
  int calculateDistance(String startId, String endId, List<RelationshipModel> relations) {
    if (startId == endId) return 0;
    
    final graph = _buildGraph(relations);
    final queue = <MapEntry<String, int>>[MapEntry(startId, 0)];
    final visited = <String>{startId};
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final contactId = current.key;
      final distance = current.value;
      
      if (contactId == endId) return distance;
      
      final neighbors = graph[contactId] ?? [];
      for (final rel in neighbors) {
        if (!visited.contains(rel.toContactId)) {
          visited.add(rel.toContactId);
          queue.add(MapEntry(rel.toContactId, distance + 1));
        }
      }
    }
    
    return -1; // No path found
  }

  /// Gets all contacts related to a given contact within a certain depth
  Set<String> getRelatedContacts(String contactId, List<RelationshipModel> relations, {int maxDepth = 2}) {
    final related = <String>{};
    final graph = _buildGraph(relations);
    final queue = <MapEntry<String, int>>[MapEntry(contactId, 0)];
    final visited = <String>{contactId};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentId = current.key;
      final currentDepth = current.value;

      if (currentDepth > 0) {
        related.add(currentId);
      }

      if (currentDepth < maxDepth) {
        final neighbors = graph[currentId] ?? [];
        for (final rel in neighbors) {
          if (!visited.contains(rel.toContactId)) {
            visited.add(rel.toContactId);
            queue.add(MapEntry(rel.toContactId, currentDepth + 1));
          }
        }
      }
    }

    return related;
  }
}
