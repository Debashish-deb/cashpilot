import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/theme/app_typography.dart';

/// A widget that visualizes family relationships in a tree-like structure
class FamilyTreeGraph extends ConsumerWidget {
  final List<FamilyContact> contacts;
  final List<FamilyRelation> relations;

  const FamilyTreeGraph({
    super.key,
    required this.contacts,
    required this.relations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) {
      return const Center(child: Text('No family data available.'));
    }

    // Simple implementation: List of contacts with their primary relationship
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final contactRelations = relations.where((r) => r.fromContactId == contact.id || r.toContactId == contact.id).toList();
        
        return _ContactNodeCard(
          contact: contact,
          relations: contactRelations,
        );
      },
    );
  }
}

class _ContactNodeCard extends StatelessWidget {
  final FamilyContact contact;
  final List<FamilyRelation> relations;

  const _ContactNodeCard({
    required this.contact,
    required this.relations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTokens.brandSecondary.withValues(alpha: 0.1),
              child: contact.avatarUrl != null
                  ? ClipOval(child: Image.network(contact.avatarUrl!))
                  : Text(contact.name[0], style: AppTypography.titleLarge.copyWith(color: AppTokens.brandSecondary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: AppTypography.titleMedium),
                  if (relations.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: relations.map((r) {
                        final isFrom = r.fromContactId == contact.id;
                        final type = r.relationshipType;
                        return Chip(
                          label: Text(type, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _getRelationColor(type).withValues(alpha: 0.1),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRelationColor(String type) {
    switch (type.toLowerCase()) {
      case 'spouse': return Colors.pink;
      case 'parent': return Colors.blue;
      case 'child': return Colors.green;
      case 'sibling': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
