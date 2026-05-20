abstract interface class SettingsStore {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Stream<String?> watch(String key);
}
