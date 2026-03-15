import '../entities/user_preferences.dart';

/// Repository interface for user settings and preferences.
abstract class SettingsRepository {
  Future<UserPreferences> getPreferences();
  Future<void> savePreferences(UserPreferences preferences);
  Future<void> clearAllData(); // Called on logout
}
