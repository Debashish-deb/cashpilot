import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sync/sync_providers.dart'; // Added for dataRepairServiceProvider

/// Diagnostic Console - Hidden Operational Tooling
/// Accessible via internal settings or secret gesture.
class DiagnosticConsole extends ConsumerStatefulWidget {
  const DiagnosticConsole({super.key});

  @override
  ConsumerState<DiagnosticConsole> createState() => _DiagnosticConsoleState();
}

class _DiagnosticConsoleState extends ConsumerState<DiagnosticConsole> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _logs = [];
  bool _isProcessing = false;

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, "[${DateTime.now().toIso8601String().substring(11, 19)}] $msg");
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _runRepair() async {
    setState(() => _isProcessing = true);
    try {
      final repairService = ref.read(dataRepairServiceProvider);
      final results = await repairService.runDiagnostics();
      _addLog("Diagnostics: $results");
      final count = await repairService.repairAll();
      _addLog("Repaired $count items.");
    } catch (e) {
      _addLog("Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark deep blue
      appBar: AppBar(
        title: const Text('DIAGNOSTIC CONSOLE V1', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTerminalOutput(),
          _buildQuickActions(),
          _buildCommandLine(),
        ],
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        color: Colors.black,
        child: ListView.builder(
          reverse: true,
          itemCount: _logs.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              _logs[index],
              style: const TextStyle(
                color: Color(0xFF10B981), // Emerald terminal green
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF1E293B),
      child: Wrap(
        spacing: 8,
        children: [
          _ActionButton(
            label: "RUN REPAIR",
            color: Colors.blue,
            onPressed: _runRepair,
            loading: _isProcessing,
          ),
          _ActionButton(
            label: "HARD RESET SYNC",
            color: Colors.red,
            onPressed: () => _confirmAction("Perform Hard Reset?", () => ref.read(dataRepairServiceProvider).hardSyncReset()),
          ),
          _ActionButton(
            label: "EXPORT DB",
            color: Colors.amber,
            onPressed: () => ref.read(dataRepairServiceProvider).exportDatabase(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandLine() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          const Text("> ", style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
          Expanded(
            child: TextField(
              controller: _commandController,
              autocorrect: false,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter command...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onSubmitted: (val) async {
                if (val.isEmpty) return;
                final res = await ref.read(dataRepairServiceProvider).processCommand(val);
                _addLog("> $val");
                _addLog(res);
                _commandController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(String title, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text("This action cannot be undone and may affect active sync sessions."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
              _addLog("Action executed.");
            },
            child: const Text("EXECUTE"),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool loading;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      onPressed: loading ? null : onPressed,
      child: loading ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
    );
  }
}
