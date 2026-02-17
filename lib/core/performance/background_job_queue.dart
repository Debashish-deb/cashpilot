import 'dart:async';
import 'dart:collection';

typedef JobAction = Future<void> Function();

class BackgroundJobQueue {
  static final BackgroundJobQueue _instance = BackgroundJobQueue._internal();
  factory BackgroundJobQueue() => _instance;
  BackgroundJobQueue._internal();

  final Queue<Job> _queue = Queue<Job>();
  bool _isProcessing = false;

  /// Add a job to the queue
  void enqueue(String name, JobAction action, {int priority = 100}) {
    _queue.add(Job(name: name, action: action, priority: priority));
    _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    
    // Simple priority sorting could be added here if needed
    final job = _queue.removeFirst();

    try {
      print('[BackgroundJobQueue] Starting job: ${job.name}');
      await job.action();
      print('[BackgroundJobQueue] Completed job: ${job.name}');
    } catch (e) {
      print('[BackgroundJobQueue] Error in job ${job.name}: $e');
    } finally {
      _isProcessing = false;
      _processNext();
    }
  }
}

class Job {
  final String name;
  final JobAction action;
  final int priority;

  Job({required this.name, required this.action, this.priority = 100});
}
