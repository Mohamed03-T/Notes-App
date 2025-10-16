// MigrationService removed
// The app uses SQLite exclusively. This placeholder keeps the symbol available
// so any remaining references still compile. It contains no migration logic.

class MigrationService {
  const MigrationService();

  /// No-op: migration removed. Keep for compatibility.
  Future<bool> isNeeded() async => false;
}
