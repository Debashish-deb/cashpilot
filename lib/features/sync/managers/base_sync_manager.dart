/// abstract base class for feature-specific sync managers
abstract class BaseSyncManager<T> {
  Future<void> syncUp(String id); // Push local item to cloud
  Future<void> syncDown(String id); // Pull remote item to local (optional)
  Future<int> pushChanges(); // Push all pending local changes
  Future<int> pullChanges(); // Pull all remote changes
}
